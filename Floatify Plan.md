# Floatify — macOS Floating Notification App for Claude Code

**A lightweight macOS menu bar daemon that renders animated floating notifications in the screen's dead zones (bottom-left / bottom-right corners), triggered by Claude Code task completion hooks.**

---

## Overview

When working with Claude Code CLI, there is often unused screen real estate in the bottom corners — the gap between the active editor window and the macOS Dock. Floatify exploits this dead zone to surface non-intrusive, attention-grabbing notifications that signal when Claude Code has finished a task and is waiting for the next prompt.

The system has two components:
1. **Floatify.app** — a background GUI app (no Dock icon) that owns the floating NSPanel overlay
2. **`floatify` CLI tool** — a thin binary that sends a message to the running app via FIFO pipe IPC

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
    │  latency < 1ms, no network, no permissions needed
    ▼
Floatify.app  (LSUIElement, runs at Login, no Dock icon)
    │
    │  NSPanel  (.nonactivatingPanel, .popUpMenu level)
    │  NSScreen.frame  →  absolute bottom-left / bottom-right
    ▼
Floating Notification  (bounces, auto-dismisses after N seconds)
```

---

## Component 1 — Floatify.app

### App Configuration (`Info.plist`)

```xml
<!-- Run silently in background, no Dock icon, no Cmd+Tab entry -->
<key>LSUIElement</key>
<true/>

<!-- Auto-launch at Login (register via SMAppService or Login Items) -->
<key>LSBackgroundOnly</key>
<false/>
```

### IPC Server — FIFO Pipe Listener

The app creates a named FIFO pipe at `/var/tmp/floatify.pipe` and listens for JSON payloads from the CLI tool.

```swift
// AppDelegate.swift
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var pipeSource: DispatchSourceRead?
    private let pipePath = "/var/tmp/floatify.pipe"

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupPipeListener()
    }

    private func setupPipeListener() {
        // Create pipe if it doesn't exist
        if !FileManager.default.fileExists(atPath: pipePath) {
            mkfifo(pipePath, 0o666)
        }

        // Open pipe for reading
        let pipeFd = open(pipePath, O_RDONLY | O_NONBLOCK)
        guard pipeFd >= 0 else { return }

        // Set up dispatch source to read from pipe
        pipeSource = DispatchSource.makeReadSource(fileDescriptor: pipeFd, queue: .main)
        pipeSource?.setEventHandler { [weak self] in
            var buffer = [UInt8](repeating: 0, count: 4096)
            let bytesRead = read(pipeFd, &buffer, buffer.count)
            if bytesRead > 0 {
                let data = Data(bytes: buffer, count: bytesRead)
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    self?.handleJSON(json)
                }
            }
        }
        pipeSource?.resume()
    }

    private func handleJSON(_ json: [String: Any]) {
        let message = json["message"] as? String ?? "Task complete!"
        let corner: Corner = json["corner"] == "bottomLeft" ? .bottomLeft : .bottomRight
        let duration = json["duration"] as? TimeInterval ?? 6.0

        FloatNotificationManager.shared.show(message: message, corner: corner, duration: duration)
    }
}
```

### Corner Positioning — `NSScreen.frame` (Absolute Edges)

Uses `NSScreen.main?.frame` for absolute positioning at screen bottom edges (not `visibleFrame` which respects Dock).

```swift
enum Corner { case bottomLeft, bottomRight }

func cornerOrigin(corner: Corner, size: CGSize, padding: CGFloat = 16) -> CGPoint {
    guard let frame = NSScreen.main?.frame else { return .zero }
    switch corner {
    case .bottomLeft:
        return CGPoint(x: frame.minX + padding, y: frame.minY + padding)
    case .bottomRight:
        return CGPoint(x: frame.maxX - size.width - padding, y: frame.minY + padding)
    }
}
```

### NSPanel — Non-Activating Floating Overlay

```swift
class FloatPanel: NSPanel {
    // Never steal focus from the active editor
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    // Allow rendering outside normal screen constraints
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return frameRect
    }
}

class FloatNotificationManager {
    static let shared = FloatNotificationManager()
    private var panels: [FloatPanel] = []

    func show(message: String, corner: Corner, duration: TimeInterval = 6) {
        DispatchQueue.main.async {
            let size = CGSize(width: 280, height: 68)
            let origin = self.cornerOrigin(corner: corner, size: size)

            let panel = FloatPanel(
                contentRect: NSRect(origin: origin, size: size),
                styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            panel.level = .popUpMenu
            panel.collectionBehavior = [
                .canJoinAllSpaces,
                .fullScreenAuxiliary
            ]
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.ignoresMouseEvents = false

            let view = FloatNotificationView(message: message) {
                self.dismiss(panel: panel)
            }
            panel.contentView = NSHostingView(rootView: view)
            panel.orderFront(nil)
            self.panels.append(panel)

            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.dismiss(panel: panel)
            }
        }
    }

    private func dismiss(panel: FloatPanel) {
        panel.orderOut(nil)
        panels.removeAll { $0 === panel }
    }
}
```

### SwiftUI Notification View

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

---

## Component 2 — `floatify` CLI Tool

A separate **Command Line Tool** Xcode target, compiled into the app bundle at `Floatify.app/Contents/Resources/floatify`, then symlinked to `/usr/local/bin/floatify` on first launch.

### CLI Source (`main.swift`)

```swift
import Foundation

// --- Argument parsing ---
var message = "Task complete!"
var corner  = "bottomRight"
var duration = "6"

