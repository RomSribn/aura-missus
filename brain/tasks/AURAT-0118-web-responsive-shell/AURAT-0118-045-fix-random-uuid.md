# AURAT-0118-045 — фикс: ключи попытки на http по IP

Дата: 2026-10-22. Slave-2, ветка `feature/AURAT-0118-web-responsive-shell`.

## Что нашёл владелец
После мёржа (`044`) проверка в маноре: кнопка оплаты в шторке Book не реагирует ни на
телефоне, ни на desktop — запроса нет, надпись не меняется, баланса хватает. На
`http://localhost:5173` бронь работает (подтвердил владелец).

## Причина
`crypto.randomUUID()` есть только в защищённом контексте (https / localhost). Dev-сервер,
открытый по IP (`http://192.168.31.114:5173`), — обычный http: `usePay.begin()` падал
с `TypeError` до запроса, `inFlight` оставался `true`. Сервер ни при чём: CORS bff-dev
пускает LAN-origin, слоты и «Now» отдаются (`AURAT-0115` на bff-dev работает). На проде
(https) бага нет. Тесты брони зелёные, в т. ч. под `StrictMode` (проверено отдельно).

## Решение (владелец: «делай с фолбэком на randomUUID»)
- `shared/lib/browser/random-uuid.ts` — `randomUuid()`: `crypto.randomUUID`, где он есть;
  иначе UUID v4 из `crypto.getRandomValues` (биты версии и варианта по RFC 9562).
  Никогда `Math.random` — ключ защищает от двойного списания.
- Переведены все 5 вызовов: `use-pay.ts` (ключ попытки, id карты и кошелька),
  `use-extend-session.ts`, `entities/message/model/chat-sync.ts`.
- Тест `shared/lib/__tests__/random-uuid.test.ts` (4).

Минусы, названные владельцу: своя утилита на ~10 строк; Payment Request и другие
secure-only API по http по IP всё равно не заработают (с настоящим PSP — проверять по https).

## Проверки
typecheck, lint (eslint + steiger) — чисто. Полный vitest: 1342 passed; изредка падают
отдельные тесты и `_location` jsdom под нагрузкой — то же на чистом `develop` в маноре
(1 failed + unhandled error), не связано с правкой.

Коммит aura-web: `e40c400`. Дальше — проверка владельцем с телефона по IP (dev из
slave-2 или после мёржа из манора), затем мёрж по его «да».
