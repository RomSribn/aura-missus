# AURAT-0208-004 — Context

Date: 2026-11-11. Код — `develop` `84d4b33` (факты шага 001 перепроверены).

## Код веба

- Порт — `src/features/pay/model/top-up-provider.ts`: `startCard`, `payWithWallet`, `status`;
  `useTopUpProvider` отдаёт фейк при `PSP_ENABLED`, иначе `null`.
- `PSP_ENABLED = import.meta.env.DEV && VITE_PSP_ENABLED === 'true'` — `src/shared/config/env.ts:117`,
  реэкспорт через `shared/config/payments.ts` (его мокает `psp.test.tsx`).
- Потребители флага: `app/router/router.tsx:65` (ленивый `/psp-sandbox`), `use-pay.ts:164` (план),
  `pay-actions.tsx:59` (тестовая шторка кошелька), `top-up-provider.ts`.
- `use-pay.ts`: `payByCard` сохраняет `PendingPayment` в `sessionStorage` до ухода, затем
  `loadPage(url)`; `payByWallet` — фейковая шторка; `pageshow` с `persisted` сбрасывает шторку в
  `idle` (`AURAF-0020-041`).
- `use-payment-return.ts` и `settle-top-up.ts`: опрос раз в 2 с до 60 с, «Still confirming…» через
  10 с, `processing` после окна, `credited` → бронь с баланса тем же ключом; `declined` → шторка с
  «Your payment didn't go through», `cancelled` → шторка молча.
- `lib/top-up-plan.ts` — порт `payPlan` приложения: недостача вверх до целого доллара, остаток < $1.
- `/checkout?payment=` — `shared/config/routes.ts:146–156` (`CheckoutSearch`); `cancelled` в нём нет.
- `entities/wallet/api/wallet-api.ts` — `getWallet` (тег `Wallet`) и `topUpWallet` (заглушка BFF
  `POST /v1/wallet/top-ups`, ею «зачисляет» фейк).
- Строки — `features/pay/config/locales/*.ts` (24 языка): `topUp.card`, `topUp.wallet`, `topUp.note`
  «Card payments open our payment partner's secure page».
- Деплой: `VITE_PSP_ENABLED` — `Dockerfile:39`, проверка значения — `deploy/web/build.sh:34`.
  `.env.development` — `false`, `.env.development.local` — `true` (в слоте).

## Контракты

- Веб на `v0.29.0`. Между ним и `v0.31.0` — сезонные тексты на языке запроса (`copyLanguage`,
  `labelLanguage`), перевод чата (`Message.translation`, `message.translated`), язык слогана и био:
  9 файлов, +316. При подъёме — сверить typecheck и разбор WS-событий веба.
- `v0.32.0` ещё не протегирован: в `aura-contracts` ветка `feature/v0.32.0-card-top-up` с
  незакоммиченными `README.md` / `package.json`; `src/card-top-up.ts` есть. Сверено с ним (не финал):
  `CardTopUpRequest { paymentId: uuid, amountMinor: int > 0, returnPath: '/'…, ≤ 512 }`,
  `CardTopUpResponse { redirectUrl: url }`, `CardTopUpStatus` — те же 4 значения, что `TopUpStatus`
  веба, `CardTopUpStatusResponse { paymentId, status, amountMinor, balanceMinor }`,
  `CARD_TOP_UP_MIN_USD = 5`, `CARD_TOP_UP_MAX_USD = 120`, коды `card_top_up_amount_invalid`,
  `card_top_up_return_path_invalid`, `card_top_up_payment_conflict`.

## BFF — `AURAT-0207-007-spec-v2` (одобрена)

- `POST /v1/wallet/top-ups/card` → `{ redirectUrl }`; `Origin` должен быть в `WEB_ALLOWED_ORIGINS`;
  `cancel_url` = `returnPath` + `cancelled=1` (через `URL` API); повтор того же `paymentId` — та же
  страница, пока она `open`, иначе 409; Stripe не ответил → 503.
- `GET /v1/wallet/top-ups/card/:paymentId` — `settle` не чаще раза в 5 с; чужой или неизвестный → 404.
- `POST …/:paymentId/cancel` — закрывает открытую сессию, а если уже оплачено — зачисляет; безопасен
  на любом статусе.
- Всё под `BILLING_ENABLED` и `CARD_TOP_UP_ENABLED` (выключен → 404 на `/card*`).
- Срок Checkout Session — 1 час. `locale` — из `?lang=` (`base-query` веба его уже добавляет).

## Что нашлось сверх шага 001

1. **Недостача больше $120.** Правило суммы не даёт пополнить больше `CARD_TOP_UP_MAX_USD` за раз, а
   сессия может стоить больше (ставка × минуты). Нужно решение — спека, решение 5.
2. **Back без bfcache.** Браузер может не восстановить страницу из bfcache, а загрузить шторку
   заново — тогда `pageshow.persisted` ложен, а запись попытки в `sessionStorage` жива. Тот же случай,
   что 041, — спека, решение 6.
3. **Флаг BFF выключен при включённом вебе.** `/card*` → 404; без обработки это «That didn't go
   through». В спеке — отдельный исход «оплата картой здесь недоступна».
4. **Путь кошелька.** При решении 2А у настоящего провайдера нет `payWithWallet`; держать его только
   ради фейка — мёртвый код в продукте (правило 5). В спеке — убрать вместе с кнопкой.
5. `topUpPlan` — порт приложения; новое правило ($5 минимум, $120 потолок) — только веба (у сторов
   своя лестница), заголовок файла это скажет.
