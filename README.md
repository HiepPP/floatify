# Floatify

**Website:** https://floatify-app.vercel.app

<!-- Header Banner -->
<p align="center">
  <img src="https://img.shields.io/badge/macOS-11%2B-blue?style=for-the-badge" alt="macOS 11+">
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=for-the-badge" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="MIT License">
  <img src="https://img.shields.io/badge/Platform-arm64%20%7C%20x86__64-blueviolet?style=for-the-badge" alt="Platforms">
</p>

<p align="center">
  A lightweight <strong>macOS menu bar daemon</strong> that renders animated floating notifications in screen dead zones.
</p>

<p align="center">
  <img src="website/public/demo.gif" alt="Floatify Demo" width="800">
</p>

---

## Table of Contents

- [Features](#features)
- [Why Floatify](#why-floatify)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [CLI Reference](#cli-reference)
- [Hook Setup](#hook-setup)
- [Architecture](#architecture)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- Floating notifications in screen corners and center positions
- Cursor-follow mode for dynamic positioning
- Sub-millisecond IPC via FIFO pipes
- No Dock icon (LSUIElement background app)
- Stacking support with up to 3 visible notifications
- Smooth animated transitions
- Claude Code and Codex hook integration for automation
- **File changes badge** - Shows git modified files count on each session floater
- **Activity timestamp** - Displays relative time since last session activity (Just now / 2m ago / 1h ago)

## Why Floatify

| Benefit | Description |
|---------|-------------|
| Zero distraction | Notifications appear in screen dead zones, never blocking your work |
| Focus-friendly | Non-activating NSPanel never steals keyboard focus |
| Blazing fast | FIFO pipe IPC achieves sub-millisecond latency |
| Clean integration | Works with Claude Code and Codex hooks |
| Lightweight | No network permissions, minimal resource usage |
| Context-aware | Git changes count and activity timestamps keep you informed |

---

## Installation

### Prerequisites

- macOS 11.0 (Big Sur) or later
- XcodeGen installed (`brew install xcodegen`)

### Build from Source

```bash
# Clone the repository
git clone https://github.com/HiepPP/floatify.git
cd floatify

# Generate Xcode project
cd Floatify && xcodegen generate

# Build the app
xcodebuild -project Floatify.xcodeproj -scheme Floatify -configuration Release build \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO
```

### Run the App

```bash
open ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Release/Floatify.app
```

Approve the CLI symlink prompt when it appears. The `floatify` command will be available in your PATH.

---

## Quick Start

```bash
# Basic notification
floatify --message 'Task complete!' --position bottomRight --duration 6

# Corner positions
floatify --message 'Bottom Left!' --position bottomLeft --duration 4
floatify --message 'Bottom Right!' --position bottomRight --duration 4
floatify --message 'Top Left!' --position topLeft --duration 4
floatify --message 'Top Right!' --position topRight --duration 4
floatify --message 'Centered!' --position center --duration 5
floatify --message 'Below menu bar!' --position menubar --duration 5
floatify --message 'Horizontal!' --position horizontal --duration 5

# Follows your cursor
floatify --message 'Following cursor!' --position cursorFollow --duration 8
```

---

## CLI Reference

```bash
floatify [options]
```

| Flag | Description | Default |
|------|-------------|---------|
| `--message` | Notification text | `Task complete!` |
| `--position` | Screen position | `bottomRight` |
| `--duration` | Auto-dismiss seconds | `6` |
| `--effect` | Animation effect | Position-specific |

### Position Options

| Flag | Description |
|------|-------------|
| `--position bottomLeft` | Bottom-left corner |
| `--position bottomRight` | Bottom-right corner |
| `--position topLeft` | Top-left corner |
| `--position topRight` | Top-right corner |
| `--position center` | Screen center |
| `--position menubar` | Below menu bar |
| `--position horizontal` | Horizontal layout at bottom-center |
| `--position cursorFollow` | Follows cursor position |

---

## Hook Setup

Floatify creates one floater per live Claude Code or Codex session. Hooks only update `running` and `complete` state through the CLI.

### Claude Code

Add this to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "sh -c '/usr/local/bin/floatify --status complete >/dev/null 2>&1'"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "sh -c '/usr/local/bin/floatify --status complete >/dev/null 2>&1'"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "sh -c '/usr/local/bin/floatify --status running >/dev/null 2>&1'"
          }
        ]
      }
    ]
  }
}
```

### Codex

First enable hooks in `~/.codex/config.toml`:

```toml
[features]
codex_hooks = true
```

Then create `~/.codex/hooks.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "sh -c '/usr/local/bin/floatify --status running >/dev/null 2>&1'"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "sh -c '/usr/local/bin/floatify --status complete >/dev/null 2>&1'"
          }
        ]
      }
    ]
  }
}
```

Codex reads hook commands from `~/.codex/hooks.json`, not from `config.toml`.

| Tool | Event | Command |
|------|-------|---------|
| Claude Code | `UserPromptSubmit` | `/usr/local/bin/floatify --status running` |
| Claude Code | `Stop` | `/usr/local/bin/floatify --status complete` |
| Claude Code | `SessionEnd` | `/usr/local/bin/floatify --status complete` |
| Codex | `UserPromptSubmit` | `/usr/local/bin/floatify --status running` |
| Codex | `Stop` | `/usr/local/bin/floatify --status complete` |

---

## Configuration

Floatify uses `positions.json` for per-position notification configuration. The bundled defaults are at `Floatify/Floatify/Resources/positions.json`.

### Config Fields

| Field | Description |
|-------|-------------|
| `margin` | Distance from screen edge (pixels) |
| `width` | Panel width (pixels) |
| `height` | Panel height (pixels) |
| `stackOffset` | Vertical spacing between stacked notifications (pixels) |

### User Overrides

Place your custom config at `~/.floatify/positions.json`. User values take precedence over bundled defaults.

```json
{
  "bottomRight": {
    "margin": 20,
    "width": 320,
    "height": 80,
    "stackOffset": 6
  }
}
```

### Supported Positions

`bottomLeft`, `bottomRight`, `topLeft`, `topRight`, `center`, `menubar`, `horizontal`, `cursorFollow`

## Architecture

```
Claude Code and Codex hooks -> floatify CLI -> FIFO pipe IPC -> Floatify.app -> NSPanel overlay
```

### Components

| Component | Description |
|-----------|-------------|
| **Floatify.app** | Background GUI app (LSUIElement) owning the floating NSPanel overlay |
| **floatify CLI** | Command-line tool that sends messages to the app via FIFO pipe IPC |

### Technical Highlights

- **FIFO pipe** (`/var/tmp/floatify.pipe`) for sub-ms IPC without network permissions
- **NSPanel** with `.nonactivatingPanel` to avoid stealing keyboard focus
- **`.popUpMenu`** window level floats above all apps including fullscreen windows
- **Max 3 stacked panels** with 4px vertical offset for multiple notifications

### IPC Protocol

JSON payload sent via FIFO pipe:

```json
{
  "message": "Task complete!",
  "corner": "bottomRight",
  "duration": "6"
}
```

---

## Contributing

Contributions are welcome.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

<p align="center">
  <a href="#table-of-contents">Back to top</a>
</p>
