# PD-0001 — Contact lists are soft-deleted, never hard-deleted

Date: 2026-01-12
Status: accepted

## Decision

Deleting a contact list sets `deleted_at` and hides it from all reads. Rows are
never physically removed. Members stay attached for audit and possible restore.

## How it works

- `contact_list.deleted_at timestamptz null` — null = active.
- All list queries filter `deleted_at is null`.
- A restore endpoint clears `deleted_at`.
- A background purge may hard-delete rows older than a retention window (future).

## Why

- Accidental deletes are recoverable.
- Message/billing history that references a list stays interpretable.
- Cheap: one nullable column + a read filter.

Informed by `PI-0001`. Implemented by `PF-0001` / `PT-0001`.
