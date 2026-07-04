# NEXT

## Current Active Plan

- Title: Unique project tabs with status priority
- Slug: 20260704-unique-project-tabs
- Status: ARCHIVED
- Updated: 2026-07-05

## Tracker

One row per TASK. Group ties together items that ship as one transaction.

| Order | TASK | Group | Status | Spec | Deps | Context | Notes |
|-------|------|-------|--------|------|------|---------|-------|
| 1 | TASK-001 Merge floater tabs by project | standalone | DONE | [watchtower/tasks/TASK-001-merge-tabs-by-project.md](watchtower/tasks/TASK-001-merge-tabs-by-project.md) | - | [watchtower/CONTEXT.md](watchtower/CONTEXT.md) | One tab per project, worst state wins. |

TASK Status labels: TODO, IN PROGRESS, BLOCKED, DONE.
Plan-level Status header: ACTIVE while any row is open, DONE when all rows DONE, ARCHIVED after archive.

## Plan Verify

- Run `./build.sh`, then start two Claude sessions in the same project. The floater shows one tab for that project.

## Handoff

- Next action: watch real multi-session use to confirm the merged tab color follows the worst state, then archive this plan.

## Archive

- Archived: 2026-07-03 -> watchtower/archive/20260703-tini-display-mode/
- Archived: 2026-07-05 -> watchtower/archive/20260704-unique-project-tabs/
