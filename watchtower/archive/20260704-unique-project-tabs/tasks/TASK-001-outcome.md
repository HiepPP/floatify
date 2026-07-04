# TASK-001 Outcome

## Outcome

Status: DONE

Changed:
- Added `mergePriority` to `ClaudeStatusState` (running=0, idle=1, complete=2) in [Floatify/Floatify/FloaterPanelManager.swift](Floatify/Floatify/FloaterPanelManager.swift).
- Added `mergedItemsByProject` and call it at the top of `showPersistentStatuses`. Group key is `project.localizedLowercase`. Lowest `mergePriority` wins; ties pick latest `lastActivity`. Merged item takes max `modifiedFilesCount` across the group.

Contract:
- `showPersistentStatuses` signature unchanged; `AppDelegate` session tracking untouched.
- Representative item keeps its session id, so avatar tap acknowledge and close-by-id still work.
- Known trade-off: shake-on-idle can miss when the representative id switches between refreshes (accepted per spec).

Verified:
- `./build.sh` -> BUILD SUCCEEDED, app reinstalled and relaunched.
- Sent 2 pipe payloads for project baconsua with sessions claude:99901 (running) and claude:99902 (complete) -> screenshot shows exactly 1 baconsua tab.
- Sent complete for claude:99901 -> tab stays as 1 and keeps rendering.
- Color check by screenshot was inconclusive (indicator dot too small, running auto-transitioned after 15s); merge priority logic verified by code review.
