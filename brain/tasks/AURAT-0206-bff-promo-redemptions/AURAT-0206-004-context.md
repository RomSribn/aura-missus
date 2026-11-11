# AURAT-0206-004 — context

## Ответы владельца (2026-11-11, до спеки)

1. Что показывать: **профиль + «что было дальше»** — имя, телефон, email, дата регистрации,
   «аккаунт удалён»; после погашения — пополнения, оплаченные сессии, текущий баланс.
2. CSV: **нет**, только на странице. CSV остаётся `code,status,redeemed_at_utc,user_id`.

## Код (develop `b4a4a54`) — ground truth

- `PromoRedemption` хранит `walletId`, `createdAt`, `creditedMinor`, `codeId`, `batchId`;
  телефона / имени в нём нет (так и остаётся — читаем из `users` в момент показа).
- `User`: `displayName`, `phoneE164`, `email`, `createdAt`; удаление (`AURAT-0042`) обнуляет
  все три, строка остаётся надгробием + `AccountErasure`.
- Журнал: пополнение — `LedgerEntryType.TOPUP` (Play / Apple / заглушка), промо —
  `PROMO_CREDIT`, возврат стора — `STORE_REFUND`.
- Сессии: `sessions.conversationId → conversations.userId`; у удалённого аккаунта
  `conversationId = NULL` — его сессии к человеку больше не привязать.
- Индексы для чтения есть: `promo_redemptions(batchId, walletId)` unique,
  `ledger_entries(walletId, idempotencyKey)` unique, `conversations(userId, advisorId)` unique,
  `sessions(conversationId, idempotencyKey)` unique — миграция не нужна.
- Бэкофис: `findBatch` читает у публичного кода одну строку погашения и выбрасывает её;
  комментарии в `promo-codes.repository.ts` (`PromoCodeRow.redemption`) и в
  `publicBatchContent` фиксируют «охват, а не люди» (`AURAT-0146` §5) — пересматривается
  решением владельца выше, комментарии надо поправить.
- Нигде в бэкофисе пока не показаны телефон / email / имя — только id (`deletions`,
  промокоды). Страницы бэкофиса уже `no-store` + `noindex`, только за сессией оператора.

## Правила

- Build rules: «No PII in logs» — про логи; экран оператора — не лог. Логи этой задачей не
  меняются. Решение показать контакты оператору — владельца (п. 1 выше).
- Слои: запрос — в репозитории `promo-codes` (как `totals`), сервис — сквозной, контроллер —
  тонкий, view — чистая функция с экранированием через `html```.

## Противоречий нет

Кроме пересмотра `AURAT-0146` §5 «никогда кто» — это прямой запрос владельца.
