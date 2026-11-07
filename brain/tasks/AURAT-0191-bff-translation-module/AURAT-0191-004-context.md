# AURAT-0191-004 — context

Дата: 2026-11-07. aura-bff `develop` @ `b81cc54`, missus `master` @ `d5e7225`.

## Источники

- `AURAI-0012` (high, смёржено): §3 порт и DI, §4 модель и стоимость, §5 глоссарий, Implementation Notes, задача 4.
- `AURAT-0189-007-spec-v2.md` (ветка slave-3, только чтение): места и лимиты сезона (`SEASON_COPY_LIMITS`,
  `ticketDiscountSub` 40), плейсхолдеры `{code}` `{amount}` `{pct}`, кнопка без кода, el-надзаголовки капсом без тонуса,
  точка подключения `translateCampaignText`.
- `AURAT-0192-001` (заглушка) — первый потребитель: 9 текстов сезона + подпись скидки, кнопка «Перевести на 23 языка».
- Бандл-скилл `claude-api` (цены на 2026-10-06): таблица thinking, `messages.parse` + `zodOutputFormat`, типы ошибок
  (`.type === 'billing_error'` у 402), `fallbacks: "default"` (бета `server-side-fallback-2026-07-01`, Opus 5.5 /
  Sonnet 5.5, только Claude API; у Haiku 5.5 нет), минимальный кэшируемый префикс 512 у Sonnet 5.5 / Haiku 5.5.

## Код (ground truth)

- Порт = абстрактный класс-токен (`play-purchase.port.ts:23-34`); выбор адаптера `useFactory` + `ConfigService` при старте
  (`play.module.ts:41-87`); `StaffChatPort` резолвится в `null` без Telegram (`telegram.module.ts:14-31`).
- `env.schema.ts`: правила «все или ничего» (`requireTelegramStaffChat` `:554-570`, `requireAppStoreConfig`);
  **`NODE_ENV=production` во всех развёрнутых окружениях, bff-dev тоже** (`env.schema.ts:577-578`, `Dockerfile:54`).
  Значит, «fake запрещён в проде» по `NODE_ENV` = fake только на локальном стеке и в тестах → решение 4 спеки.
- Redis — глобальный `REDIS_CLIENT` (ioredis, `common/redis/redis.module.ts`).
- Лог ошибки задачи пишет `error.message` (`logging-worker.host.ts:46`) — текст провайдера туда попадать не должен.
- Длина текста сезона — `String.length` после подстановки (`campaign-rules.ts:112-135`, `copyTooLong`).
- Глоссарий приложения: `aura-app/scripts/i18n/glossary.json` **v3** — 96 терминов × 23 языка (`use` / `stem` / `avoid`,
  `match` по английскому), `register` по языку (обращение, местоимения, форма кнопки, примеры, заметка — в el «текст
  капсом — без ударений»). 134 КБ. В BFF сейчас только `avoid` для reader / reading
  (`advisors/labels/glossary-avoid.spec-fixtures.ts`), `AURAT-0189` переносит его в `src/common/language/` — не трогаю.
- `'…'.toLocaleUpperCase('el')` в Node снимает тонос верно («Μάιος» → «ΜΑΪΟΣ») — капс можно делать кодом, а не моделью.
- В BFF нет ни SDK, ни переменных провайдера. `@anthropic-ai/sdk` — последняя `1.6.0` (2026-11-05), peer `zod ^3.25 || ^4`;
  в BFF `zod 3.25.76` — совместимо. `tsconfig`: `resolveJsonModule: true`.

## Расхождения с `AURAI-0012` (выношу в спеку)

1. Запрос порта — список текстов (кампания: 10 текстов на язык одним вызовом, а не 230 вызовов); чат шлёт один.
2. `formality` не поле запроса: обращение выводится из `register` глоссария, который адаптер получил в `prepare`.
3. Цену считает адаптер (у LLM и DeepL разные единицы) — `TRANSLATION_PRICES` в env не нужен.
4. `TRANSLATION_CONCURRENCY` и `ChatTranslationService` (условия §1.2) — задача 5, не здесь.
5. Правило 8 сборки («нет неиспользуемых провайдеров»): у сервиса нет потребителя до `AURAT-0192` → решение 5 спеки.
