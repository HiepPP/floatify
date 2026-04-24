---
name: generate-theme
description: "Use when creating, editing, reviewing, or validating Floatify UI theme presets. Guides agents to ask for theme vibe and details, generate a final image design with imagegen that strictly preserves the Floatify skeleton, then change only theme preset scope without touching app logic, Swift components, IPC, panel behavior, visual packs, or non-theme files."
---

## Purpose

Create or edit Floatify theme presets safely.
Theme work means JSON preset changes only unless user explicitly expands scope.

## Scope

Allowed by default:

- `~/.floatify/styles/*.json`
- `Floatify/Floatify/Resources/StylePresets/*.json`
- `~/.floatify/styles/designs/*` for user-level generated design references
- `Floatify/Floatify/UI/Styles/Designs/*` for repo-level generated design references
- `Floatify/Floatify/UI/Styles/Docs/AddStylePreset.md` only when docs are requested

Do not edit by default:

- Swift files
- Xcode project files
- IPC, CLI, session monitoring, panel lifecycle, or settings logic
- visual packs, avatar assets, effect code, or app resources outside theme preset JSON

If requested theme cannot be done with current JSON tokens, stop and explain the missing token.
Do not add Swift support unless user explicitly asks to extend the theme system.

## Required Image Design Step

Use the `imagegen` skill before implementing a new theme or major theme rewrite.

Read when needed:

- `/Users/hiep/.codex/skills/.system/imagegen/SKILL.md`

Use built-in `image_gen` mode by default.
Generate one UI mockup image based on:

- current `Floatify/Floatify/Resources/StylePresets/default.json` as the theme blueprint
- current Floatify floater skeleton
- selected base preset
- user vibe prompt
- user theme details
- current theme token limits

Skeleton is locked.
Only change style tokens: color, typography, border, radius, shadow, density, opacity, and effect mood.
Do not add, remove, rename, or reposition UI components.

Treat the generated image as the final visual design.
After it is accepted or clearly matches the prompt, implement JSON tokens to follow that design.
Do not improvise a different visual direction during JSON implementation.

If image design shows unsupported UI structure, keep JSON within supported tokens.
Report what cannot be implemented without extending the skeleton.
If image design violates the skeleton, do not implement from it.
Regenerate once with stricter skeleton wording or stop and report the mismatch.

For project-bound repo themes, save the design reference in `Floatify/Floatify/UI/Styles/Designs/`.
For user-level custom themes, save the design reference in `~/.floatify/styles/designs/`.
Do not overwrite existing design images unless user explicitly asks.

## Default Theme Blueprint

Always read `Floatify/Floatify/Resources/StylePresets/default.json` before image generation.
Use the current file contents, not memory or prior summaries.

Default theme is the canonical blueprint for:

- JSON schema
- token group order
- component names
- variant names
- supported visual controls
- current sizes, spacing, proportions, and effects

Feed a compact blueprint summary into the imagegen prompt.
The prompt must say that the mockup must preserve the default theme structure and only restyle token values.

Required blueprint prompt block:

```text
Default theme blueprint:
- use current default.json as canonical theme file shape
- keep the same component list, token groups, variants, and size roles
- keep current compact floater proportions from default.json
- only reinterpret colors, typography, border, radius, shadow, opacity, density, and effect mood
- do not invent JSON keys or visual components outside the default theme system
```

For new theme JSON, start from the `default.json` shape.
Change `id`, `name`, `description`, then modify only token values needed for the requested vibe.
Do not invent top-level groups or component names.
If a desired visual cannot map to default theme tokens, stop and report the missing token.

## Skeleton Lock

The generated design must keep the live Floatify persistent floater skeleton.

Required panel structure:

- one compact persistent NSPanel floater only
- header keeps Floatify app mark, `Floatify` title, optional CPU chip, collapse button, and settings button
- each session row keeps left avatar stage, project title, footer line, status pill, pencil icon with modified file count, and close button
- status pill stays in the footer line before the pencil change count
- close button stays at top trailing of the row
- avatar stage stays on the left
- project title stays in the row body

Forbidden additions:

- no extra cards, panels, menus, charts, timers, Wi-Fi widgets, battery widgets, percentage widgets, cups, badges, or decorative objects that are not already in the skeleton
- no new titles such as `UI polish & responsive`
- no replacement of the pencil change count with another metric
- no moving status to the far right if the current skeleton places it in the footer line
- no invented app screens, toolbars, nav bars, or marketing layout

Image validation must pass before JSON work:

- compare generated image against the required panel structure
- reject the image if any required component is missing
- reject the image if any forbidden addition appears
- reject the image if component order or position changes
- only then write or update the theme JSON

