# AURAT-0098-005 — Часть A: `aura-contracts` v0.22.0 выпущен

Дата: 2026-10-18

- `src/chat.ts` (только аддитивно): `WsServerEvent` += `message.deleted`
  `{advisorId, messageId}`; `HistoryQuery` += `deletedFrom?: string`;
  `HistoryResponse` += `deletedIds: string[]` (`.default([])`). `Message` и
  `MessagePushData` не тронуты.
- `README.md` — абзац `v0.22.0`, в таблице модулей `chat` + `AURAF-0018`;
  `package.json` → `0.22.0`.
- typecheck + build зелёные. Коммит `003040a` «Удаление сообщения на проводе
  (v0.22.0)» в `main`, аннотированный тег `v0.22.0`; `main` и тег запушены в
  origin с подтверждения владельца (AskUserQuestion, 2026-10-18).
- App-задача `AURAT-0097` (slave-0 `aura-app-manor`) может ставить
  `@aura/contracts#v0.22.0`.

Дальше — часть B (BFF).
