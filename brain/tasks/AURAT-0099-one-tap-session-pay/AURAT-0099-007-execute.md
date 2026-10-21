# AURAT-0099-007 — Execute

Date: 2026-10-19
Slave: slave-1, `feature/AURAT-0099-one-tap-session-pay` (aura-app, база `cc71ef4`)

Владелец спросил «что насчёт работы по aura-app?» — код начат, не дожидаясь
выкатки BFF: зависимость только в порядке **выпуска** (сборка не уходит в стор
раньше `AURAT-0100` и продуктов в консолях). Без продуктов приложение само
остаётся на старом «Top up to book».

## Что сделано (staged, не закоммичено — ждёт ревью владельца, 6f)

**`features/store-topup` — ядро:**

- `model/store-rail.ts` — одно подключение к стору на процесс (module store):
  `start/stop`, цены по запросу (`ensurePrices`), `buy(sku, onDelivered)` →
  `credited | cancelled | failed | pending`. Порядок «BFF кредитует → потом
  `finishTransaction`», дедуп, подбор брошенных покупок, `trackPurchase` —
  перенесены из старого хука без изменения смысла.
- `model/use-store-rail.ts` — `useStoreRailSync` (монтируется в `app/index.tsx`)
  и `useStoreRail`.
- `model/use-store-topup.ts` — Profile → Top Up теперь читает общее
  подключение; форма ответа прежняя, Profile не менялся по логике.
- `lib/pay-plan.ts` — недостача → продукт `aura.topup.usdN` (округление вверх),
  остаток на баланс; долг на балансе гасится всегда; выше $120 — стор не
  предлагается.
- `model/use-checkout.ts` — выбор способа (баланс по умолчанию, если хватает;
  иначе стор), «Use my balance», цена стора на кнопке, фазы
  (`store → crediting → charging`), исходы (`storeError / slotTaken / ended /
  pending / failed`), откат на Top Up, если стор не продаёт сумму.
- `ui/` — `PayWith`, `PayBreakdown` (+ `RemainderNote`), `PayCompact`,
  `UseBalanceToggle`, `PayNotice`, `CheckoutButton` по `CHECKOUT.md`.
- `config/products.ts` — `LADDER_MAX_USD = 120`, `ladderSku`,
  `STORE_ACCOUNT_LABEL`, `STORE_VENDOR`.

**Фичи, которые платят:**

- `features/booking`: `confirm` → `charge(): Promise<outcome>`; `onTopUp` и
  `needsTopUp` убраны — что платит, решает checkout. `QuickBookSheet` получил
  слоты `payment` / `action` (фича не может импортировать `store-topup`).
- `features/paid-session`: выбор блока поднят в модель (`selectedMinutes`,
  `selectBlock`), `confirm(minutes)` → `charge()`; блоки больше не
  блокируются по балансу; `SessionBlockSheet` — те же слоты. Текст правила:
  «A started block can't be refunded. Unused credit always stays on your balance.»

**Экраны:**

- Review: «Pay with» + разбивка + `PayNotice` + кнопка; строка «Visa ···· 4242»
  удалена; политика — «…refunds go to your Aura balance».
- Booked: строка «$0.15 stays on your balance» (`remainderMinor` в параметрах).
- Чат: Quick book и Extend через `useCheckout`; тосты «Session started · N min» /
  «Added N minutes»; «сессия закончилась, пока платили» — тостом (лист
  закрывается на 409). Пока идёт оплата, лист не закрывается по скриму.
- Profile → Top Up: строка стора с подписью аккаунта вместо голого имени.

## Проверка в слоте

- `npx tsc --noEmit` — чисто; `npm run lint` — чисто.
- `npx jest` — 127 наборов, 918 тестов, все зелёные. Новое: `pay-plan` (10),
  `use-checkout` (16), `checkout-ui` (11, в т.ч. «нигде нет Apple Pay /
  Google Pay»); старые 21 тест стор-пополнения прошли на новом подключении
  без правок, кроме монтирования `useStoreRailSync`.
- В слоте обновлены `node_modules` (`@aura/contracts` 0.21.0 → 0.22.0, как в
  `package.json`); `package*.json` не менялись.

## Не сделано / сознательно

- Анимация появления (`FadeInDown 250ms`) у остатка и сообщения — в проекте нет
  reanimated; появляются без анимации.
- Проверка на устройстве — только после мержа, в маноре (правило слейва), и
  только когда `AURAT-0100` выкачен и продукты заведены.
- Скоуп-таблица `AURAF-0019` не трогалась сейчас: её строку 009 правит сессия
  BFF-манора — отмечу UI при мерже, чтобы не ловить конфликт.

Next: ревью владельца в IDE → коммит → мерж (только с подтверждения).
