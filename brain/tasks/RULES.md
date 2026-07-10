# Tasks — Rules

## Structure

Each task = folder. Step files inside carry the task prefix.

```
tasks/
  PT-0001-short-name/
    PT-0001-001-check.md
    PT-0001-002-understand.md
    PT-0001-003-context.md
    PT-0001-004-spec.md
    PT-0001-005-approval.md
    PT-0001-006-execute.md
    PT-0001-007-approved.md         ← task done only when this exists
```

## Rules

1. **One task = one folder.** `PT-NNNN-short-name/`
2. **Step files carry task prefix.** `PT-NNNN-NNN-description.md`
3. **Steps go forward only.** `001`, `002`, `003`… No rewrites, no branches.
4. **Task is done ONLY when user approves.** Last file must be `PT-NNNN-NNN-approved.md`.
5. **Step files are short.** What was done, what was decided, what's next.
6. **Next number:** `ls tasks/ | grep '^PT' | sort | tail -1`

> `PT` = `${PREFIX}T`. Replace `P` with your project prefix from `PROJECT`.
