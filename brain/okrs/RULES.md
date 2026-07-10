# OKRs — Rules

## Naming

- Cycle folder: `cycle-N-YYYY-MM-<short-name>` — N = board cycle ordinal,
  YYYY-MM = objective start month.
- Objective folder: `P-O-N-<slug>` — N = board objective id.
- Objective file: `P-O-N.md` inside its folder.

## Source of truth

The board (Jira/Oboard/etc.) owns grades, status, dates. The knowledgebase copy
is a tracked mirror + context. On re-export of the OKR report:
1. Update grade/status/dates in each `P-O-N.md` header.
2. Update the `OKRS-SUMMARY.md` table.
3. Note the change in the objective's progress log with the export date.

## Objective file format

```markdown
# P-O-N — <objective title>

| Field | Value |
|-------|-------|
| Cycle | First/Second/... Month |
| Window | <start> → <due> |
| Status | On track / At risk / Off track |
| Grade | <n>% |
| Owner | ... |

## Why / definition of done
## Key results
## Progress log
## Related internal artifacts
```

## Boundary

- `okrs/` = measured objectives (what you are graded on).
- `roadmaps/` = planning snapshots (intent in time).
- `features/` = product scope. `tasks/` = execution history.
