# AURAT-0092-004 — context

- `SessionsService.enqueueDeskNote` → задача `desk-note` → `postDeskNote` →
  `ChatwootMessagingPort.postPrivateNote(..., { mentionAssignee })`. Текст (`deskNote`)
  собирается в `sessions.service.ts` — рендер под Chatwoot живёт в сервисе.
- Стиль портов в репо: `abstract class` как DI-токен (`ChatwootMessagingPort`,
  `ObjectStorage`, `AppStoreApi`); опциональные интеграции — `useFactory`, возвращающий
  `null`, когда конфиг не задан (`apple.module.ts`, `storage.module.ts`).
- Конфиг: zod `env.schema.ts`, группы «всё или ничего» через `superRefine`
  (`requireBucket`). HTTP — нативный `fetch` (`chatwoot.client.ts`).
- Ссылка на диалог в деске: публичный origin есть (`AGENT_DESK_FRAME_ANCESTOR`,
  `https://chat.aura-app.cc`), `CHATWOOT_ACCOUNT_ID`, display id диалога — в
  модуле `chatwoot` (`conversations.repository`).
- Правила: Chatwoot запечатан в своём модуле (правило 1), процессоры тонкие (2),
  секреты/PII не утекают (3) — Telegram это внешний сервис, в сообщение не
  попадают номер, UID, имя клиента, тексты переписки.
