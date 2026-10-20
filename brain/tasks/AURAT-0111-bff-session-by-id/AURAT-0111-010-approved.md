# AURAT-0111-010 — Approved

Дата: 2026-10-20. Владелец принял задачу после проверки в маноре (AskUserQuestion «Verify»).
Status: **done**.

Итог:
- `aura-contracts` `v0.23.0` (`65183ff`): `SessionResponse`, правило повтора `AURAT-0109` у
  брони (тело не сравнивается) и продления (другие `minutes` → 409), `PUT` у
  `EnsureConversationResponse`.
- BFF: `GET /v1/sessions/:sessionId` — `ab7c279` → `develop` @ `7625b44`; `bff-dev` — через
  Coolify с этим push.
- `AURAF-0020`: строки 024 и 026 — BE ✓.

Для `aura-app-manor`: тег `v0.23.0` готов для `AURAT-0110` (подъём — отдельным коммитом в
вебе); приложению подъём не обязателен.
