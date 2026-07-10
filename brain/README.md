# Knowledgebase

Everything the team knows about a project, captured as small structured
Markdown files under version control. No wiki, no external tool — the knowledge
lives next to the work and travels with the repo.

This folder is a **reusable template**. Copy it into a project (or a private
side repo), set your project prefix, and start filling it in. The conventions
below are what keep it navigable as it grows to hundreds of artifacts.

## Start here

1. Read `GUIDE.md` — how to work and maintain a knowledgebase this way.
2. Set your prefix in `PROJECT` (one short token, e.g. `P`).
3. Browse `examples/` — a fully worked task, investigation, decision, feature.
4. Each category folder has its own `README.md` (what it is) and `RULES.md`
   (naming + format law).

## Structure

| Folder | What's inside | Kind | ID letter |
|--------|---------------|------|-----------|
| `features/` | Feature specs — what the system does | FEATURE | `F` |
| `tasks/` | Task tracking with step files — the doing | TASK | `T` |
| `decisions/` | Architectural / process decisions | DECISION | `D` |
| `investigations/` | Research and deep dives | INVESTIGATE | `I` |
| `roadmaps/` | Planning snapshots mapped to our artifacts | ROADMAP | `R` |
| `solutions/` | Reusable implementation playbooks | SOLUTION | `S` |
| `okrs/` | Objectives mirrored from a board, per cycle | OKR | — |

## ID format

Every artifact ID is `${PREFIX}${KIND_LETTER}-NNNN`.

- `PREFIX` — lives in `PROJECT` (single source of truth). Example: `P`.
- `KIND_LETTER` — `T` / `F` / `D` / `I` / `R` / `S`.
- `NNNN` — zero-padded 4-digit sequential number, tracked in a single counter
  file (`active-work.md`) so two people never grab the same number.

Example with `PREFIX=P`: first task is `PT-0001`, first investigation `PI-0001`.

## Flow

```
Roadmap (R) → informs → Investigation (I) → Decision (D) → Feature (F) → Task (T)
```

Upstream sets direction; downstream executes. Every artifact links to its
sources. Not every artifact needs the full chain — a quick fix is just a task.

See `GUIDE.md` for the full working method.
