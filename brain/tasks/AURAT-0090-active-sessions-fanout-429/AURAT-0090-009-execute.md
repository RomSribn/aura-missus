# AURAT-0090-009 — Исполнение (часть A)

Дата: 2026-11-20 · slave-1 · `feature/AURAT-0090-active-sessions-fanout-429` (от `develop` `6b429d2`).
Не закоммичено, всё застейджено для ревью.

## A1 — активные сессии одним запросом
- `features/paid-session/model/use-active-sessions.ts`: `fetchSessions()` вместо
  `fetchActiveSession` × N. Хранятся `ACTIVE` из ответа; `live` фильтруется по `advisorIds`.
  In-flight-флаг один на хук (новый тред запроса не порождает). Ошибка, кроме 404, оставляет
  прошлый ответ (блоки всё равно истекают по `endsAt`). Без тредов — не спрашивает.
- Тест `ChatsScreen.session.test.tsx`: `/v1/sessions` с активной, будущей и закрытой; новый тест —
  один `/v1/sessions` на маунт и фокус, ни одного `/sessions/active`.

## A2 — история без дублей
- `features/chat/model/ChatProvider.tsx`:
  - `syncThread` — одно чтение на тред; поводы, пришедшие пока оно идёт, ставят **один**
    повтор в очередь (`followUps`, проверка эпохи);
  - `syncAllThreads` открывает раунд `sweptSinceOpen`. Эффект каталога читает только тех, кого в
    раунде нет, и ничего до первого раунда;
  - `userUid` и `AppState → active` больше не sweep'ят. Sweep — на `onOpen`; запасной таймер
    `SOCKET_OPEN_GRACE_MS` (5 с, `features/chat/config/constants.ts`) читает, только если сокет
    **сейчас не открыт**. `background` сбрасывает раунд и таймер.
- `shared/api/bff/ws-client.ts`: `isOpen` — флаг от `onopen` до `onclose` / `stop`.
- `src/test-support/fake-bff-socket.ts`: фейковый сокет, подключается на `start` (микротаск →
  `onOpen`). Им заменены самописные моки в 7 файлах тестов `ChatProvider.*` и
  `ChatThreadScreen.history`; `foreground()` в `unread` теперь `background → active`.
- Новый `ChatProvider.sync.test.tsx` (7 тестов):
  - холодный старт — 1 чтение на советника;
  - возврат — 1;
  - inactive → active при живом сокете — 0;
  - сокет не открылся — чтение после grace;
  - три пуша во время чтения — 1 + 1;
  - каталог перечитан — читается только новый советник;
  - каталог пришёл после `onOpen` — все.

## A3 — 429 на чтении
- Новый `shared/api/bff/rate-limit-window.ts`: отметка «закрыто до» по 429 **без кода отказа**
  (глобальный лимитер; у 429 промокода код есть, он окно не трогает). `waitsOut` — 429 без кода
  с `Retry-After ≤ 30`.
- `shared/api/bff/http-client.ts`:
  - `bffRequest` разобран на `authorisedAttempt` (ворота для GET + 401-рефреш) и `failureOf`;
    GET после такого 429 ждёт и повторяется один раз;
  - записи не ждут и не повторяются, но их 429 закрывает окно для чтений;
  - `bffPublicRequest` — те же ворота и тот же один повтор.
- 7 тестов в `http-client.test.ts`, тест `isOpen` в `ws-client.test.ts`.

## Решение по ходу
Таймаут теста в jest идёт по подменённым часам (`jest.useFakeTimers()` в `jest.setup.js`), а grace
(5 с) совпадает с таймаутом по умолчанию. В `ChatProvider.sync.test.tsx` стоит
`jest.setTimeout(4 × grace)` с комментарием.

## Проверки
- `tsc --noEmit` ✓;
- `npm run lint` (`--max-warnings 0`) ✓;
- `jest` — 254 набора / 3388 тестов ✓, плюс тест `isOpen`.

Переводов нет: новых строк в интерфейсе нет. Живая проверка — в маноре после мёржа (критерии
спеки: бронь ×10 и возврат ×10, в две отдельные минуты).

## Дальше
Ревью кода манором → «да» владельца на мёрж. Часть B — после A, отдельной парой.
