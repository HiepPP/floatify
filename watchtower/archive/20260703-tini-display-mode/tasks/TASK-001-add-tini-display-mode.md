# TASK-001 Add Tini display mode

Group: standalone

## Brief

Goal: Add a Tini Display Style. Tini must render at half the width of Compact.

Change: Compact stays the same -> Tini is available as a smaller separate mode.

How:

- Run GitNexus impact for `FloaterSize` and `FloaterStyleSizes` before editing Swift.
- Add a `tini` case to `FloaterSize` with display name `Tini`.
- Add default Tini size tokens in `FloaterStyleSizeTokens.defaultTokens(for:)`.
- Set Tini width tokens to half Compact: `panelWidth: 105` and `persistentPanelWidth: 118`.
- Add Tini storage and decoding support to `FloaterStyleSizes`.
- Add Tini size values to the bundled default style preset.
- Adjust persistent floater layout only if the half-width row overlaps content.

Files:

- [Floatify/Floatify/FloatifySettings.swift](../../Floatify/Floatify/FloatifySettings.swift) (add the `tini` display style case and label)
- [Floatify/Floatify/UI/Skeleton/FloaterStylePreset.swift](../../Floatify/Floatify/UI/Skeleton/FloaterStylePreset.swift) (add Tini size defaults, decoding, and token lookup)
- [Floatify/Floatify/Resources/StylePresets/default.json](../../Floatify/Floatify/Resources/StylePresets/default.json) (add bundled Tini size values)
- [Floatify/Floatify/FloaterStatusView.swift](../../Floatify/Floatify/FloaterStatusView.swift) (change only if half-width Tini layout needs fit fixes)

Expected result:

- Settings Display Style shows Tini.
- Tini width is exactly half Compact width for panel and persistent panel tokens.
- Compact, Regular, Large, Larger, and Super Large keep their current sizes.
- Custom presets that omit `tini` still load with Swift default Tini tokens.
- Persistent Tini floaters fit without text or controls overlapping.

Prompt:

```text
Implement TASK-001. Add a Tini Display Style. Keep Compact unchanged. Make Tini panelWidth 105 and persistentPanelWidth 118. Update size decoding and the bundled default preset. Run ./build.sh.
```

## Verify

- `./build.sh` -> build and install complete without errors.
- Manual Settings check -> Display Style includes Tini.
- Manual floater check -> a Tini floater is half the Compact width and has no content overlap.
