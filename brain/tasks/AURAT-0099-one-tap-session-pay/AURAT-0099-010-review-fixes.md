# AURAT-0099-010 — Правки по проверке на устройстве

Дата: 2026-10-19 … 2026-10-21
Проверка: владелец, Galaxy A50, `apk:staging` из слота → bff-dev (с лестницей
`AURAT-0100`, продукты Play — `008`).

## Что попросил владелец и что сделано

1. **Строка «Aura balance» при нехватке — неактивна, но путь в Profile → Top Up
   сохранён** (2026-10-19). Строка серая и не выбирается (`disabled`,
   `selected: false`), справа — ссылка «Top up»: Profile с уже открытым листом
   пополнения, как было до checkout. В листах (Quick book, Extend) — строка
   «Rather add to your balance first? Top up»; без стора — «Balance $X · Top up».
   Новое: `ui/TopUpLink.tsx`, `topUp` в `use-checkout` (только в `idle`).
2. **Разбивка в листах, как на Review** (2026-10-21). `PayCompact` показывает
   карточку `PayBreakdown` («Session · From balance · Google Play» + остаток)
   при выбранном сторе — и в Quick book, и в Extend; голая строка остатка
   остаётся только без карточки (без дубля «stays on your balance»).
   `PayBreakdown` получил `style`.
3. **«End session early» закрывает лист продления** (2026-10-21). После
   подтверждения в диалоге лист закрывается сразу — как после оплаченного
   продления; «Keep going» оставляет его. Это была ошибка и в `develop`
   (`use-paid-session.ts` `endEarly` не трогал `visible`).

## Проверка

- `npx tsc --noEmit`, `npm run lint` — чисто.
- `npx jest` — 127 наборов, **925 тестов**, все зелёные. Новые: неактивная строка
  баланса и `TopUpLink` (`checkout-ui`), `topUp` (`use-checkout`), разбивка в
  листе (`checkout-ui`), закрытие листа после «End session» (`use-paid-session`).
- Владелец на устройстве: «все окей, комить и закрывай задачу» (2026-10-21).
