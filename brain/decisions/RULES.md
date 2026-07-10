# Decisions — Rules

## Format

```markdown
# PD-NNNN — Decision Title

Date: YYYY-MM-DD
Status: accepted / superseded / deprecated

## Decision
{What was decided, 1–3 sentences}

## How it works
{Implementation details, only if needed}

## Why
{Motivation — keep short}
```

## Rules

1. **Flat files, no folders.** `PD-NNNN-short-name.md` directly in `decisions/`.
2. **Short.** Decision + why. No essays.
3. **Status is current.** Update if superseded (point to the new `PD-*`).
4. **Next number:** `ls decisions/ | grep '^PD' | sort | tail -1`
