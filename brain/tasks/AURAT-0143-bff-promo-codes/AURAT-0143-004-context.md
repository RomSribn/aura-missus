# AURAT-0143-004 — Context

Date: 2026-10-27
Код: `aura-bff` `develop` @ `5a960ba`; `@aura/contracts` `v0.24.0` (`main` @ `474c5cb`, чисто).

Кошелёк (`prisma/schema.prisma`, `src/modules/wallet/`):
- `Wallet.balanceMinor` — кэш append-only `LedgerEntry`; каждое движение — `$transaction` +
  `SELECT … FOR UPDATE` строки кошелька; триггер запрещает UPDATE журнала.
- `LedgerEntryType`: `TOPUP`, `SESSION_CHARGE`, `SESSION_REFUND`, `STORE_REFUND`,
  `STORE_REFUND_REVERSAL`; ключ `(walletId, idempotencyKey)`; тип не исправить задним числом.
- Образец «таблица ради глобального unique»: `PlayPurchase` / `ApplePurchase` — строка пишется
  в той же транзакции, что и проводка; `ledgerEntryId @unique`; `creditedMinor` — из нашей
  таблицы, никогда из запроса; повтор своим — `replayed: true`, чужой — 409.
- `WalletController` (`/v1/wallet`) — под `BillingEnabledGuard` (флаг выключен → 404). Отказы с
  кодом: `throw new XException({ code, message })` (так делают отзывы и удаление аккаунта).
- Удаление аккаунта (`AURAT-0042`) кошелёк, журнал и покупки не трогает; строка `users`
  остаётся надгробием — id пользователя для бэкофиса сохраняется.

Бэкофис (`src/modules/backoffice/`, спека `AURAT-0075-005`):
- `@Public()` + `SameOriginGuard` + `BackofficeSessionGuard`, `BackofficeExceptionFilter`;
  `VERSION_NEUTRAL`, `/backoffice/...`; страницы — `views/*.view.ts` через `html\`\`` с
  экранированием; `sendPage` (no-store, noindex), после формы — 303 (`redirectTo`).
- Формы: «строгие» zod-схемы в `http/backoffice.forms.ts` (400 целиком), GET — «мягкие».
- Данные страниц собирает `BackofficePagesService`; действия — в сервисах-владельцах
  (отзывы — `ReviewModerationModule`). Вкладки — `Section` в `layout.view.ts`.
- Оператор: `{ id, login }`; действия отзывов пишут `operatorId`.

Логи: `http-logger.options.ts` — тела запросов и ответов не пишутся, URL пишется целиком →
код только в теле. `ZodValidationPipe` отдаёт сообщения issues — значение не эхается.
Лимиты: `@fastify/rate-limit` 120/мин на IP глобально; Redis-счётчик неудачных входов
бэкофиса (`backoffice-auth.service.ts`, ключ — sha256) — образец для лимита попыток.

Контракты: `ApiError {code, message}`; отказы — `z.enum` snake_case (`AccountDeletionRefusalCode`,
`ReviewRefusalCode`); README — таблица модулей + абзац на версию; выкатка — как
`AURAT-0122-005` §6. OpenAPI-фрагменты руками в `src/contracts/openapi.ts`.

Противоречий между планом манора и кодом нет. Новое относительно плана: нужен отдельный код
отказа на «из этой партии вы уже погашали» (в списке манора из пяти его нет).

Next: 005-spec.