var args = Array(CommandLine.arguments.dropFirst())
while !args.isEmpty {
    let flag = args.removeFirst()
    guard !args.isEmpty else { break }
    switch flag {
    case "--message":  message  = args.removeFirst()
    case "--corner":   corner   = args.removeFirst()
    case "--duration": duration = args.removeFirst()
    default: break
    }
}

// --- Send via FIFO pipe ---
let pipePath = "/var/tmp/floatify.pipe"

guard let pipeFd = open(pipePath, O_WRONLY | O_NONBLOCK) else {
    fputs("Floatify.app is not running\n", stderr)
    exit(1)
}

let payload: [String: String] = [
    "message":  message,
    "corner":   corner,
    "duration": duration
]
let data = try! JSONSerialization.data(withJSONObject: payload)
let bytesWritten = write(pipeFd, data.bytes, data.count)

if bytesWritten > 0 {
    print("Sent: \(message)")
} else {
    fputs("Pipe write failed\n", stderr)
    exit(1)
}
```

### CLI Usage

```bash
# Minimal
floatify --message "Task complete!"

# Full options
floatify \
  --message "Task complete! Continue prompting" \
  --corner bottomRight \
  --duration 8

# Bottom-left example
floatify --message "Build succeeded" --corner bottomLeft
```

### Symlink Installation (on first app launch)

```swift
// In AppDelegate.applicationDidFinishLaunching
func installCLIToolIfNeeded() {
    let src  = Bundle.main.url(forResource: "floatify", withExtension: nil)!
    let dest = URL(fileURLWithPath: "/usr/local/bin/floatify")
    guard !FileManager.default.fileExists(atPath: dest.path) else { return }

    // Requires user approval — show an NSAlert first
    try? FileManager.default.createSymbolicLink(at: dest, withDestinationURL: src)
}
```

---

## Component 3 — Claude Code Integration

Claude Code supports lifecycle hooks in `~/.claude/settings.json`.

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

| Hook | When it fires | Suggested use |
|------|---------------|---------------|
| `Stop` | Claude finishes a full task and stops | Main "come back" notification — bottom-right |
| `PostToolUse` | After each individual tool call | Quick status per action — bottom-left |
| `PreToolUse` | Before a tool runs | Optional: "starting..." indicator |

---

## Project Structure

```
Floatify/
├── Floatify.xcodeproj
├── Floatify/                    ← GUI app target
│   ├── AppDelegate.swift         ← FIFO pipe server + menu bar + symlink installer
│   ├── FloatNotificationManager.swift
│   ├── FloatNotificationView.swift
│   ├── Corner.swift
│   ├── main.swift
│   └── Info.plist               ← LSUIElement = true
├── cli/                         ← CLI tool target
│   └── main.swift               ← Argument parser + FIFO pipe client
└── README.md
```

**Xcode targets:**
- `Floatify` — macOS App, deployment target macOS 13+
- `floatify` — Command Line Tool, linked into app bundle via Copy Files build phase

---

## Implementation Milestones

| Step | Task | Estimated effort |
|------|------|-----------------|
| 1 | Create Xcode project with two targets (App + CLI Tool) | 15 min |
| 2 | Implement FIFO pipe server in AppDelegate | 30 min |
| 3 | Build `FloatPanel` + `FloatNotificationManager` with `frame` positioning | 45 min |
| 4 | Build `FloatNotificationView` SwiftUI with bounce animation | 30 min |
| 5 | Implement CLI `main.swift` with arg parser + FIFO pipe client | 20 min |
| 6 | Wire CLI binary into app bundle via Copy Files phase + symlink on launch | 20 min |
| 7 | Add Claude Code hooks to `~/.claude/settings.json` | 5 min |
| 8 | Test: bottom-left, bottom-right, multi-monitor, fullscreen edge cases | 30 min |

**Total: ~3 hours for a working v1**

---

## Key Technical Decisions

**Why FIFO pipe over CFMessagePort or HTTP?**
FIFO pipe is macOS-native, requires no server setup, has sub-millisecond latency, and works with zero network permissions. No firewall or security approval dialogs needed.

**Why `NSScreen.frame` over `NSScreen.visibleFrame`?**
`frame` gives absolute screen edges ( Dock hidden or not ). `visibleFrame` respects Dock size/position, which causes notifications to appear above the Dock when it auto-hides. Using `frame` ensures notifications always appear at true screen edges.

**Why `NSPanel` with `.nonactivatingPanel` over `NSWindow`?**
`NSPanel` with `.nonactivatingPanel` prevents the notification from stealing keyboard focus from the active editor — critical when Claude Code is waiting and the developer is mid-typing.

**Why `.popUpMenu` window level?**
This level floats above all standard app windows without requiring the app to claim `.screenSaver` level (which would block mouse events on underlying apps). Combined with `.fullScreenAuxiliary`, it appears alongside fullscreen apps as well.

---

## Edge Cases & Mitigations

| Edge case | Mitigation |
|-----------|------------|
| Multiple monitors | Use `NSScreen.screens` to pick the screen where the active editor lives, or default to `NSScreen.main` |
| Dock on left/right side | Frame-based positioning is always at absolute edges regardless of Dock position |
| Dock set to auto-hide | Frame-based positioning means notifications stay at absolute bottom edge |
| Floatify.app not running when CLI fires | CLI prints `Floatify.app is not running` and exits with code 1 — add a fallback: `osascript -e 'display notification "Task done" with title "Claude Code"'` |
| Notification spam (rapid successive triggers) | Stagger panels with a 4px vertical offset per queued notification; cap queue at 3 visible at once |
