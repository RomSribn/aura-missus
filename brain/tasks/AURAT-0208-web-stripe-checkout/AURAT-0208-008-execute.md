# AURAT-0208-008 — Execute (в слоте; не закоммичено, всё застейджено на ревью)

Date: 2026-11-11. Ветка `feature/AURAT-0208-web-stripe-checkout`, от `develop` `84d4b33`.
Спека — `AURAT-0208-007-spec-v2` (одобрена владельцем, `006`).

## Проверки (в слоте)

- `npm test` — 113 файлов, 1938 тестов, зелёные (плюс новый `card-provider.test.ts`, 4 теста);
  `npm run typecheck`, `npm run lint` (eslint + steiger), `prettier --check` — чисто.
- Прод-сборка через сам `deploy/web/build.sh` с `VITE_PSP_ENABLED=true` **и** `VITE_PSP_FAKE=true` —
  проходит. Маркера фейка `aura.fake-psp` и песочницы в `dist` нет, адаптер карты есть.
- Сборка `--mode development` с `VITE_PSP_FAKE=true` — маркер есть, то есть проверка `build.sh` на
  такой сборке упала бы. Обе стороны проверки доказаны; запасной вариант из спеки (перенос пути
  песочницы в модуль фейка) не понадобился.

## Коммит 1 — `@aura/contracts` `v0.29.0` → `v0.32.0` (отдельно, правило 6)

`package.json`, `package-lock.json` (`34f978b`), плюс то, без чего не проходил typecheck после
`v0.30.0`:

- `entities/season/lib/parse-app-config.ts` — `partOf` принимает схемы с `default`
  (`ZodType<T, ZodTypeDef, unknown>`): `copyLanguage` / `labelLanguage` (по умолчанию `en`);
- фикстуры с `copyLanguage: 'en'` и `labelLanguage: 'en'` — `presets.ts`, `parse-app-config.test.ts`,
  `season.test.tsx`, `offer.test.ts`.

Новые поля `v0.30.0`–`v0.31.0` веб пока **не показывает**: `lang` у сезонных текстов, сумма в языке
текста, `Message.translation`. Это отдельная задача веба по `AURAT-0189` / `AURAT-0195`, ID — в
`aura-app-manor`.

## Коммит 2 — Stripe Checkout

- **Флаг** (решение 1А). `shared/config/env.ts`: `PSP_ENABLED = VITE_PSP_ENABLED === 'true'` — в
  любой сборке; `PSP_FAKE = PSP_ENABLED && DEV && VITE_PSP_FAKE === 'true'`; схема знает
  `VITE_PSP_FAKE`. Реэкспорт — `payments.ts`, `shared/config/index.ts`. `/psp-sandbox` в роутере —
  только при `PSP_FAKE`. `.env.development` (`VITE_PSP_FAKE=false`), `.env.example`. В слоте
  `.env.development.local` (не в git) — `VITE_PSP_FAKE=true`, фейк остаётся как был.
- **`deploy/web/build.sh`**: `VITE_PSP_FAKE` в проверке `true | false`; после `npm run build` —
  `grep 'aura.fake-psp' dist`, нашёл → сборка падает (замечание 1). Ключ описан в
  `features/pay/config/pay.ts`.
- **API** — `features/pay/api/card-top-up-api.ts`: `startCardTopUp` (`POST /v1/wallet/top-ups/card`,
  тело `CardTopUpRequest.parse`), `cardTopUpStatus` (`GET …/:paymentId`), `cancelCardTopUp`
  (`POST …/:paymentId/cancel`). Ответы разбираются схемами; `balanceMinor` статуса и отмены уходит в
  кэш кошелька (`walletBalanceUpdated`).
- **Порт** — `model/top-up-provider.ts`: `startCard → { redirectUrl } | null` (null — карта на BFF
  выключена), `status`, новый `cancel`; `payWithWallet` удалён. `useTopUpProvider`: `PSP_FAKE` → фейк,
  `PSP_ENABLED` → `createCardProvider`, иначе `null`.
- **Адаптер** — `model/card-provider.ts`: 404 старта → `null`; ошибка статуса или отмены (404 тоже) —
  «ещё не ответ», не `declined` (замечание 2); окно 60 с кончается `processing`.
- **Фейк** — `fake-provider.ts`: без кошелька, `cancel` (открытая → `cancelled`, решённая — как
  есть). `/psp-sandbox` «Cancel and go back» возвращает на путь возврата с `cancelled=1` (как
  `cancel_url`), отмену решает уже сайт.
- **Кошелёк убран** (решение 2А): `fake-wallet-prompt.ts`, `ui/test-wallet.tsx`,
  `config/test-wallet.ts`, `lib/wallet-brand.ts` с тестом, `WALLET_NAMES`, `PaymentMethodId 'wallet'`,
  `payByWallet` / `walletPrompt` / `wallet` в `PayView`, CSS `.buttons` / `.test*`, строка
  `topUp.wallet` (24 языка).
