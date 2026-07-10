# brain/ — read this first

This is the **missus brain**: the project's knowledge base. Small, single-purpose
Markdown files with predictable IDs, committed to git. Prefix = `AURA` (see
`PROJECT`).

**Before creating or renaming anything here:**

1. Read **`NAMING.md`** — the naming law (machine-enforced).
2. Read the target folder's **`RULES.md`** — format for that category.
3. Bump the right counter in `<workspace>/active-work.md` **before** creating.

**A guard is watching.** `PreToolUse` hook `.wts/hooks/brain-guard.py` blocks any
file/folder creation under `**/missus/brain/**` whose name violates `NAMING.md`.
If you are blocked, the message tells you the exact rule and correct pattern —
fix the name, never work around it.

| I want to capture… | Goes in | ID |
|--------------------|---------|----|
| work being done now | `tasks/` | `AURAT-NNNN` |
| how the system behaves now | `features/` | `AURAF-NNNN` |
| a choice to remember | `decisions/` | `AURAD-NNNN` |
| research / deep dive | `investigations/` | `AURAI-NNNN` |
| a planning snapshot | `roadmaps/` | `AURAR-NNNN` |
| a reusable pattern | `solutions/` | `AURAS-NNNN` |
| a graded objective | `okrs/` | board id |

Full working method: `GUIDE.md`. Worked sample: `examples/`. Project mental
model: `PROJECT-ORIENTATION.md`.
