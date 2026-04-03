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
  <img src="https://raw.githubusercontent.com/HiepPP/floatify/main/demo.gif" alt="Floatify Demo" width="600">
</p>

---

## Table of Contents

- [Features](#features)
- [Why Floatify](#why-floatify)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [CLI Reference](#cli-reference)
- [Claude Code Integration](#claude-code-integration)
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
- Claude Code hook integration for automation

## Why Floatify

| Benefit | Description |
|---------|-------------|
| Zero distraction | Notifications appear in screen dead zones, never blocking your work |
| Focus-friendly | Non-activating NSPanel never steals keyboard focus |
| Blazing fast | FIFO pipe IPC achieves sub-millisecond latency |
| Clean integration | Works seamlessly with Claude Code hooks |
| Lightweight | No network permissions, minimal resource usage |

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
floatify --message 'Task complete!' --corner bottomRight --duration 6

# Different positions
floatify --message 'Bottom Left!' --corner bottomLeft --duration 4
floatify --message 'Top Right!' --corner topRight --duration 4
floatify --message 'Centered!' --corner center --duration 5

# Follows your cursor
floatify --message 'Following cursor!' --corner cursorFollow --duration 8
```

---

## CLI Reference

```bash
floatify [options]
```

| Flag | Description | Default |
|------|-------------|---------|
| `--message` | Notification text | `Task complete!` |
| `--corner` | Screen position | `bottomRight` |
| `--duration` | Auto-dismiss seconds | `6` |
| `--effect` | Animation effect | Position-specific |

### Corner Positions

| Position | Description |
|----------|-------------|
| `bottomLeft` | Bottom-left corner |
| `bottomRight` | Bottom-right corner |
| `topLeft` | Top-left corner |
| `topRight` | Top-right corner |
| `center` | Screen center |
| `menubar` | Below menu bar |
| `horizontal` | Horizontal layout at bottom-center |
| `cursorFollow` | Follows cursor position |

---

## Claude Code Integration

Add to your `~/.claude/settings.json` to get notifications when Claude Code finishes tasks:

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
            "command": "floatify --message 'Bash done' --corner bottomLeft --duration 5"
          }
        ]
      }
    ]
  }
}
```

---

## Architecture

```
Claude Code hooks -> floatify CLI -> FIFO pipe IPC -> Floatify.app -> NSPanel overlay
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
