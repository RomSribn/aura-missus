# AURAT-0114-002 — Check

Date: 2026-10-20 · slave-4 · `feature/AURAT-0114-web-live-session` (master от develop `d4e6772`, missus от `1021e69`)

## Старт (бриф владельца, 2026-10-20)

Задача выдана в `aura-app-manor`; новых ID здесь не создавать. Условие старта выполнено:
`AURAT-0110` влита в develop `d4e6772` — сокет в `app/session/use-live-socket.ts`,
`session.updated` → `sessionUpdated` в `entities/session`, там же `getSessions` / `useSessions`
(тег `Session`, `LIST`) и `useSessionClock`. `getSession` пока берётся из списка:
`GET /v1/sessions/:id` (`AURAT-0111`) в BFF не смержен — на него не опираться.

BFF (`bff-dev` = develop `4277664`), ответы продления: тот же ключ — исходный результат,
другие минуты — 409 (`AURAT-0109`); наезд на следующую сессию человека у другого советника —
409 «You already have a session covering that time» (`AURAT-0113`); наезд на следующую бронь
советника — 409 «Extending would run into the advisor’s next booking»; блок кончился — 409
«Session is not active»; нехватка — 402. Приложение на любой 409 молча закрывает шторку и
перечитывает сессию — что показывать в вебе, решить в спеке.

Параллельно: `AURAT-0108` (slave-1, порт `features/pay` — путь 402 с флагом PSP зависит от её
merge), `AURAT-0112` (slave-3, главная — что она показывает во время сессии, согласовать).
Тест `advisors.test.tsx` «next 4 slots» падает после ~21:00 и на develop — чинит `AURAT-0108`,
не трогать. В slave-4 положен `.env.local` (ключи Firebase Web App, не в git).

## Найдено

- Папка задачи: только `001-initial.md` (заглушка из `aura-app-manor`). Свежая задача.
- Смежные шаги лежат в незакоммиченных missus слотов: `AURAT-0110` (slave-2, до `008-merge`),
  `AURAT-0108` (slave-1, `008-fix-review`), `AURAT-0112` (slave-3, `008-sync-0110`) — читать оттуда.
- `origin/master` missus впереди на `4a630d2` (спека `AURAT-0113`); локальный `1021e69` ещё не в
  origin — сольются при `wts-release`. Читать `AURAT-0113` через `git show origin/master:…`.

Дальше: understand.
