# NEXT

## Current Active Plan

- Title: Tini Display Mode
- Slug: 20260703-tini-display-mode
- Status: DONE
- Updated: 2026-07-03

## Tracker

| Order | TASK | Group | Status | Spec | Deps | Context | Notes |
|-------|------|-------|--------|------|------|---------|-------|
| 1 | TASK-001 Add Tini display mode | standalone | DONE | [watchtower/tasks/TASK-001-add-tini-display-mode.md](watchtower/tasks/TASK-001-add-tini-display-mode.md) | - | [watchtower/CONTEXT.md](watchtower/CONTEXT.md) | Tini ships as a half-width mode. |

## Plan Verify

- `./build.sh` -> Floatify builds, installs, updates the CLI symlink, and relaunches.
- Manual app check -> Settings shows Tini in Display Style, and Tini floaters are half Compact width.

## Handoff

- Next action: None. TASK-001 is done.

## Archive

- None.
