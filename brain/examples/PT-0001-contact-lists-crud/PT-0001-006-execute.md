# PT-0001-006 — Execute

Date: 2026-01-17

Done as specced:
- Migration added both tables + unique member pair + FKs.
- Service implements create/rename/addMember/removeMember/softDelete; all reads
  filter `deleted_at is null` and scope by owner.
- REST endpoints wired; delete is soft.
- Frontend Lists page + detail drawer; delete uses the shared confirm dialog
  (per approval note), not a popconfirm.
- Tests green: service CRUD + soft-delete-hides-list + one API happy path.

Deviation: none on backend. Restore (PF-0001-005) left out as planned.

Build, lint, tests pass. Ready for review.
