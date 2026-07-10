# PT-0001-003 — Context

Date: 2026-01-15

## Touched areas
- Backend `contact` module: new `contact_list`, `contact_list_member` tables +
  repository, service, REST controller.
- Frontend: new Lists page + list-detail drawer; reuse existing contact picker.

## Constraints
- Soft-delete only (`PD-0001`): add `deleted_at`, filter all reads.
- `contact_list_member` is a join table (list_id, contact_id), unique pair.
- A user only sees their own lists (scope by owner id).

## Unknowns
- Max members per list? Assume unbounded for now; revisit if perf bites.