## Required Questions

Before creating a new theme, ask for missing details.
Use the platform question tool if available.
If no question tool is available, ask concise plain-text questions.

Ask:

- Theme vibe: minimal, terminal, glass, gaming, high contrast, compact, retro, professional, etc.
- Base preset: `default`, `terminal`, or another existing preset.
- Target location: custom user preset in `~/.floatify/styles` or repo preset in `Floatify/Floatify/Resources/StylePresets`.
- Details: colors, typography, spacing density, border style, shadow strength, status colors, and effects.
- Whether to accept one generated design directly or generate variants first.

If user already gave enough detail, proceed without more questions.

## Workflow

1. Read current theme files before editing:
   - `Floatify/Floatify/Resources/StylePresets/default.json`
   - `Floatify/Floatify/Resources/StylePresets/terminal.json`
   - requested target preset, if it exists
2. Extract the default theme blueprint from `default.json`.
3. Confirm target file path and theme id.
4. Use `imagegen` to generate the final design reference with Default Theme Blueprint and Skeleton Lock wording.
5. Inspect the generated image against Default Theme Blueprint and Skeleton Lock.
6. Regenerate once or stop if the image adds, removes, renames, or repositions components.
7. Save the accepted design reference if it is project-bound.
8. Create or update only one preset JSON unless user asks for more.
9. For new themes, start from `default.json` shape and mutate token values only.
10. Keep stable keys readable and grouped:
   - `id`
   - `name`
   - `description`
   - `palette`
   - `shell`
   - `card`
   - `sizes`
   - `typography`
   - `components`
   - `variants`
11. Preserve existing app behavior.
12. Validate JSON with `jq empty`.
13. If repo preset changed, run `./build.sh`.
14. If only `~/.floatify/styles` changed, reload themes from Floatify Settings or restart Floatify.

## Image Design Prompt Shape

When using `imagegen`, describe the design as a UI mockup, not a marketing image.
Keep the skeleton stable.

Prompt with:

- Use case: `ui-mockup`
- Asset type: Floatify floater theme design reference
- Primary request: user vibe and theme details
- Blueprint: include Default Theme Blueprint block derived from current `default.json`
- Skeleton: one compact persistent macOS NSPanel floater; header with app mark, `Floatify` title, optional CPU chip, collapse button, settings button; session row with left avatar stage, project title, footer status pill, pencil change count, and top-trailing close button
- Constraints: keep exact component set, labels, order, and positions; only change visual styling; no new business logic; no extra panels; no unrelated app screens
- Forbidden: cups, Wi-Fi, battery, timers, random percentages, invented page titles, new widgets, extra badges, charts, menus, or marketing sections
- Output: polished final design reference that JSON tokens should follow

## Theme JSON Rules

Use JSON only.
For new themes, prefer full `default.json` shape for maximum skeleton adherence.
Keep fields partial only for small edits to existing custom themes.
Swift defaults fill missing values.

Use `family: "system"` or omit `family` for the system font.
Use installed macOS font names for custom fonts.

Typography roles:

- `panelHeaderTitle`
- `panelHeaderChip`
- `panelHeaderChipValue`
- `rowTitle`
- `rowMeta`
- `statusPill`

Supported font weights:

- `ultraLight`
- `thin`
- `light`
- `regular`
- `medium`
- `semibold`
- `bold`
- `heavy`
- `black`

Supported font designs:

- `default`
- `rounded`
- `serif`
- `monospaced`

## Minimal Theme Template

```json
{
  "id": "theme-id",
  "name": "Theme Name",
  "description": "Short theme description.",
  "palette": {
    "dark": {
      "primaryText": "#FFFFFF",
      "secondaryText": { "hex": "#FFFFFF", "alpha": 0.72 },
      "running": "#FF6A4D",
      "idle": "#E8C75A",
      "complete": "#4DE88A"
    }
  },
  "typography": {
    "rowTitle": {
      "family": "system",
      "weight": "heavy",
      "design": "rounded"
    },
    "statusPill": {
      "family": "system",
      "weight": "bold",
      "design": "rounded"
    }
  },
  "variants": {
    "effects": {
      "entryEffects": ["fade", "slide"]
    }
  }
}
```

## Verification

Always run:

```bash
jq empty <theme-file>
```

For repo preset changes, run:

```bash
./build.sh
```

Then confirm the installed resource if applicable:

```bash
jq -r '.id + " " + .name' /Applications/Floatify.app/Contents/Resources/<theme-file>
```

## Output

Report:

- design image path or preview status
- created or changed theme file
- theme id and name
- key tokens changed
- verification command results
- any unsupported request that could not stay inside theme scope
