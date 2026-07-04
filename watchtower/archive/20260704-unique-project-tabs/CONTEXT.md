# Plan Context

## Shared Context

- Floatify shows one floater tab per session today. Sessions come from Claude and Codex monitors plus pipe payloads.
- [Floatify/Floatify/AppDelegate.swift](Floatify/Floatify/AppDelegate.swift) builds `PersistentStatusItem` per session and calls `showPersistentStatuses` (line 81).
- [Floatify/Floatify/FloaterPanelManager.swift](Floatify/Floatify/FloaterPanelManager.swift) renders one tab per item id in `showPersistentStatuses` and `refreshFloaterPanel`.
- State colors: `running` is red, `idle` is yellow, `complete` is green. See `ClaudeStatusState.indicatorColor`.
- Rebuild and install with `./build.sh` after code changes.

## Decisions

- Tabs are unique by project name. Sessions still tracked per id underneath.
- Merged tab state uses worst-state priority: running > idle > complete.
- Merged tab keeps the id of the session that supplied the winning state, so tap and close keep working.

## Open Decisions

- None.

## References

- [Floatify/Floatify/AppDelegate.swift](Floatify/Floatify/AppDelegate.swift)
- [Floatify/Floatify/FloaterPanelManager.swift](Floatify/Floatify/FloaterPanelManager.swift)
