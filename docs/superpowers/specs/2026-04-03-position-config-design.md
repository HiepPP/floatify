# Floatify Per-Position Configuration Design

## Overview

Add per-position configuration for margin, panel size, and stack offset via JSON config files.

## Config File Location

- **Bundled default:** `Floatify.app/Contents/Resources/positions.json`
- **User override:** `~/.floatify/positions.json`

## Config Schema

```json
{
  "bottomLeft": { "margin": 10, "width": 280, "height": 68, "stackOffset": 4 },
  "bottomRight": { "margin": 10, "width": 280, "height": 68, "stackOffset": 4 },
  "topLeft": { "margin": 10, "width": 280, "height": 68, "stackOffset": 4 },
  "topRight": { "margin": 10, "width": 280, "height": 68, "stackOffset": 4 },
  "center": { "margin": 0, "width": 280, "height": 68, "stackOffset": 4 },
  "menubar": { "margin": 10, "width": 280, "height": 68, "stackOffset": 4 },
  "horizontal": { "margin": 20, "width": 280, "height": 68, "stackOffset": 8 },
  "cursorFollow": { "margin": 20, "width": 280, "height": 68, "stackOffset": 4 }
}
```

## Load Logic

1. App launches → load bundled `positions.json` from app bundle Resources
2. Check if `~/.floatify/positions.json` exists
3. If yes, merge user config over bundled defaults (user values override)
4. Cache merged config in `PositionConfigManager.shared` for app lifetime

## Architecture

### PositionConfigManager

- Singleton that owns merged config
- `config(for: Corner) -> PositionConfig` method
- `PositionConfig` struct: margin, width, height, stackOffset
- Falls back to defaults for any missing keys

### New Files

- `Floatify/Floatify/PositionConfigManager.swift`
- `Floatify/Floatify/Resources/positions.json`

### Modified Files

- `Floatify/Floatify/FloatNotificationManager.swift` - uses `PositionConfigManager` for size/margin/offset

## Field Meanings

| Field | Purpose |
|-------|---------|
| margin | Distance from screen edge (padding in cornerOrigin) |
| width | Panel width |
| height | Panel height |
| stackOffset | Vertical spacing between stacked notifications |

## Backwards Compatibility

- If config file is missing or malformed, use hardcoded defaults from existing code
- Existing CLI behavior unchanged
- All 8 positions have sensible defaults
