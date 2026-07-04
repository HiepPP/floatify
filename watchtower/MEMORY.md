# Watchtower Memory

## Core Intent

- Floater tabs are unique by project name. Sessions stay tracked per id; merging happens only at render input in `FloaterPanelManager.showPersistentStatuses`.

## Planning Rules

- Merged tab state uses `ClaudeStatusState.mergePriority`: running(0) > idle(1) > complete(2). Lower wins.
- The representative item keeps its session id so tap acknowledge and close-by-id keep working. Do not invent project-based ids.

## Source Anchors

- [Floatify/Floatify/FloaterPanelManager.swift](Floatify/Floatify/FloaterPanelManager.swift): `mergedItemsByProject`, `mergePriority`, `showPersistentStatuses`.
- [Floatify/Floatify/AppDelegate.swift](Floatify/Floatify/AppDelegate.swift): builds one `PersistentStatusItem` per session; leave per-session tracking alone.

## Learnings

- 2026-07-04: SourceKit shows false cross-file "cannot find type" errors in this project; trust `./build.sh` output. Screenshot color checks on the floater indicator are unreliable; verify state colors by watching a live session or by code review.
