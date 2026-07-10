# Features — Rules

## Structure

Each feature = folder with main spec file inside.

```
features/
  PF-0001-short-name/
    PF-0001-short-name.md     ← main spec
    PF-0001-notes.md          ← optional extras (prefixed!)
```

## Spec format

```markdown
# PF-NNNN — Feature Name
Type: product / technical / infrastructure
Status: draft / in-progress / done
Priority: P0 / P1 / P2
Source spec: path/to/spec.md (or "none")

## What
{1–3 sentences — what this feature does, plain language}

## Scope

| # | Src | Own | App | UI | BE | Del | Item |
|---|-----|-----|-----|----|----|-----|------|
| PF-NNNN-001 | spec | ✓ | ✓ | ✓ | ✓ |   | Fully working item |
| PF-NNNN-002 | me   | — | ✓ | ✓ | ✗ |   | UI done, backend pending |

## NOT in scope
- {What's explicitly excluded and why/when}

## Context
- {Background, technical notes — only what's needed}
```

### Scope table columns

| Column | Meaning |
|--------|---------|
| `#` | Item ID: `PF-NNNN-NNN` |
| `Src` | Who proposed: `spec` / `me` / `dev` |
| `Own` | Owner approved: `✓` / `✗` / `—` |
| `App` | Source-of-truth approved: `✓` / `✗` / `—` |
| `UI` | Frontend done: `✓` / `✗` |
| `BE` | Backend done: `✓` / `✗` |
| `Del` | Needs deletion: `✗` / empty |
| `Item` | User-facing description |

**Row order = priority** (top = highest). Describe **what the user can do**, not
UI elements.

## Rules

1. **One feature = one folder.** `PF-NNNN-short-name/PF-NNNN-short-name.md`
2. **Every feature has: What, Scope, NOT in scope, Context.**
3. **Scope = user-facing.** What the user can do, not UI elements.
4. **Short and laconic.** No water.
5. **Scope is a table.** Row order = priority.
6. **Features stay current** — always reflect current state.
7. **Artifacts use feature prefix.** `PF-NNNN-NNN-description.ext` — no generic names.
8. **Next number:** `ls features/ | grep '^PF' | sort | tail -1`
