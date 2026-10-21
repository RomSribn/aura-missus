# AURAT-0111-007 — Часть A: `aura-contracts` v0.23.0 выпущен

Дата: 2026-10-20

- `src/session.ts` (только аддитивно): `SessionResponse = {session: Session}` — ответ
  `GET /v1/sessions/:sessionId`; комментарии `BookSessionRequest` (повтор — исходная сессия до
  проверок, тело не сравнивается, смена правила — только вместе с клиентами) и
  `ExtendSessionRequest` (повтор до проверок и после конца сессии; другие `minutes` или ключ
  брони → 409).
- `src/chat.ts`: `EnsureConversationResponse` — `PUT` вместо `POST`.
- `README.md` — абзац `v0.23.0`, в таблице `session` += `SessionResponse`, `AURAF-0020`;
  `package.json` → `0.23.0`.
- typecheck + build зелёные. Коммит `65183ff` «Сессия по id на проводе (v0.23.0)» в `main`,
  аннотированный тег `v0.23.0`; `main` и тег запушены в origin с подтверждения владельца
  (AskUserQuestion, 2026-10-20).
- Веб (`AURAT-0110`) может ставить `@aura/contracts#v0.23.0`.

Дальше — часть B (BFF).
