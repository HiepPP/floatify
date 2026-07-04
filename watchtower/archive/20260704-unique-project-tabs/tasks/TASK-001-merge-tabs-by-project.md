# TASK-001 Merge floater tabs by project

Group: standalone

## Brief

Goal: show one floater tab per project name, even when the project has many sessions. The tab shows the worst session state.

Change: one tab per session id -> one tab per project name with state priority running > idle > complete.

State priority examples from the user:

- One session idle (yellow), one running (red) -> tab is red.
- One session idle (yellow), one complete (green) -> tab is yellow.
- All sessions running -> red.
- All sessions complete -> green.

Code facts behind the priority:

- `ClaudeStatusState` ([Floatify/Floatify/FloaterPanelManager.swift](Floatify/Floatify/FloaterPanelManager.swift) line 17) is `Equatable` only. No priority ordering exists yet. Add one: running(0) > idle(1) > complete(2). Worst state = lowest index.
- Color mapping comes from `indicatorColor` (line 46): running=red, idle=yellow, complete=green.
- `showPersistentStatuses` (line 191) has no grouping today. Items only pass a hidden-id filter and `sortPersistentItems` sort, so each session id renders its own tab.
- `PersistentStatusItem` fields (line 58) are all `let`; build a new representative item when merging.
- Shake-on-idle (line 208) compares `previousItemsByID[item.id]` state transitions. If the representative id switches between refreshes, shake detection can miss or misfire. Handle or accept this explicitly.

How:

- Add a priority value to `ClaudeStatusState` (running=0, idle=1, complete=2). Lower value wins the merge.
- In `FloaterPanelManager.showPersistentStatuses`, group incoming items by `project` using `localizedCaseInsensitiveCompare` semantics (lowercased key is fine), same compare as `sortPersistentItems`.
- Pick one representative item per project: highest priority state wins (running > idle > complete). On tie, pick the item with the latest `lastActivity`.
- Keep the representative item's `id` so avatar tap acknowledgement and close-by-id still work.
- Sum or take max of `modifiedFilesCount` across the group; use max unless a simpler choice reads better in code review.
- Keep hidden and closing id filters working: when the representative id is hidden by close, the project tab hides.
- Do not change session tracking in `AppDelegate`; merging happens at render input only.

Files:

- [Floatify/Floatify/FloaterPanelManager.swift](Floatify/Floatify/FloaterPanelManager.swift) (group items by project in `showPersistentStatuses` before filtering and sorting)

Expected result:

- A project with 2 live sessions shows exactly 1 tab.
- Tab color follows the worst state across that project's sessions.
- Closing the tab hides it; a later state change from another session of the same project can bring it back.
- Projects with one session behave as before.

## Verify

- `./build.sh` -> build succeeds and app relaunches.
- Manual: start 2 Claude sessions in one project (for example baconsua). Floater shows 1 tab for it.
- Manual: keep one session running while the other finishes -> tab stays red. When the running one turns idle -> tab turns yellow. When all complete -> green.
- Manual: a project with a single session still shows and updates as before.