- **Сумма** — `lib/top-up-plan.ts`: не меньше `CARD_TOP_UP_MIN_USD` (`raisedToMin`), больше
  `CARD_TOP_UP_MAX_USD` — `overMax`. Константы — из контрактов. Заголовок порта: правило карты —
  только веба.
- **Шторка** — `use-pay.ts`, `pay-actions.tsx`: одна кнопка «Pay $X»; строка плана `topUp.planMin`,
  когда поднято до $5; `overCardMax` → строка `topUp.tooMuch` без кнопки (5А); 404 старта →
  нынешняя строка «Top up in the Aura app», запись попытки стёрта.
- **Отмена** — `CheckoutSearch.cancelled` (`cancelled=1`) в `shared/config/routes.ts`;
  `use-checkout-page` → `usePaymentReturn({ cancelled })` → `settleTopUp(…, { cancelled })`: первым
  делом `provider.cancel`, дальше его ответ как статус.
- **Back (041, 6А)** — `use-pay.ts`: шторка открылась (загружена заново) или вернулась из bfcache, а
  запись попытки для этого советника жива (`pending-store.pendingFor`) → `replacePage(
  /checkout?payment=…&cancelled=1)` — новая `shared/lib/browser/page-load.replacePage`
  (`location.replace`).
- **Строки** `pay`, 24 языка: `topUp.note` — «Opens Stripe's secure page — you may be charged in your
  local currency» (3, вариант 1); новые `topUp.planMin`, `topUp.tooMuch` (сначала «сессия короче»,
  приложение вторым — замечание 3); `topUp.wallet` удалён. Обращение «ты / вы» — как в остальных
  строках каждого языка.

## Тесты

- `app/__tests__/psp.test.tsx` — переписан. Работает настоящий адаптер против мока BFF (маршруты
  `/card*`) — строже, чем мок провайдера из спеки. 23 теста: одна кнопка без кошелька; $5 минимум;
  больше $120; старт → Stripe → `/checkout` → Booked (тело старта, `returnPath`); `declined`; три
  случая отмены (молча в шторку; оплачено — Booked; отмена без ответа — ждём статус); Back из bfcache;
  Back с перезагрузкой (деньги ушли — Booked); старт, не дошедший до Stripe, Back не трогает; 404
  старта; 503 старта; занято после зачисления; повтор брони тем же ключом; перезагрузка `/checkout`;
  чужой `paymentId`; «Still confirming…»; `processing`; **404 статуса → `processing`, а не «Nothing
  was charged»**; «Now» ×2.
- `app/__tests__/psp-fake.test.tsx` — бывший `psp.test.tsx`, только фейк: успех, 3DS-отказ, отмена
  через `cancelled=1`, `processing`.
- `card-provider.test.ts` (новый), `fake-provider.test.ts` (+ `cancel`), `top-up-plan.test.ts` (+ 4
  про $5 / $120 / долг), `routes.test.ts` (`cancelled=1`), `env.test.ts` (`VITE_PSP_FAKE`).

## Отступления от спеки v2

1. Эндпоинты — в `features/pay/api`, а не в `entities/wallet/api`: в сущности
   `walletBalanceUpdated` ссылался бы на тип `walletApi` из его же определения. Так же устроены
   `extend-session` и `redeem-promo-code`. Других потребителей у эндпоинтов нет.
2. «Карта выключена» (404 старта) помнится, пока открыта шторка, а не до перезагрузки. Повторное
   открытие шторки снова предложит карту; нажатие опять покажет строку — ничего не списано.
3. Back ведёт на `/checkout` полной загрузкой (`location.replace`), а не через `navigate`: при
   открытии шторка сама переписывает URL (`?book=1&slot=`) и перебивала переход, тест это поймал.
4. Отдельного теста «`PSP_FAKE` ложен при `PROD`» нет — константа сборки в Vitest не переключается.
   Вместо него — две настоящие сборки выше.

## Открыто

- `.claude/aura-web-build-rules.md`, раздел «Payments» — ещё про фейк и «off until a PSP is chosen».
  Предлагаю переписать под `AURAD-0023` (Stripe, флаг, фейк только в dev, без кнопки кошелька) — это
  файл воркспейса, не репо; правлю только после «да» владельца.
- `AURAF-0020` (037, 038, 040, 041 → UI ✓; 039 — дело BFF) и `AURAD-0023` правит `aura-app-manor` —
  передам после мёржа.
- Проверка в маноре — после выката `AURAT-0207` на bff-dev (`CARD_TOP_UP_ENABLED=true`, sandbox).
  Coolify: web-dev `VITE_PSP_ENABLED=true` — тогда же; прод — `false` до ворот live `AURAD-0023`.
  `VITE_PSP_FAKE` в Coolify не задаётся нигде.
- В маноре `.env.development.local` с `VITE_PSP_ENABLED=true` без `VITE_PSP_FAKE` после мёржа ведёт
  в настоящий sandbox через bff-dev. Для фейка — `VITE_PSP_FAKE=true`.
