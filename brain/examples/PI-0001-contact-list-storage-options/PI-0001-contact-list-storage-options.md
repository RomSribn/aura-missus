# PI-0001 — Contact list storage options

Date: 2026-01-10

## Purpose

Decide how to store user contact lists and their members: one wide table,
two tables (list + member), or a document blob per list. Inform the upcoming
contact-lists feature (`PF-0001`).

## Options considered

| Option | Pros | Cons |
|--------|------|------|
| Single wide table | simplest | members duplicated per list, hard to query |
| List + member tables (relational) | clean queries, dedup, FK integrity | one extra join |
| JSON blob per list | flexible shape | no per-member queries, no integrity |

## Finding

Relational (list + member) wins: members are queried, filtered, and counted
independently; integrity matters; the extra join is trivial at this scale.

## Open question for the decision

Hard-delete vs soft-delete of a list — members and history implications.
→ resolved in `PD-0001`.

## Outcome

Feeds `PD-0001` (delete semantics) and `PF-0001` (the feature).
