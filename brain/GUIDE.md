# How to run a knowledgebase

A practical guide to working with this structure. Read once; then the per-folder
`RULES.md` files are the reference.

## The idea in one paragraph

Capture project knowledge as **small, single-purpose Markdown files** with
**predictable IDs and names**, committed to git. Each file answers one thing.
Categories separate *what the system does* (features), *the work being done*
(tasks), *choices made* (decisions), *what we learned* (investigations), *what's
planned* (roadmaps), *reusable patterns* (solutions), and *what we're measured
on* (okrs). Because names are predictable, both humans and agents can find,
extend, and cross-link without a search engine.

## Two kinds of artifact: living vs history

This distinction decides whether you **edit** a file or **add a new one**.

- **Living** — always reflects the *current* state. Edit in place.
  → `features/`, `decisions/`, `solutions/`, `okrs/`.
- **History** — a snapshot of a moment. Never rewritten; superseded by a new one.
  → `tasks/`, `investigations/`, `roadmaps/`.

A feature spec describes how things work *now*. A task describes what happened
*then*. If you find yourself editing a finished task, you actually want a new
task.

## Picking the right category

```
Is it work you are doing right now?            → tasks/         (T)
Is it "how the system behaves" (current truth)? → features/      (F)
Is it a choice to remember/justify?             → decisions/     (D)
Is it research / a deep dive / a comparison?    → investigations/(I)
Is it an external planning snapshot in time?    → roadmaps/      (R)
Is it a reusable pattern for future work?       → solutions/     (S)
Is it a graded objective from a board?          → okrs/
```

When two fit: research → `investigations/`, the resulting choice → `decisions/`,
the lasting pattern → `solutions/`, the execution → `tasks/`.

## IDs and the counter

- ID = `${PREFIX}${KIND}-NNNN`. Set `PREFIX` once in `PROJECT`.
- One global counter file at the workspace root, `active-work.md`, holds the
  **next free number per kind**. Before creating an artifact: bump the counter
  there first, then create the file. This is the whole concurrency story — two
  people/agents never collide because the counter is claimed before the work.
- Quick local check of the last used number in a kind:
  `ls tasks/ | grep '^PT' | sort | tail -1` (swap prefix/kind).

## Naming law (applies everywhere)

1. **Prefix everything.** Files and folders start with their artifact ID. No
   generic names — never `notes.md` floating at the root, never `img.png`. Use
   `PF-0007-notes.md`, `PF-0007-flow.png`.
2. **One artifact = one home.** A task is a folder; a decision is a single file.
   See each `RULES.md` for the shape (folder vs flat file).
3. **Short slug after the ID.** `PT-0012-rate-limit-retry`, not a sentence.
4. **Forward only for history.** Task step files go `001`, `002`, … — never
   renumber or rewrite a committed step.

## The task lifecycle (the part you do most)

A task is a folder `PT-NNNN-slug/` with **short, forward-only step files**. The
canonical sequence — adapt, but keep the order and the approval gate:

| Step | File | Purpose |
|------|------|---------|
| 1 | `PT-NNNN-001-check.md` | What exists already, related artifacts, partial work. |
| 2 | `PT-NNNN-002-understand.md` | Restate the goal in your own words. |
| 3 | `PT-NNNN-003-context.md` | Code/area touched, constraints, unknowns. |
| 4 | `PT-NNNN-004-spec.md` | The plan: concrete steps, files, acceptance. |
| 5 | `PT-NNNN-005-approval.md` | User signs off on the spec before execution. |
| 6 | `PT-NNNN-006-execute.md` | What was actually done; deviations from spec. |
| 7 | `PT-NNNN-007-approved.md` | **Task is done only when this file exists.** |

Rules of thumb:
- Steps are **short** — what was done, what was decided, what's next. Not essays.
- The **approval gate** (`005`) precedes execution; the **done gate** (`007`)
  is created only on the user's final sign-off. No `approved.md` ⇒ not done.
- More steps are fine (`004b`, `008-followup`) as long as numbers go forward.
- See `examples/PT-0001-contact-lists-crud/` for a full worked task.

## Cross-linking

Reference upstream and downstream by ID in prose: "implements `PF-0007`",
"follows `PD-0003`", "supersedes `PI-0012`". IDs are stable, so links survive
renames. An agent or teammate can then walk the chain `R → I → D → F → T`.

## Maintenance routines

- **Feature changed in code?** Edit its `features/PF-*` spec the same PR. The
  spec must never lie about current behavior.
- **Decision reversed?** Set the old one's `Status: superseded`, point to the
  new `PD-*`. Don't delete history.
- **Recurring pattern emerging across tasks?** Lift it into a `solutions/PS-*`
  playbook so the next task reuses instead of re-deriving.
- **OKRs re-exported from the board?** Update grades/status in each objective
  file and the summary index; log the export date.

## Adopting this for a new project

1. Copy this `knowledgebase/` folder into the project (or a private side repo).
2. Put your prefix in `PROJECT` (e.g. `ACME` → IDs like `ACMET-0001`).
3. Create `active-work.md` at the workspace root with a "next free number" line
   per kind.
4. Write `PROJECT-ORIENTATION.md` — the stable mental model newcomers read first.
5. Start capturing. First research → `PI-0001`; first choice → `PD-0001`; first
   build → `PT-0001`.

## Anti-patterns (don't)

- Editing a finished task or investigation to "update" it — make a new one.
- Generic filenames with no ID prefix.
- Letting a feature spec drift out of date — it's the current-truth contract.
- Dumping long research into a decision or solution — that belongs in an
  investigation; link to it.
- Grabbing an ID number without bumping the counter first.
