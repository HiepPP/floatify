## Floatify

[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-111827?style=flat-square)](https://github.com/HiepPP/floatify)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-f97316?style=flat-square)](https://github.com/HiepPP/floatify)
[![Website](https://img.shields.io/badge/Website-floatify--app.vercel.app-0ea5e9?style=flat-square)](https://floatify-app.vercel.app)

Floatify is a macOS menu bar app that shows persistent session HUDs for Claude Code and Codex, plus temporary CLI notifications.

Website: https://floatify-app.vercel.app

![Floatify Demo](website/public/demo.gif)

## Table Of Contents

- [Features](#features)
- [Why Floatify](#why-floatify)
- [Current Notes](#current-notes)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [CLI Reference](#cli-reference)
- [Corner Positions](#corner-positions)
- [Claude Code And Codex Integration](#claude-code-and-codex-integration)
- [Architecture](#architecture)
- [Contributing](#contributing)
- [License](#license)

## Features

- One persistent floater per live Claude Code or Codex session
- Project label, color status, sprite avatar, git modified file count, and last activity time
- Theme, display style, and idle timeout in the built-in Settings window
- Drag to move floaters, close individual floaters, and restack them with Arrange
- Click a floater to open its project in VS Code when the path is known
- Temporary notifications still support all screen positions, including `menubar`, `horizontal`, and `cursorFollow`
- FIFO pipe IPC at `/var/tmp/floatify.pipe`
- Non-activating `NSPanel` overlays that stay visible without stealing focus

## Why Floatify

| Approach | Session context | Focus impact | What you miss |
| --- | --- | --- | --- |
| Terminal output only | Low | None | Easy to miss when another app is frontmost |
| Standard notifications | Low | Medium | Short-lived and not project-aware |
| Floatify | High | Low | Persistent per-session HUDs with project and git context |

## Current Notes

- Codex can infer task state from session logs.
- Claude session discovery is automatic, but precise running and complete state still depends on hooks.
- `~/.floatify/positions.json` only affects temporary notifications. It does not style persistent session floaters.
- Persistent floater placement is drag-and-arrange today. There is no full layout editor yet.

## Installation

Prerequisites:

- macOS 13 or later
- XcodeGen installed with `brew install xcodegen`

Recommended install:

```bash
git clone https://github.com/HiepPP/floatify.git
cd floatify
./install.sh
```

`./install.sh` builds the app and CLI, installs `Floatify.app` to `/Applications`, links `floatify` into a writable bin directory, and launches the app.

Developer rebuild for the current machine:

```bash
./build.sh
```

Compile-only commands:

```bash
cd Floatify
xcodegen generate
xcodebuild -project Floatify.xcodeproj -scheme Floatify -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO
xcodebuild -project Floatify.xcodeproj -scheme floatify -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO
```

## Quick Start

Temporary notification:

```bash
floatify --message "Deploy done!" --position bottomRight --duration 6
```

Session status updates:

```bash
floatify --status running
floatify --status complete
```

More examples:

```bash
floatify --message "Watch this" --position cursorFollow --duration 8
floatify --message "Menu bar alert" --position menubar --duration 5
floatify --message "Horizontal alert" --position horizontal --duration 5
```

## CLI Reference

```bash
floatify [options]
```

| Flag | Meaning | Default |
| --- | --- | --- |
| `--message` | Temporary notification text | `Task complete!` |
| `--position` or `--corner` | Notification position | `bottomRight` |
| `--duration` | Auto-dismiss seconds for temporary notifications | `6` |
| `--project` | Project label in the payload | Current folder name |
| `--effect` | Notification entry effect override | Position default |
| `--status` | Session status update | Not set |

Status values:

- `running`
- `idle`
- `complete`
- `done`

Current status behavior:

- `running` shows the red running state
- `idle` shows the yellow idle state
- `complete` and `done` enter idle first, then auto-transition to green after the idle timeout
- the default idle timeout is 15 seconds

## Corner Positions

| Position | Behavior |
| --- | --- |
| `bottomLeft` | Bottom-left corner |
| `bottomRight` | Bottom-right corner |
| `topLeft` | Top-left corner |
| `topRight` | Top-right corner |
| `center` | Screen center |
| `menubar` | Centered below the menu bar |
| `horizontal` | Bottom-centered horizontal stack |
| `cursorFollow` | Tracks the cursor position |

Optional JSON override for temporary notifications only:

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

Save that file to `~/.floatify/positions.json`.

## Claude Code And Codex Integration

Claude Code example:

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
    ]
  }
}
```

Codex example:

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
    ]
  }
}
```

Current integration notes:

- Claude examples in this repo use `~/.claude/settings.json`
- Codex examples in this repo use `~/.codex/hooks.json`
- This repo does not recommend `UserPromptSubmit` for Claude because it can interfere with prompt flow
- Codex can still infer task state from its session logs, but hooks keep transitions explicit

## Architecture

```text
Claude hooks / floatify CLI / session monitors
  -> FIFO pipe IPC + process scan + Codex session log scan
  -> Floatify.app
  -> temporary notifications and persistent session floaters
```

| Component | Role |
| --- | --- |
| `Floatify.app` | Background macOS app that owns the overlay windows and menu bar UI |
| `floatify` CLI | Sends notification and status payloads through the FIFO pipe |
| `ClaudeSessionMonitor` | Finds live Claude sessions and project paths |
| `CodexActivityMonitor` | Finds live Codex sessions and infers task state from session logs |
| `SettingsView` | Controls floater theme, display style, and idle timeout |

## Contributing

1. Fork the repository.
2. Create a branch for your change.
3. Build and test locally.
4. Open a pull request.

## License

This repository does not currently include a license file.

[Back to top](#floatify)
