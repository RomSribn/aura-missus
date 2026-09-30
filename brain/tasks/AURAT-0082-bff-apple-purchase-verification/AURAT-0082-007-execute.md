# AURAT-0082-007 — Реализация

Дата: 2026-09-30. Слэйв `slave-2`, ничего не закоммичено — всё в stage на ревью.

## Сделано (aura-bff)

- **Зависимости:** `@aura/contracts` → `#v0.20.0`; `@apple/app-store-server-library`
  `^3.1.0` (новых уязвимостей `npm audit --omit=dev` не добавила).
- **Контракт:** `contracts/wallet.ts` ре-экспорт `AppleTopUp{Request,Response}`,
  `contracts/openapi.ts` — их схемы, `wallet.spec.ts` — пин формы v0.20.0.
- **Таблица тиров общая:** `play-tiers.ts` → `top-up-tiers.ts`, `TOP_UP_TIERS`.
- **Конфиг:** `APPLE_IAP_KEY_ID / _ISSUER_ID / _PRIVATE_KEY`, `APPLE_BUNDLE_ID`,
  `APPLE_APP_APPLE_ID` — все пять или ни одного (везде), обязательны в
  production при `BILLING_ENABLED=true`.
- **Адаптер `src/modules/apple/`:** корень Apple Root CA G3 (пин по отпечатку в
  тесте), `AppStoreApi` (два окружения; клиент-подкласс с таймаутом 10 с — у
  библиотеки его нет), `AppStoreTransactionVerifier` (прод → песочница; в проде
  `401/404/4000006` — промах; id только из цифр — библиотека кладёт его в путь
  без кодирования), `AppStoreNotifications` (проверка `signedPayload` и
  вложенной транзакции; история уведомлений для добора), контроллер
  `POST /webhooks/apple`.
- **Деньги (`wallet/`):** `AppleTopUpService` (таблица проверок из `005`),
  `AppleRefundService` (`apply` + `sweep`), 4 метода репозитория под блокировкой
  кошелька; `POST /v1/wallet/top-ups/apple` (200).
- **Схема:** `ApplePurchase` (`apple_purchases`) + `LedgerEntryType.STORE_REFUND_REVERSAL`,
  миграция `20260930120000_apple_purchases` (руками; `migrate diff` требует БД —
  сверка в маноре).
- **Задачи:** очередь `apple-refund` (`notice` / `sweep`), процессор,
  планировщик (раз в час, окно 30 дней, оба окружения, сначала REFUND, потом
  REFUND_REVERSED).
- **Документы:** README (модуль, эндпоинт, вебхук), `.env.example`,
  `deploy/env/bff.env.example`, `TECH-DEBT #33` (ловушка 401 до первой продажи).
  В мозге: `AURAF-0010-008` BE → ✓.

## Проверки в слэйве

`lint` ✓, `typecheck` ✓, `build` ✓, `jest` — 1344/1344 ✓ (новых ~90).
Дымовой прогон без сети: реальный `appStoreApiFromConfig` собирает оба
окружения, токен — `ES256`, `kid=CSNPA77W6Y`, `iss`, `aud=appstoreconnect-v1`,
`bid=cc.silvermind.aura` — ровно форма из `001`.

## Решения по ходу

- Храню окружение как `production` / `sandbox` (наши слова, не Apple'овские).
- `REFUND_REVERSED` раньше своего `REFUND` (push'и без порядка) пропускается —
  добор применит его после возврата в течение часа.
- Непроверяемая (OCSP недоступен) подпись → исключение (500), а не отказ:
  приложение/Apple повторят.

## Открытое / для манора

- Миграцию сверить `prisma migrate diff` на живой БД.
- **Порядок деплоя:** на dev и на прод (там тоже `NODE_ENV=production`, а биллинг
  включён) сервис **не стартует** без пяти `APPLE_*` — их надо прописать **до**
  деплоя этой версии.
- App Store Connect → App Store Server Notifications V2: Sandbox URL → dev,
  Production URL → прод.
- Первый прогон — висящая `aura.topup.usd25` из TestFlight.
