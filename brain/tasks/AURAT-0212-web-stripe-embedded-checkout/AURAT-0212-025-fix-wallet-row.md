# AURAT-0212-025 — Fix: вечный скелетон кошельков (проверка владельца на web-dev)

Date: 2026-11-13. Slave `slave-1`, ветка `feature/AURAT-0212-web-stripe-embedded-checkout` (после мёржа `9cf617d`).

## Что увидел владелец

На web-dev в шторке Book вечные скелетоны. В консоли:
- `IntegrationError: options.layout.overflow: 'never' is only supported when options.layout.maxRows is 0`
  — из фрейма `ExpressCheckoutElement`;
- `Unhandled terms Element loaderror … You cannot use the Terms Element without being gated into this functionality`;
- `payment method types are not activated: link` — предупреждение тестового режима;
- `postMessage … m.stripe.network` и `[Violation] Forced reflow` — шум Stripe, не наш.

## Причина

`WALLET_OPTIONS.layout = { maxRows: 1, overflow: 'never' }` — Stripe принимает `'never'` только при
`maxRows: 0`. Ошибка бросается внутри фрейма: не приходят ни `ready`, ни `loaderror`. Поэтому
`wallets` остаётся `null`, и шторка вечно рисует контур ряда и кнопки. Юнит-тесты это не ловили:
`ExpressCheckoutElement` в них замокан.

## Исправление

- `layout.overflow: 'auto'` (одна строка, до трёх колонок; браузер показывает не больше двух из
  Apple Pay / Google Pay / Link — «More» не появится).
- `WALLETS_WAIT_MS = 8 000` (`config/pay.ts`) и таймер в `use-card-checkout.ts`. Если ряд кошельков
  молчит, это «нет кошельков»: открывается коралловая «Pay …», контур не висит.
- `TermsElement onLoadError` — тихо. Элемент — превью Stripe, аккаунт к нему не допущен. На
  sandbox согласие не спрашивается (`STRIPE_TERMS_CONSENT`), так что ничего не теряется.
- Тест «the wallet row never answers» в `psp.test.tsx` (флаг мока `walletsSilent`).

Прогон: lint, typecheck чистые; 117 файлов / 1970 тестов; build ок (`card-elements` 17,5 kB).

## Merge

Владелец в этой вкладке на вопрос о мёрже фикса: «Да, мёрж».
- Брейн манора: `fetch` + `merge --ff-only origin/master` — уже актуален.
- `./bin/wts-finish slave-1` → `9cf617d..6e811b2 develop -> develop`; idle-слоты 2–5 обновлены; slave-1
  остаётся на ветке.
- Координатор посмотрел `b339656`: таймер ожидания кошельков сделан правильно, замечаний нет.

## Открыто

- **Terms для live** (решение владельца через координатора): владелец просит у Stripe доступ к
  Terms Element, обращение готовит координатор. `TermsElement` и тихий `onLoadError` остаются как
  есть. Если Stripe откажет, будет отдельная задача к воротам live: своё согласие на вебе и в BFF.
  Пункт добавлен в ворота live (`AURAD-0023`, `AURAF-0009` п. 7).
- **Кошельки в sandbox** (координатор проверил через API):
  - `link` — `on`; предупреждение в консоли относится только к тестовому режиму;
  - `google_pay` был `off`; владелец включил его в sandbox, по API координатора теперь `on` и
    available (Apple Pay и Link тоже `on`).

## Добавлено в проверку в маноре (к списку `024`)

- Google Pay в Chrome на Android: кнопка в ряду кошельков, оплата до Booked без ухода со страницы.
- Банк: уход и возврат на `/checkout`. В sandbox включён Bancontact (iDEAL выключен). Нужен
  покупатель из Бельгии (EUR по Adaptive Pricing). Задать его можно одним из двух способов:
  - **Stripe.js testing assistant**: значок внизу справа (только sandbox) → вкладка Elements
    inspector → место покупателя BE;
  - **email профиля** `test+location_BE@example.com`: BFF передаёт его в `customer_email`, и
    сессия создаётся для Бельгии.

  Затем на шаге оплаты — Bancontact, после банка — возврат на `/checkout?payment=…` и Booked.
  Не годится: ввод такого адреса в поле email Stripe. Место задаётся при создании сессии. EUR в
  выборе валюты есть, только если покупатель в стране с евро.
