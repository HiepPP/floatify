# LEARN

## Plan

- Slug: 20260703-tini-display-mode
- Title: Tini Display Mode

## Outcome

- Added new `tini` FloaterSize with half-width Compact tokens across Swift defaults, JSON preset, and settings picker.
- Fixed header vs card width mismatch (`FloaterStatusView.swift`): cards now use `minWidth`/`idealWidth: persistentPanelWidth` + `maxWidth: .infinity` instead of a fixed width, so panel VStack sizes to the widest child and every row/header shares one edge-to-edge width regardless of size or CPU chip visibility.

## Lessons

- `FloaterPanelView` uses `.fixedSize()` on a VStack containing `FloaterPanelHeaderView` and per-item `FloaterStatusView` rows. When rows use a fixed `width:`, SwiftUI sizes each child independently and misalignment appears whenever the header's natural width differs from the row's fixed width (e.g. CPU chip toggled on). Use `minWidth`/`idealWidth`/`maxWidth: .infinity` on the row instead so the shared parent's width negotiation keeps header and rows flush.
