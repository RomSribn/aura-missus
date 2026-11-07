# AURAT-0196-004 — context

Дата: 2026-11-07 · Код — slave-3 `master` @ `524f412`; Chatwoot — `chatwoot-manor` @ `11deffdd5` (v4.15.1);
контракты — тег `v0.31.0` (`fa56e89`).

## Источники

- `AURAT-0195-005-spec.md` §4, §7 (одобрено, `006`), `008` (JSDoc порядка выкатки версии согласия).
- `AURAI-0012` §1.2–1.4, §2, §6, §8, решения владельца, проверка стола; `AURAI-0012-legal.md` (решение 6).
- `AURAF-0024` — строка 005.
- Код BFF (ниже) и исходники Chatwoot.

## Факты из кода

**Язык запроса.**
- `@RequestLanguage()` (`src/common/language/request-language.decorator.ts:13`) отдаёт `Language | null`, а не `en`.
  `null` — это любой «непригодный» язык: параметра нет, код незнакомый, `DE`, повтор `?lang=de&lang=fr`, язык выключен
  `DISABLED_LANGUAGES` (`request-language.ts:17-22`). `en` подставляет отдельный `languageOrDefault` в контроллерах.
- **Уточнение к заглушке `001`:** «сырой» `?lang` отдельным декоратором не нужен — нужен тот же `@RequestLanguage()`
  без `languageOrDefault`. Отсутствие и `en` он уже различает.
- Отправка (`chat.controller.ts:59-97`) сейчас `?lang` не читает вовсе. JSON и multipart — один маршрут
  `POST /v1/advisors/:advisorId/messages`, `?lang` в query у обоих. Значит, правило записи живёт в одном месте.

**Отправка.** `ChatService.sendMessage` (`chat.service.ts:82-118`): проверка пустоты → `ensureConversation`
(создаёт пользователя, контакт и разговор) → проверка `idempotencyKey` → `postUserMessage` → upsert строки.

**Пользователь.** `User` (`prisma/schema.prisma`), `UserRecord` / `PrismaUsersRepository` с явной проекцией
`toUserRecord` (новая колонка сама в вызывающих не появится). Колонки в БД — camelCase в кавычках.

**Профиль.** `toProfileResponse(user)` (`src/modules/profile/profile-response.ts`) — единственная проекция; её зовут
`ProfileService` (`GET` / `PATCH /v1/me`) и `AvatarService` (`PUT` / `DELETE /v1/me/avatar`). Добавить `chat` туда —
значит на всех маршрутах профиля и аватара.

**Стирание аккаунта.** `CLEARED_PROFILE` (`prisma-account-erasure.repository.ts:35-46`) перечисляет личные колонки
`users` явно — новые надо дописать, иначе язык и согласие переживут удаление аккаунта.

**Контакт в Chatwoot.**
- Порт `ChatwootContactPort` (`setAvatar`, `setName`, `deleteContact…`), сервис — тонкий, клиент — `ChatwootClient`.
- `PUT /contacts/:id` с `custom_attributes` **объединяет**, а не заменяет: `contacts_controller.rb:177-191`
  (`@contact.custom_attributes.merge(permitted_params[:custom_attributes])`). Значит, `setContactCustomAttributes` —
  тот же `PUT`, без чтения-перед-записью (в отличие от атрибутов разговора, `chatwoot.client.ts:424-431`).
- desk-setup (`desk-setup.service.ts`, `desk-attributes.ts`) знает только `conversation_attribute`
  (`chatwoot.client.ts:467-495`, `:695`).
- Образец очереди — `contact-name` (`queues.ts:83-87`, `:241-251`, `contact-name.processor.ts`,
  `ProfileService.pushNameToDesk`): данные — только `userId`, задача перечитывает строку, 5 попыток, без `jobId`.

**Локаль агентов.** Пузырь берёт `translations[локаль агента]` → `[локаль аккаунта]` → **первый ключ**
(`dashboard/composables/useTranslations.js:12-22`). Конвейер пишет только `translations.en`, значит чаттер видит
английский при любой локали. Локаль людей-агентов — их `ui_settings`, токен сервисного пользователя ею не управляет.

**Названия языков.** `LANGUAGE_NAMES` (код → английское название) есть только внутри адаптера Claude
(`src/modules/translation/claude/claude-prompt.ts:17`). Модулю `chatwoot` импортировать из адаптера перевода нельзя.

**Контракты.** BFF на `#v0.30.0` (`package.json:37`, lock `14073f1`), в `node_modules` слота — 0.30.0. По `AURAT-0195`
§6 BFF собирается с v0.31.0 без правок. `HistoryQuery.translatedFrom` новый BFF молча пропустит — это и есть «сервер
не догоняет», пока нет задачи 5.

**Модуль перевода (0191).** Профили — только `campaign` (`translation-config.ts:11`). Профиль `chat` — задача 5.

## Противоречия / уточнения

- Заглушка: «`@RequestLanguage()` подставляет `en`» — неверно, подставляет `languageOrDefault` (выше).
- `AURAI-0012` §2 называет колонки `chatTranslationConsentAt/Version`. Контракт (`AURAT-0195` §4) уточнил: это
  согласие **чата**, не перевода. Предлагаю `chatConsentVersion` / `chatConsentGivenAt` (спека, решение 3).
