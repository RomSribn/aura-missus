# AURAT-0196-007 — execute

Дата: 2026-11-08 · slave-3, ветка `feature/AURAT-0196-bff-chat-language-consent` (от develop `524f412`).
По спеке `005` (одобрена в `006`, решения 1–5 — А, решение 6 — `chat` отдаётся сразу). Всё застейджено, коммитов нет.

## Что сделано

**Данные**
- `prisma/schema.prisma` → `User`: `chatLanguage`, `chatTranslationEnabled`, `chatConsentVersion`, `chatConsentGivenAt`.
- Миграция **файлом**: `prisma/migrations/20261107140000_chat_settings/migration.sql`.
  - Три `ADD COLUMN` плюс `CHECK users_chat_consent_complete`: версия и время вместе.
  - Сверено офлайн с `prisma migrate diff` (old schema → new): столбцы совпадают.
- `UserRecord` / `toUserRecord`: четыре поля, время согласия — ISO.
- Новые методы репозитория:
  - `setChatLanguage(firebaseUid, lang)` — одно условное `updateMany` (`OR null / not`). Чтение `id` и контакта —
    только при изменении;
  - `updateChatSettings(userId, …)` — транзакция. Согласие пишется с условием `version IS NULL OR < v`.
- Стирание аккаунта: `CLEARED_PROFILE` чистит все четыре колонки.

**Правила**
- `src/modules/profile/chat-settings.ts` — чистые функции:
  - `decideChatSettings` (таблица §4);
  - `translationActive`: переключатель **и** согласие текущей версии (решение 2);
  - `toChatSettings`.
- `toProfileResponse` → `chat` на всех маршрутах профиля и аватара (решение 6).

**Маршруты**
- `PATCH /v1/me/chat-settings` — `ChatSettingsController` (тонкий) и `ChatSettingsService`.
  - Тело проверяет `ChatSettingsPatchRequest` (strict).
  - `409 { code: 'chat_consent_required' }`; пустое изменение — без записи.
- Отправка (`chat.controller.ts`): `@RequestLanguage()` **без** `languageOrDefault` → `ChatService.sendMessage(…, language)`.
  - Язык пишется после `ensureConversation`, до проверки `idempotencyKey` и поста (решение 1).
  - Свой `ApiQuery lang` с описанием «запоминается».
- `ChatModule` импортирует `ProfileModule` (цикла нет).

**Стол**
- Порт `ChatwootContactPort.setClientLanguage`; 404 — успех.
- Клиент `setContactCustomAttributes`: `PUT /contacts/:id`, Chatwoot объединяет атрибуты.
- Значение — английское название (решение 4). `LANGUAGE_NAMES` переехала в
  `src/common/language/language-names.ts`, промпт Claude импортирует её оттуда, текст промпта не менялся.
- Очередь `contact-attributes` (задача `push`, `{ userId }`, 5 попыток, без `jobId`), `ContactAttributesProcessor` →
  `ChatSettingsService.pushLanguageToDesk`. Задача перечитывает строку; незнакомый код пропускает.
- desk-setup:
  - `deskContactAttributeDefinitions()`: `client_language`, `list` из 24 названий, английский первым;
  - методы клиента обобщены моделью: `list/create/updateAttributeDefinition(model, …)` вместо `…Conversation…`;
  - `ensureDeskSchema` проходит обе модели.
- Локаль агентов — без кода (решение 5).

**Контракты и OpenAPI**
- `package.json` / lock → `#v0.31.0` (`fa56e89`).
- `src/contracts/chat-settings.ts` — ре-экспорт.
- `openapi.ts`: `chat` в профиле (необязательное), `chatSettingsPatchRequestOpenApi`.

**README** — `?lang` на отправке, раздел `PATCH /v1/me/chat-settings`, `client_language`, `desk:setup`.
**AURAF-0024** — строка 005 уточнена (атрибут контакта), шаг 3 в плане. BE ✓ — после мёржа и проверки в маноре.

## Файлы

- Новые:
  - `src/common/language/language-names.ts`
  - `src/contracts/chat-settings.ts`
  - `src/jobs/contact-attributes.processor.ts`
  - `src/modules/profile/chat-settings{,.service,.controller}.ts` + спеки всех трёх
  - миграция
- Изменённые (код):
  - `schema.prisma`, `package{,-lock}.json`, `README.md`
  - `src/contracts/{index,openapi}.ts`, `src/desk-setup.ts`, `src/jobs/{jobs.module,queues}.ts`
  - `account/prisma-account-erasure.repository.ts`
  - `auth/{users.repository,prisma-users.repository,users.service}.ts`
  - `chat/{chat.controller,chat.module,chat.service}.ts`
  - `chatwoot/{chatwoot-contact.port,chatwoot-contact.service,chatwoot.client,desk-attributes,desk-setup.service}.ts`
  - `profile/{profile-response,profile.module}.ts`
  - `translation/claude/claude-prompt.ts`
- Изменённые (спеки): фикстуры `UserRecord` в 11 спеках, моки порта и репозитория. Тесты добавлены в
  `chat.service`, `chatwoot.client`, `chatwoot-contact.service`, `desk-setup.service`, `prisma-users.repository`,
  `request-language.routes`.

## Проверки (слот, без стека)

- `prisma validate` / `generate` — ок.
- `lint` — чисто, `tsc --noEmit` — чисто, `build` — ок.
- `jest`:
  - первый полный прогон — **181 / 181 наборов, 2439 / 2439 тестов**;
  - после правок README, комментария и выравнивания схемы — 2438 / 2439. Упал
    `backoffice-promo-codes.smoke.spec.ts`: один раз, этот код не затронут. Отдельно он проходит 12 / 12 —
    похоже на таймаут под нагрузкой.
- Новые тесты:
  - вся таблица §4 + сценарии версии 2;
  - HTTP: `PATCH` 200 / 409 / 400 (×5);
  - `?lang` на отправке: JSON `de / en / нет / mt / DE` → `de / en / null / null / null`, multipart `fr`;
  - порядок «ensure → язык → пост», повтор по `idempotencyKey`;
  - условные записи репозитория;
  - адаптер и desk-setup обеих моделей.
- Форматирование: prettier задел чужие строки в двух файлах, грязных ещё до задачи
  (`provisioning.service.spec.ts`, `claude-prompt.ts`), — откачено, остались только мои правки. В `schema.prisma`
  переформатирован только блок `User`.

## Только в маноре после мёржа

1. `prisma migrate deploy`.
2. `desk:setup` — определение `client_language` у контакта.
3. Отправка с `?lang=de` → в карточке контакта «German».
4. `PATCH /v1/me/chat-settings` → профиль.

## Открытое

- Задаче 5 — §8 спеки. Плюс: язык, выключенный `DISABLED_LANGUAGES` после записи, не должен переводиться.
