# AURAT-0104-002 — Check

Date: 2026-10-20
Slave: slave-1, branch `feature/AURAT-0104-web-auth` (master from `develop` @ `9443576`,
missus from `5dc3288` — the local stub commit, not on origin yet).

- Task folder exists with the stub `001-initial.md` only (minted in `aura-app-manor`). Fresh
  work, nothing executed.
- Foundation `AURAT-0101` done (`016-approved`): `shared/api/firebase.ts`, `dialog` slice with
  the `auth` kind, GuestGate. Catalog/profile `AURAT-0103` done (`013-approved`): guest CTAs are
  deep links (`?book=1&slot=`, `/chats/:advisorId`), Back closes the open dialog.
- BFF access `AURAT-0102` (CORS, guest reads) — done in `aura-bff-manor`.
- Feature: `AURAF-0020`, rows 003 (phone sign-in) and 004 (gate with resume), UI column.

Next: understand (003).
