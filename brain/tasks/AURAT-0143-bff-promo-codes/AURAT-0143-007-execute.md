# AURAT-0143-007 — Execute

Date: 2026-10-28
Слот `slave-1`, ветка `feature/AURAT-0143-promo-codes`. Ничего не закоммичено (ревью владельца).

## `aura-contracts` — `v0.25.0` (ветка `feature/v0.25.0-promo-codes`, не закоммичено, не запушено)

- `src/promo.ts` (новый): `RedeemPromoCodeRequest {code}` (1–64, как набрано),
  `RedeemPromoCodeResponse {entryId, balanceMinor, currency, creditedMinor, replayed}`,
  `PromoCodeRefusalCode` — 6 кодов (§1 спеки); `src/index.ts`, `package.json` 0.25.0,
  README: строка модуля + абзац `v0.25.0`. `typecheck` + `build` — ок.
- В BFF собранный `dist` скопирован в `node_modules/@aura/contracts` для проверки;
  `package.json` BFF ещё на `#v0.24.0` — поднять можно только после push тега (см. ниже).

## `aura-bff`

Модель и миграция:
- `prisma/schema.prisma`: `LedgerEntryType.PROMO_CREDIT`; `PromoBatch` (оператор — id + снимок
  логина, без FK; `creationKey @unique`; `disabledAt/By*`), `PromoCode` (`code @unique`,
  `disabledAt/By*`), `PromoRedemption` (`codeId @unique`, `ledgerEntryId @unique`,
  `@@unique([batchId, walletId])`); связи у `Wallet`, `LedgerEntry`.
- `prisma/migrations/20261027120000_promo_codes/migration.sql` — enum value + 3 таблицы, только
  добавления.

Модуль `src/modules/promo-codes/` (новый):
- `promo-code-format.ts` — алфавит 31 символ (без 0 O 1 I L), генерация `crypto.randomInt`,
  нормализация: NFKC, все `\s` (вкл. NBSP), U+200B–U+200D, U+2060, U+FEFF, любые дефисы/тире,
  верхний регистр; показ `K7QM-9XRT`.
- `promo-codes.policy.ts` — $1…$100, ≤ 500, кампания ≤ 80, 90 / 365 дней, 10 неудач / час.
- `promo-codes.repository.ts` + `prisma-promo-codes.repository.ts` — погашение одной
  транзакцией (код FOR UPDATE → повтор своим / чужой → отключён → истёк → кошелёк FOR UPDATE →
  «из партии уже» → `PROMO_CREDIT` с ключом `promo:<codeId>` → погашение → баланс; unique —
  повтор разбора); создание партии (повтор `creationKey` → та же партия; коллизия кода →
  `PromoCodeCollisionError`); список, сводка, партия с кодами; отключение кода (замок строки)
  и партии (замки в порядке id, только непогашенные).
- `promo-attempts.ts` — Redis-счётчик неудач по sha256(id пользователя), окно 1 час.
- `promo-redemption.service.ts` — лимит → нормализация → погашение; считается только
  `not_found`; лог — id кода/партии и сумма, без кода и пользователя.
- `promo-batch-draft.ts` — разбор формы оператора (`10`, `10,50`, `$10`; дата `ГГГГ-ММ-ДД`,
  не раньше завтра, ≤ 365 дней), ошибки по полям.
- `promo-codes-admin.service.ts` — проверка, создание (до 3 генераций), обзор, отключение.
- `promo-code-status.ts` — статус кода/партии.
- `promo-codes.controller.ts` — `POST /v1/wallet/promo-codes/redeem`, `@HttpCode(200)`,
  `BillingEnabledGuard`, 429 + `Retry-After`.
- `promo-codes.module.ts`; подключён в `app.module.ts`.
- `wallets.repository.ts` — `PROMO_CREDIT` в типе проводок.
- `src/contracts/promo.ts`, `index.ts`, `openapi.ts` — ре-экспорт и OpenAPI-фрагменты.

Бэкофис (`src/modules/backoffice/`):
- `backoffice-promo-codes.controller.ts` (новый) — 8 маршрутов §4, гарды
  `BillingEnabledGuard → SameOriginGuard → сессия`; «Отключить все» без галочки → плашка,
  ничего не отключено.
- `views/promo-codes.view.ts` (новый) — список + сводка, форма, подтверждение
  («50 кодов × $10 = $500», кнопки «Создать» / «Исправить» через `formaction`), партия
  (поле с активными кодами, таблица, галочка `required`), CSV (`promo-codes-<batchId>.csv`,
  защита от формул).
- `layout.view.ts` — вкладка «Промокоды» только при `BILLING_ENABLED`; `format.ts` —
  `formatUsd`, `formatUtcDay`; `backoffice.forms.ts` — схемы; `backoffice-http.ts` —
  `sendCsv`; `backoffice-pages.service.ts` — страницы + флаг вкладки; `backoffice.module.ts`;
  `assets/backoffice.css` — стили форм/панелей.
- `README.md` — дерево модулей, эндпоинт, вкладка.

Тесты (новые): `promo-code-format`, `promo-batch-draft`, `promo-attempts`,
`promo-redemption.service`, `prisma-promo-codes.repository` (форма транзакций на записывающем
Prisma), `promo-codes-admin.service`, `promo-codes.controller` (200 в OpenAPI, 429 +
Retry-After), `contracts/promo`, `views/promo-codes.view`, `backoffice-promo-codes.smoke`
(HTTP: 404 без биллинга, подтверждение без записи, повтор формы — одна партия, 403 с чужого
сайта, галочка, CSV). Правка: `views.spec` (флаг вкладки), `backoffice.smoke` (зависимость).

Проверки: `tsc` ✓, `eslint` ✓, `nest build` ✓, jest — 131 сьют / 1741 тест ✓.

## Решения по ходу

- Сводка «активно сейчас» считается типизированным `groupBy`, а не сырым SQL: в репо нет
  образца сравнения даты в `$queryRaw` через этот драйвер.
- Форма с ошибками возвращается со статусом 422 (страница формы, не страница ошибки).
- Партия: `disabledAt` ставится и когда отключать нечего (статус в списке — «отключена»).

## Открыто / до мёржа

1. **Push `aura-contracts` `v0.25.0`** (merge в `main` + тег) — только с разрешения владельца.
   После — `npm install @aura/contracts@github:RomSribn/aura-contracts#v0.25.0` в BFF (меняет
   `package.json` + lock), иначе `npm ci` / Docker не соберут ветку.
2. Живая проверка в маноре (§7 спеки): миграция на живой базе, замки, гонка двух погашений,
   лимит, лог без кода, страницы в браузере.

Next: ревью владельца → коммит → merge gate.
