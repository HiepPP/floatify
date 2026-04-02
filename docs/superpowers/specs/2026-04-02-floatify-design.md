# Floatify — Design Specification

## Overview

Floatify is a macOS menu bar daemon that renders animated floating notifications in the screen's dead zones (bottom-left / bottom-right corners), triggered by Claude Code task completion hooks.

The system has two components:

1. **Floatify.app** — background GUI app (no Dock icon) that owns the floating NSPanel overlay
2. **floatify CLI** — thin binary that sends a message to the running app via FIFO pipe IPC

---

## Architecture

```
Claude Code (CLI)
    │
    │  ~/.claude/settings.json hooks (PostToolUse / Stop)
    ▼
floatify CLI  (/usr/local/bin/floatify)
    │
    │  FIFO pipe IPC  "/var/tmp/floatify.pipe"
    │  latency < 1ms, no network, macOS native
    ▼
Floatify.app  (LSUIElement, menu bar icon)
    │
    │  NSPanel  (.nonactivatingPanel, .popUpMenu level)
    │  NSScreen.main?.frame  →  absolute bottom-left / bottom-right
    │
    │  Stacking: up to 3 panels, 4px vertical offset each
    ▼
Floating Notification  (bounces 3x, auto-dismisses after N seconds)
```

---

## Component 1 — Floatify.app

### App Configuration

- **LSUIElement = true** — no Dock icon, no Cmd+Tab entry
- **Menu bar icon** — text label in status bar; click reveals Quit and "Test Notification"
- **No launch at login** — v1, user manually launches once
- **Deployment target** — macOS 13+

### IPC Server — FIFO Pipe Listener

App creates a FIFO pipe at `/var/tmp/floatify.pipe` on startup and listens for JSON payloads from the CLI tool.

**Pipe path:** `/var/tmp/floatify.pipe`

JSON payload schema:
```json
{
  "message":  "Task complete!",
  "corner":   "bottomRight",
  "duration": "6"
}
```

- `corner` accepts: `bottomLeft`, `bottomRight` (defaults to `bottomRight`)
- `duration` accepts: number seconds (defaults to `6`)
- Invalid/corrupt JSON is silently ignored

### NSPanel — Non-Activating Floating Overlay

```swift
class FloatPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return frameRect
    }
}
```

- **Level:** `.popUpMenu` — floats above all apps, visible on all Spaces
- **Collection behavior:** `.canJoinAllSpaces`, `.fullScreenAuxiliary`
- **Background:** clear, non-opaque, no shadow (shadow handled in SwiftUI view)
- **Mouse events:** ignored for panel itself, tap handled by SwiftUI view

### Corner Positioning

Uses `NSScreen.main?.frame` for absolute screen edge positioning (not `visibleFrame` which respects Dock).

```swift
enum Corner { case bottomLeft, bottomRight }

func cornerOrigin(corner: Corner, size: CGSize, padding: CGFloat = 0, stackOffset: CGFloat = 0) -> CGPoint {
    guard let frame = NSScreen.main?.frame else { return .zero }
    switch corner {
    case .bottomLeft:
        return CGPoint(x: frame.minX + padding, y: frame.minY + padding + stackOffset)
    case .bottomRight:
        return CGPoint(x: frame.maxX - size.width - padding, y: frame.minY + padding + stackOffset)
    }
}
```

### Notification Manager — Stacking Behavior

- Max 3 visible panels at once
- New panels stack with 4px vertical offset above the previous
- When a panel dismisses, panels above fall down to fill gap
- Replacement/dispatch logic: new notification appends to stack

### CLI Symlink Installation (First Launch)

On first app launch, show NSAlert:

> "Floatify needs to install the `floatify` command-line tool to `/usr/local/bin/`. This allows Claude Code hooks to trigger notifications. Create the symlink?"

- User approves → create symlink `floatify` → `/usr/local/bin/`
- User declines → app continues running, CLI won't work until manually installed
- If symlink already exists → skip silently

---

## Component 2 — floatify CLI Tool

### Binary Location

After install: `/usr/local/bin/floatify` (symlink to app bundle resource)

### Argument Parsing

```bash
floatify --message "Task complete!" --corner bottomRight --duration 6
```

