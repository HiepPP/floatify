# DuckNotify

A lightweight macOS menu bar daemon that renders animated duck notifications in screen dead zones.

## Installation

1. Build the app:
   ```bash
   cd DuckNotify
   xcodegen generate
   xcodebuild -project DuckNotify.xcodeproj -scheme DuckNotify -configuration Release build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO
   ```

2. Open the built app:
   ```bash
   open ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Release/DuckNotify.app
   ```

3. Approve the CLI symlink prompt when it appears.

## Claude Code Integration

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "duck-notify --message 'Duck is waiting' --corner bottomRight --duration 10"
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
            "command": "duck-notify --message 'Bash done' --corner bottomLeft --duration 5"
          }
        ]
      }
    ]
  }
}
```

## CLI Usage

```bash
duck-notify --message "Task complete!" --corner bottomRight --duration 6
```

| Flag | Description | Default |
|------|-------------|---------|
| `--message` | Notification text | `"Task complete!"` |
| `--corner` | `bottomLeft` or `bottomRight` | `bottomRight` |
| `--duration` | Auto-dismiss seconds | `6` |
