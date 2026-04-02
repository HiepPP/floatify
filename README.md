# Floatify

A lightweight macOS menu bar daemon that renders animated floating notifications in screen dead zones.

## Installation

1. Build the app:
   ```bash
   cd Floatify
   xcodegen generate
   xcodebuild -project Floatify.xcodeproj -scheme Floatify -configuration Release build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO
   ```

2. Open the built app:
   ```bash
   open ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Release/Floatify.app
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

## CLI Usage

```bash
floatify --message "Task complete!" --corner bottomRight --duration 6
```

| Flag | Description | Default |
|------|-------------|---------|
| `--message` | Notification text | `"Task complete!"` |
| `--corner` | `bottomLeft` or `bottomRight` | `bottomRight` |
| `--duration` | Auto-dismiss seconds | `6` |