| Flag | Description | Default |
|------|-------------|---------|
| `--message` | Notification message text | `"Task complete!"` |
| `--corner` | `bottomLeft` or `bottomRight` | `bottomRight` |
| `--duration` | Auto-dismiss seconds | `6` |

### FIFO Pipe Client Behavior

1. Attempt to open `/var/tmp/floatify.pipe` for writing
2. If pipe unavailable → write `Floatify.app is not running` to stderr, exit code 1
3. If connected → send JSON payload, exit code 0 on success

---

## Component 3 — Claude Code Integration

`~/.claude/settings.json` hooks:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "floatify --message 'Floatify is waiting' --corner bottomRight --duration 10"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "floatify --message 'Bash task done' --corner bottomLeft --duration 5"
          }
        ]
      }
    ]
  }
}
```

| Hook | When it fires | Suggested corner | Suggested duration |
|------|---------------|-----------------|-------------------|
| `Stop` | Claude finishes a full task | bottomRight | 10s |
| `PostToolUse` | After each individual tool call | bottomLeft | 5s |

---

## SwiftUI Notification View

```swift
struct FloatNotificationView: View {
    let message: String
    var onTap: (() -> Void)?

    @State private var isVisible = false
    @State private var bounce = false

    var body: some View {
        HStack(spacing: 10) {
            Text("Floatify")
                .font(.system(size: 32))
                .scaleEffect(bounce ? 1.2 : 1.0)
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.5)
                    .repeatCount(3, autoreverses: true),
                    value: bounce
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Claude Code")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 4)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 24)
        .onTapGesture { onTap?() }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.68)) {
                isVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                bounce = true
            }
        }
    }
}
```

**Animation sequence:**
1. Panel slides in from bottom (offset y: 24 → 0, opacity 0 → 1) over ~450ms
2. Label bounces 3x starting 500ms after appear (spring, 300ms each)
3. Auto-dismiss after `duration` seconds (panel slides/fades out)

---

## Project Structure

```
Floatify/
├── Floatify.xcodeproj
├── Floatify/                    ← macOS App target
│   ├── AppDelegate.swift        ← FIFO pipe server + menu bar + symlink installer
│   ├── FloatNotificationManager.swift
│   ├── FloatNotificationView.swift
│   ├── Corner.swift
│   ├── main.swift
│   └── Info.plist               ← LSUIElement = true
├── cli/                         ← Command Line Tool target
│   └── main.swift               ← Argument parser + FIFO pipe client
└── README.md
```

**Xcode targets:**
- `Floatify` — macOS App, deployment target macOS 13+
- `floatify` — Command Line Tool, linked into app bundle via Copy Files build phase

---

## Edge Cases

| Edge case | Mitigation |
|-----------|------------|
| App not running when CLI fires | CLI prints error to stderr, exits 1 |
| Multiple monitors | Defaults to `NSScreen.main` (primary screen) |
| Dock on left/right side | Frame-based positioning is always at absolute edges |
| Dock set to auto-hide | Frame-based positioning means notifications stay at absolute bottom edge |
| Rapid successive triggers | Stack up to 3 panels, 4px vertical offset per queued notification |
| Invalid JSON payload | Silently ignored by pipe handler |
| Symlink already exists | Skip installation silently on next launch |

---

## Technical Decisions

**Why FIFO pipe over CFMessagePort or HTTP/Unix socket?**
FIFO pipe is macOS-native, requires no server setup, has sub-millisecond latency, and works with zero network permissions. No firewall or security approval dialogs needed.

**Why NSPanel with .nonactivatingPanel?**
NSPanel with .nonactivatingPanel prevents the notification from stealing keyboard focus from the active editor — critical when Claude Code is waiting and the developer is mid-typing.

**Why .popUpMenu window level?**
This level floats above all standard app windows without blocking mouse events on underlying apps. Combined with .fullScreenAuxiliary, it appears alongside fullscreen apps as well.

**Why NSScreen.frame over NSScreen.visibleFrame?**
`frame` gives absolute screen edges regardless of Dock state. `visibleFrame` respects Dock size/position, so when Dock auto-hides, notifications would appear higher than the true screen bottom. Using `frame` ensures consistent edge positioning.
