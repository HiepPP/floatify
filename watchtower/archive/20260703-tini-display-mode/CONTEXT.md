# Plan Context

## Shared Context

- Floatify uses `FloaterSize` as the source for display style choices.
- The Settings Display Style picker reads `FloaterSize.allCases`.
- Compact default tokens use `panelWidth: 210` and `persistentPanelWidth: 236`.
- Tini width means `panelWidth: 105` and `persistentPanelWidth: 118`.
- Keep Compact behavior and saved defaults unchanged.
- Run GitNexus impact before editing Swift symbols, per project rules.

## Decisions

- Add a new `tini` size instead of changing Compact.
- Keep the default selected size as Regular.
- Let presets that omit `tini` fall back to Swift default Tini tokens.

## Open Decisions

- None.

## References

- [Floatify/Floatify/FloatifySettings.swift](Floatify/Floatify/FloatifySettings.swift)
- [Floatify/Floatify/UI/Skeleton/FloaterStylePreset.swift](Floatify/Floatify/UI/Skeleton/FloaterStylePreset.swift)
- [Floatify/Floatify/Resources/StylePresets/default.json](Floatify/Floatify/Resources/StylePresets/default.json)
- [Floatify/Floatify/FloaterStatusView.swift](Floatify/Floatify/FloaterStatusView.swift)
- `./build.sh`
