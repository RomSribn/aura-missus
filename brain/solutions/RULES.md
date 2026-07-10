# Solutions — Rules

## Format

```markdown
# PS-NNNN — Solution Title

Date: YYYY-MM-DD
Status: draft / active / superseded

## Problem
{What recurring problem this solves}

## Solution
{Short practical rule}

## Current Behavior
{What is already implemented}

## Next
{What must be added or changed next}
```

## Rules

1. **Flat files, no folders.** `PS-NNNN-short-name.md` directly in `solutions/`.
2. **Reusable only.** Do not document one-off task details here.
3. **Practical.** Describe how future implementation should look.
4. **Short by default.** Long research belongs in `investigations/`.
5. **Next number:** `ls solutions/ | grep '^PS' | sort | tail -1`
