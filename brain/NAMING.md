# Naming Law — the contract the guard enforces

This file is the **single, concrete, machine-checked** statement of how every
file and folder under `brain/` must be named. `GUIDE.md` explains *why*; this
file is the *law*. A `PreToolUse` guard hook
(`.wts/hooks/brain-guard.py`) blocks any `Write` / `Edit` / `Bash` that would
create a path here violating the rules below — so these are not suggestions.

> **PREFIX = `AURA`** (source of truth: `brain/PROJECT`). Everywhere the
> template docs say `P` / `PT` / `PF` …, read `AURA` / `AURAT` / `AURAF` …
> Example: `PT-0001` in `GUIDE.md`/`examples/` ⇒ `AURAT-0001` for real work.

## Building blocks

| Token | Pattern | Notes |
|-------|---------|-------|
| `PREFIX` | `AURA` | from `brain/PROJECT` |
| `KIND` | `T` `F` `D` `I` `R` `S` | task / feature / decision / investigation / roadmap / solution |
| `ID` | `AURA<KIND>-NNNN` | `NNNN` = exactly 4 digits, zero-padded |
| `STEP` | `NNN` | exactly 3 digits, forward-only |
| `slug` | `[a-z0-9]+(-[a-z0-9]+)*` | lowercase, digits, single hyphens. **No** uppercase, spaces, `_`, `.`, double/edge hyphens |

`NNNN` is claimed from `active-work.md` **before** creating the file (bump the
counter first — that is the whole concurrency story).

## Brain root — the only things allowed directly in `brain/`

- **Files:** `PROJECT`, `README.md`, `GUIDE.md`, `PROJECT-ORIENTATION.md`,
  `NAMING.md`, `AGENTS.md`, `CLAUDE.md`, `.gitignore`
- **Folders:** `tasks/` `features/` `decisions/` `investigations/`
  `roadmaps/` `solutions/` `okrs/` `examples/`

Anything else at the root (a stray `notes.md`, a new ad-hoc folder) is **denied.**

Inside any category folder, `README.md` and `RULES.md` are always allowed.

## Per-category law

### `tasks/` — folder per task (history, forward-only)
```
tasks/AURAT-NNNN-<slug>/                      ← task folder
       AURAT-NNNN-STEP-<slug>.md              ← step file (NNNN matches folder)
       AURAT-NNNN-<slug>.<ext>                ← optional prefixed artifact
```
- Step files go `001`, `002`, … forward only. Never renumber a committed step.
- Every file inside carries the **same** `AURAT-NNNN-` of its folder.
- No deeper nesting.

### `features/` — folder per feature (living)
```
features/AURAF-NNNN-<slug>/
          AURAF-NNNN-<slug>.md                ← main spec
          AURAF-NNNN-<slug>.<ext>             ← optional extra (prefixed!)
```

### `investigations/` — folder per investigation (history)
```
investigations/AURAI-NNNN-<slug>/
                AURAI-NNNN-<slug>.md          ← report
                AURAI-NNNN-<slug>.<ext>       ← optional extra (prefixed!)
```

### `decisions/` — flat files (living)
```
decisions/AURAD-NNNN-<slug>.md
```
No subfolders.

### `roadmaps/` — flat files (history)
```
roadmaps/AURAR-NNNN-<slug>.md
```
No subfolders.

### `solutions/` — flat files (living)
```
solutions/AURAS-NNNN-<slug>.md
```
No subfolders.

### `okrs/` — mirrored from the board
```
okrs/OKRS-SUMMARY.md
okrs/cycle-N-YYYY-MM-<slug>/                  ← N = board cycle ordinal
      AURA-O-N-<slug>/                        ← N = board objective id
       AURA-O-N.md
```

### `examples/` — EXEMPT
Illustrative, uses the placeholder prefix `P`. The guard does not enforce
naming under `examples/`. Delete it once real artifacts exist.

`<ext>` (for non-`.md` artifacts): `png jpg jpeg gif svg webp pdf txt csv tsv
json yaml yml mmd`. Step files and main specs are always `.md`.

## Quick self-check before you create anything

1. Did I bump the counter in `active-work.md` first?
2. Is the path under the right category folder for its kind letter?
3. Does every segment start with the correct `AURA<KIND>-NNNN`?
4. Is the slug lowercase-hyphen only?
5. Am I adding a new file to a *finished* task/investigation? → make a **new**
   artifact instead (history is never rewritten).

If the guard blocks you, read its message: it names the offending path, the
rule it broke, and the correct pattern. Fix the name — do not work around it.
