## Add Theme Preset

Floatify loads bundled style presets from `Floatify/Floatify/Resources/StylePresets`.
Custom presets load from `~/.floatify/styles`.

## Format Choice

Use JSON for style presets.
It is safe for AI-assisted generation, easy to validate, and already matches Floatify visual-pack manifests.

Swift keeps defaults for missing fields.
This lets a preset override only colors, sizes, typography, component tokens, or entry effects.

## Create Preset

Create a JSON file in `~/.floatify/styles`.
Use a unique `id`.

```json
{
  "id": "minimal",
  "name": "Minimal",
  "palette": {
    "dark": {
      "running": "#FF6A4D",
      "idle": "#E8C75A",
      "complete": "#4DE88A"
    }
  },
  "typography": {
    "rowTitle": {
      "family": "Menlo",
      "weight": "bold",
      "design": "monospaced"
    },
    "statusPill": {
      "family": "Menlo",
      "weight": "semibold",
      "design": "monospaced"
    }
  },
  "variants": {
    "effects": {
      "entryEffects": ["fade"]
    }
  }
}
```

## Token Groups

- `palette` controls global colors and state colors.
- `shell` controls panel shell colors, border, glow, and shadow.
- `card` controls floater row gradient, avatar stage, border, and shadow.
- `sizes` controls layout, spacing, typography sizes, radii, and hit targets.
- `typography` controls font family, font size override, weight, and design.
- `components` controls header, row, avatar stage, status pill, and close button tokens.
- `variants.effects.entryEffects` controls entry animation choices.

## Typography Tokens

Typography roles are `panelHeaderTitle`, `panelHeaderChip`, `panelHeaderChipValue`, `rowTitle`, `rowMeta`, and `statusPill`.

```json
{
  "rowTitle": {
    "family": "Menlo",
    "weight": "bold",
    "design": "monospaced"
  }
}
```

Use `family: "system"` or omit `family` for the system font.
Supported `weight` values are `ultraLight`, `thin`, `light`, `regular`, `medium`, `semibold`, `bold`, `heavy`, and `black`.
Supported `design` values are `default`, `rounded`, `serif`, and `monospaced`.
Use optional `size` only when a theme must override the selected Display Style size.

## Reload Presets

Open Floatify Settings.
Use Floater Appearance to select a Theme.
Use Style Presets actions to reveal or reload the styles folder.
