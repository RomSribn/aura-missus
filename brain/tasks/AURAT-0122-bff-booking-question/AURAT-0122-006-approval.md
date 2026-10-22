# AURAT-0122-006 — Approval

Date: 2026-10-22
Статус: **одобрено** с правками — внесены в 005 до кода.

Решения 1–3 — все «да» (пустое = нет вопроса; вопрос в заметках `booked` и `started`;
`question` в `Session`).

Правки владельца (по ревью спеки):
1. OpenAPI: `question` в `bookSessionRequestOpenApi` (`string`, `maxLength 250`,
   необязательное) и в `sessionOpenApi` (`nullable`) — `src/contracts/openapi.ts`.
2. `Session.question` — `z.string().nullable().default(null)`: поле ответа необязательно на
   проводе (прецедент README contracts — `sessionInvite` v0.14.0, `reviews` v0.15.0,
   `firstSessionOffer` v0.21.0), клиент на `v0.24.0` разбирает ответы BFF без 0122.
3. Тесты trim / `""` / пробелы / 250 / 251 — в спеках BFF разбором
   `bookSessionRequestSchema`; там же — текст ошибки без значения. В `aura-contracts`
   тест-раннера нет.
4. §2: заметки с вопросом в Chatwoot уходят вместе с контактом при удалении аккаунта
   (`AURAT-0042`).

Из ревью без отдельного слова владельца, внесено в §6.4: вебу форма поля — путём к 005 в
слоте BFF (brain слота уйдёт в origin только с `wts-finish`).

Next: 007-execute — сначала ветка `aura-contracts` (`v0.24.0`), push тега — только с
разрешения владельца.
