# Learn 20260704-unique-project-tabs

## Summary

Discrepancy: none found. Plan matched shipped work.

## Per TASK

- TASK-001: match. Spec asked for one tab per project with worst-state priority (running > idle > complete), keeping representative session id for tap/close. Shipped `mergePriority` on `ClaudeStatusState` and `mergedItemsByProject` in [Floatify/Floatify/FloaterPanelManager.swift](Floatify/Floatify/FloaterPanelManager.swift) exactly as specced. Verified by build + live pipe payload test showing 1 tab for 2 sessions of the same project.

## Plan-Level

- none. Single-TASK plan, no cross-TASK issues.

## Lessons

- Screenshot-based color verification of the floater indicator is unreliable (dot too small, 15s auto-transition from running to idle). Prefer live multi-session observation or code review for state-color checks in future plans.
