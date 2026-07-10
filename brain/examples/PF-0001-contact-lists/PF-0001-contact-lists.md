# PF-0001 — Contact lists
Type: product
Status: in-progress
Priority: P1
Source spec: none

## What

Users can group contacts into named lists and manage list membership, so they
can later send a message to a whole list at once.

## Scope

| # | Src | Own | App | UI | BE | Del | Item |
|---|-----|-----|-----|----|----|-----|------|
| PF-0001-001 | spec | ✓ | ✓ | ✓ | ✓ |   | Create a named contact list |
| PF-0001-002 | spec | ✓ | ✓ | ✓ | ✓ |   | Rename a list |
| PF-0001-003 | spec | ✓ | ✓ | ✓ | ✓ |   | Add / remove contacts in a list |
| PF-0001-004 | spec | ✓ | ✓ | ✓ | ✗ |   | Delete a list (soft-delete per PD-0001) |
| PF-0001-005 | me   | — | ✓ | ✗ | ✗ |   | Restore a deleted list |

## NOT in scope

- Sending to a list (separate feature).
- Importing contacts from CSV (later).

## Context

- Storage is relational: `contact_list` + `contact_list_member` (per `PI-0001`).
- Delete semantics fixed by `PD-0001` (soft-delete).
- First build tracked in `PT-0001`.
