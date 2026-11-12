# AURAT-0212-009 — Execute: правки ревью (`008`)

Date: 2026-11-12

1. **`features/pay/model/use-card-form.ts` (новый, 229 строк)** — вся жизнь встроенной формы:
   - открытие по ответу старта, таймер истечения, `stripeFor` и загрузка;
   - конец формы: `onComplete` / «←» / истечение → `settleTopUp` в шторке; запись попытки
     стирается при любом исходе, кроме `unknown` и `aborted`;
   - отказ Stripe.js и размонтирование → `closeBehind`.
   - Функции создаются один раз (ленивый `useState`) и читают текущие `provider` / `balance` /
     события через ref, поэтому `onComplete` и `back` стабильны.
   - Наружу — `form`, `open`, `back`, `isOpen`, `reset`.

   `use-pay.ts`: 532 → 376 строк. Он открывает форму (`card.open`, фаза `form`) и получает исход в
   свой `finish` (`onSettled`; `expired` + `cancelled` → `error.expired`). `pageshow` из bfcache
   смотрит `leftForCard || card.isOpen()` и сбрасывает форму `card.reset()`. `CardFormView`
   переехал в `use-card-form.ts`.
2. **`sheet.module.css`**: `--sheet-pad-top: 10px` на `.dialog` (телефон); `.dialog` и `.fill` берут
   отступ из переменной.
3. **Мелочи.**
   - `idle` / `latest` ушли из `use-pay.ts` вместе с формой; заглушка в новом хуке не нужна.
   - В `card-form.tsx` `cx` оставлен — без него не проходит typecheck. При
     `exactOptionalPropertyTypes` CSS Module даёт `string | undefined`, а у `EmbeddedCheckout`
     `className?: string`. `cx` и есть способ проекта (`shared/lib/cx.ts`: «CSS Module lookups can
     be undefined»); рядом комментарий.
4. **Контракты** — отдельным коммитом (ниже).

Прогон:
- `npm run lint` и `npm run typecheck` — чисто;
- `npm test` — 115 файлов / 1960 тестов зелёные; `psp.test.tsx` в этом раунде не менялся;
- `npm run build` — ок, `card-form` — отдельный чанк, маркера фейка нет.
