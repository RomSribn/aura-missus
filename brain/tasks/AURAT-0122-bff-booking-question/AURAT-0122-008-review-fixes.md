# AURAT-0122-008 — Review fixes

Date: 2026-10-22
Ревью владельца 007: «ок, с правками».

## `aura-contracts` — выпущено (с разрешения владельца)
- `474c5cb` «Вопрос советнику на проводе (v0.24.0)» — fast-forward в `main`, аннотированный
  тег `v0.24.0` (`20fb4d0`), push `main` и тега. Ветка удалена.

## Правки BFF
1. **Упоминания в заметке.** `chatwoot.client.ts` `createPrivateNote`: каждая ссылка
   `mention://` в содержимом обезврежена (`defuseMentions` — нулевой ширины пробел после
   `mention:`, регистр не важен); своё упоминание назначенного адаптер пишет после — оно
   живое. Тест: вопрос с `(mention://user/1/…)` и `(MENTION://team/2/…)` — живое только
   `user/12`.
2. **Переводы строк.** `withQuestion` режет по `/\r\n|\r|\n/`. Тесты на `\r\n` и одиночный `\r`.
3. **OpenAPI.** Откат четырёх посторонних переформатирований (tarot `keywords`, review
   `authorName`, wallet `obfuscatedAccountId`, profile `marketingOptIn`) — в диффе только
   `question`. Prettier на `openapi.ts` по-прежнему ругается — так и на `develop`.
4. **`apple-refund.service.spec.ts`** — не флак: `sweep()` читает часы позже `before`.
   Теперь `since` ∈ [`before − 30 дн`, `after − 30 дн`], `after` — после `sweep()`.
   Отдельный коммит.
5. **Зависимость.** `npm install @aura/contracts@github:RomSribn/aura-contracts#v0.24.0` —
   `package.json` и `package-lock.json` (`474c5cb`) в коммите с кодом.

## Проверки
`typecheck`, `lint`, `build` — ок; `jest` — 121/121 наборов, 1643 теста.

## Коммиты в слоте (`feature/AURAT-0122-bff-booking-question`)
- `930e9ef` — тест окна возвратов Apple.
- `86ad162` — вопрос советнику в брони (AURAT-0122).
Missus — не закоммичен (коммит при закрытии задачи).

Next: merge gate — отдельный вопрос владельцу.
