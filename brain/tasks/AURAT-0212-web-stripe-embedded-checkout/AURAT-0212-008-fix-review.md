# AURAT-0212-008 — Fix: ревью координатора

Date: 2026-11-12

Ревью кода (координатор «Анализ платёжек для aura-web», `aura-app-manor`): по логике код принят —
поток формы, стирание записи (и после `unknown`), стабильный `onComplete`, «←», ×, Back, истечение,
отказ Stripe.js, `forgetPending(paymentId)`, CSP / Permissions-Policy, строки, FSD. Его прогон: 8
файлов / 76 тестов, typecheck, lint — чисто. Владелец, дословно: «передай, остальное по
рекомендации».

До мёржа:

1. Жизнь встроенной формы — из `use-pay.ts` (532 строки, 11 `useRef`) в отдельный хук
   `features/pay/model/use-card-form.ts`: `openForm`, таймер истечения, `stripeFor` и загрузка,
   `showForm` / `takeForm` / `settleHere`, стабильные `onComplete` / `backFromForm`, `closeBehind`
   при размонтировании. `usePay` открывает форму по ответу старта и получает исход в свой `finish`.
   Поведение то же: `psp.test.tsx` без правок по смыслу.
2. `10px` в `shared/ui/sheet/sheet.module.css` дважды (`.dialog`, `.fill`) — одна переменная модуля
   `--sheet-pad-top`.
3. `const idle = () => undefined` → `noop`; в `card-form.tsx` — `styles.form` без `cx`.
4. `@aura/contracts` `v0.32.0` → `v0.33.0` — отдельным коммитом (правило 6).

Проверка в маноре — поправки:
- повтор старта тем же `paymentId` под `rk_test_` снят с проверки веба (веб на каждое нажатие —
  новый `paymentId`; дело BFF);
- iDEAL и Bancontact в sandbox выключены (только `card`, `link`); уход к банку — только если
  владелец их включит (Settings → Payment methods).

Дальше — правки, прогон, коммиты, вопрос владельцу о мёрже в этой вкладке.
