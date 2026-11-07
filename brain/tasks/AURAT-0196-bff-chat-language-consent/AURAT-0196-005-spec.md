# AURAT-0196-005 — spec: язык чата и согласие на сервере

Дата: 2026-11-07 · Статус: **черновик, ждёт ревью координатора и одобрения владельца** · slave-3
Фича `AURAF-0024`, задача 3 разбивки `AURAI-0012`. Контракт — `@aura/contracts` v0.31.0 (`AURAT-0195-005` §4, §7).
Решения в силе: 3, 4, 5, 6, 7, 10. Тип: задача (без отдельного файла фичи). Факты — `004-context.md`.

## Что получится

После задачи сервер хранит для каждого человека:
- **язык чата** — его пишет только отправка сообщения со своим `?lang`;
- **переключатель перевода**;
- **согласие чата** — версия и время сервера.

Всё это видно в `ProfileResponse.chat`, меняется через `PATCH /v1/me/chat-settings`. Чаттер видит язык в карточке
контакта (`client_language`).

**Ничего не переводится и никуда не уходит:** провайдер не вызывается, модуль перевода не трогается. Это модель
данных и правила для задачи 5 (конвейер). Старые клиенты разницы не замечают: `?lang` на отправке они шлют `en`,
это просто запишется, а `chat` в профиле они отрежут.

## 1. Данные — миграция `20261107140000_chat_settings` (только файлом)

```prisma
model User {
  …
  // AURAF-0024 (AURAT-0196): the person's chat settings — contract ChatSettings.
  chatLanguage           String?    // Language code; only a message send writes it
  chatTranslationEnabled Boolean   @default(false)
  chatConsentVersion     Int?
  chatConsentGivenAt     DateTime?  // the server's clock
}
```

SQL: три `ADD COLUMN`, все допускают `NULL` или имеют `DEFAULT`. Плюс `CHECK`: версия и время либо обе пусты, либо
обе заданы. Это инвариант сервера, а не ввод человека, поэтому довод из `user_profile` («CHECK превратит опечатку
в 500») сюда не относится.

Миграция только добавляет: работающая версия эти колонки не читает. `prisma generate` — в слоте, `migrate` —
только в маноре.

- **`UserRecord` / `toUserRecord`** получают четыре поля (`chatConsentGivenAt` — ISO-строкой, как всё выше
  репозитория).
- **Стирание аккаунта:** `CLEARED_PROFILE` (`prisma-account-erasure.repository.ts`) дополняется:
  `chatLanguage: null, chatTranslationEnabled: false, chatConsentVersion: null, chatConsentGivenAt: null`.
  Без этого язык и согласие пережили бы удаление.

## 2. Язык — пишет только отправка

**Контроллер** `POST /v1/advisors/:advisorId/messages` (JSON и multipart — один маршрут) читает
`@RequestLanguage() language: Language | null` **без** `languageOrDefault` и передаёт его в
`ChatService.sendMessage(…, language)`.

Отдельный «сырой» декоратор не нужен: `@RequestLanguage()` уже отличает «нет параметра» (`null`) от `en`
(уточнение к `001`, см. `004`).

**Правило** (`AURAT-0195` §4):

| `?lang` на отправке | `chatLanguage` |
|---|---|
| нет | не меняется |
| `de` (известный, не выключен) | `de` |
| `en` | `en` (человек вернулся к английскому) |
| незнакомый, `DE`, повтор, выключенный `DISABLED_LANGUAGES` | не меняется — как «нет параметра» |

- **Где в `sendMessage`:** сразу после `ensureConversation` (строка пользователя и контакт к этому моменту есть),
  до проверки `idempotencyKey` и до поста в Chatwoot (решение 1).
- **Одно условное обновление:** `UPDATE users SET chatLanguage = $lang WHERE firebaseUid = $uid AND chatLanguage IS
  DISTINCT FROM $lang` (Prisma `updateMany` с `OR: [{ chatLanguage: null }, { chatLanguage: { not } }]`).
  - Побеждает последнее значение.
  - Повтор того же языка ничего не пишет и `updatedAt` не трогает.
  - Только при изменении: чтение `id` и `chatwootContactId` и задача `client_language` (§5).
- Ошибка постановки задачи логируется по `userId` и **не** роняет отправку, как у имени (`enqueueNamePush`).
- **Swagger:** у отправки свой `ApiQuery lang` с описанием «запоминается как язык чата; без параметра не меняется».
  Общий `ApiLanguageQuery` говорит «отвечает на этом языке» — для отправки это неправда.

## 3. `ProfileResponse.chat` — на всех маршрутах профиля

`toProfileResponse` (единственная проекция: `GET` / `PATCH /v1/me`, `PUT` / `DELETE /v1/me/avatar`) добавляет:

```ts
chat: {
  language: user.chatLanguage,                       // null — ни разу не задан
  translationEnabled: translationActive(user),       // решение 2
  consent: user.chatConsentVersion === null ? null
    : { version: user.chatConsentVersion, givenAt: user.chatConsentGivenAt },
}
```

`translationActive(user)` = `chatTranslationEnabled && chatConsentVersion === CHAT_CONSENT_VERSION`. Чистая функция
в `profile/chat-settings.ts`, задача 5 возьмёт её же как часть условия перевода.

## 4. `PATCH /v1/me/chat-settings` → `ProfileResponse`

**Маршрут.** Новый тонкий `ChatSettingsController` (`@Controller('me')`, `@Patch('chat-settings')`) в модуле
`profile`.
- Под глобальной проверкой Firebase, **не** за `BillingEnabledGuard` (как профиль).
- Тело проверяет `ChatSettingsPatchRequest` из пакета (`.strict()`): `language`, незнакомый ключ, `consentVersion: 2`
  — это `400`.

**Решает чистая функция** `decideChatSettings(stored, patch)` в `profile/chat-settings.ts`. Ответ — либо
`{ write }`, либо отказ. `CURRENT = CHAT_CONSENT_VERSION` (сейчас 1).

1. **Новое согласие** — если `consentVersion` есть и (сохранённого нет или оно младше). Пишутся версия и `now()`
   сервера. Та же или более ранняя версия — ничего, `givenAt` прежний.
2. **Действующая версия** — новая, если она записывается, иначе сохранённая.
3. **`translationEnabled: true`**, когда действующая версия ≠ `CURRENT`, — это **`409`**
   `{ code: 'chat_consent_required', message }` (`ConflictException`, как у промокодов). Отклоняется **всё тело**:
   согласие из него тоже не пишется.
4. **Переключатель:**
   - есть `translationEnabled` — его значение;
   - иначе, если только что записано согласие версии `CURRENT`, — `true`;
   - иначе не меняется.

   `false` принимается всегда: это отзыв.
5. **Пустое тело** — без записи, ответ — текущий профиль (как `PATCH /v1/me`).

**Запись** — `UsersRepository.updateChatSettings(userId, { consentVersion?, translationEnabled? })`. Согласие пишется
с условием `chatConsentVersion IS NULL OR chatConsentVersion < $v`: повтор или гонка двух вкладок `givenAt` не
сдвигают. Обе записи идут в одной транзакции и возвращают строку после записи.

**Таблица проверок** (`CURRENT = 1`):

| Сохранено | Тело | Итог |
|---|---|---|
| нет согласия | `{ consentVersion: 1 }` | согласие v1 + время, перевод **вкл** |
| нет согласия | `{ consentVersion: 1, translationEnabled: false }` | согласие v1, перевод выкл |
| нет согласия | `{ translationEnabled: true }` | `409 chat_consent_required`, ничего не записано |
| v1, выкл | `{ translationEnabled: true }` | вкл |
| v1, вкл | `{ consentVersion: 1 }` | ничего (повтор), `givenAt` прежний |
| v1, вкл | `{ translationEnabled: false }` | выкл (отзыв) |
| любое | `{}` | ничего, текущий профиль |
| любое | `{ consentVersion: 2 }` / `{ language: 'de' }` / `{ foo: 1 }` | `400` (схема) |

**Журнал:** запись без языка и без UID, только `userId`. Тексты согласия на сервере нет — он у клиента.

## 5. Атрибут контакта `client_language`

**Порт.** `ChatwootContactPort.setClientLanguage(contactId, language)`. 404 — успех, как `setName`: у удалённого
контакта повторять нечего.

**Клиент.** `setContactCustomAttributes(contactId, attributes)`:
- `PUT /contacts/:id { custom_attributes }` — Chatwoot их **объединяет** (`contacts_controller.rb:177-191`), чужие
  атрибуты не теряются, читать перед записью не нужно;
- значение — по решению 4.

**Очередь** `contact-attributes`, задача `push`, данные — только `{ userId }`:
- 5 попыток, экспоненциальная пауза, хранение как у `contact-name`;
- **без `jobId`**: он схлопнул бы вторую смену языка за сутки;
- процессор тонкий → `ChatSettingsService.pushLanguageToDesk`;
- сервис перечитывает строку. Нет строки, контакта или языка — выход. Иначе шлёт **текущий** язык, поэтому
  порядок и повторы безразличны.

Поставка задачи — из §2, только при смене языка. Контакт к этому моменту уже есть: `ensureConversation` идёт раньше.
Провизию и создание контакта не трогаю: язык пишется после неё и сам ставит задачу.

**desk-setup.**
- `deskContactAttributeDefinitions()` в `desk-attributes.ts`: `client_language`, отображается как «Client language»,
  тип `list` (фильтр в столе предлагает языки, а не поле ввода).
  - Значения — по решению 4.
  - Описание: «Language of the client's app at their last message. With translation on, replies reach them in it.
    Set by Aura.»
- Клиент получает `list/create/updateContactAttributeDefinition`. Это те же три вызова, что у разговора, с
  `attribute_model: 'contact_attribute'`. Существующие методы обобщаются параметром модели, а не копируются.
- `DeskSetupService.ensureDeskSchema` проходит обе модели, отчёт `desk:setup` показывает и контактные определения.
- Идемпотентно, как сейчас.

**Локаль агентов `en`** — решение 5.

## 6. Контракты и OpenAPI

- `package.json` → `github:RomSribn/aura-contracts#v0.31.0`, `npm install` (обновляется lock).
- `src/contracts/chat-settings.ts` — ре-экспорт `ChatSettings`, `ChatSettingsPatchRequest` (+ `…Schema` для пайпа),
  `CHAT_CONSENT_VERSION`, `ChatSettingsRefusalCode`.
- `openapi.ts`:
  - `profileResponseOpenApi.properties.chat` — необязательное, вне `required`;
  - `chatSettingsPatchRequestOpenApi` (`additionalProperties: false`);
  - на маршруте — `200` / `400` / `409`;
  - `?lang` отправки (§2).
- `Message.translation`, `translatedFrom`, `message.translated` в OpenAPI — задача 5: сервер их ещё не отдаёт.

## 7. Проверки в слоте (без стека)

`prisma generate`, `lint`, `typecheck`, `build`, `jest`. Чистые тесты:

1. `decideChatSettings` — вся таблица §4 + `translationActive`.
2. `toProfileResponse` — `chat` на новой строке (`null` / `false` / `null`) и на заполненной, согласие ISO.
3. Маршруты (по образцу `request-language.routes.spec.ts`, Fastify, сервисы — моки):
   - отправка: `?lang=de` → `'de'`; без параметра → `null`; выключенный → `null`; multipart — тот же `?lang`;
   - `PATCH /v1/me/chat-settings`: `400` на `language`, незнакомый ключ, `consentVersion: 2`; `409` с кодом.
4. `ChatService.sendMessage`:
   - язык пишется после `ensureConversation` и до поста;
   - `null` — без записи;
   - повтор с тем же `idempotencyKey` всё равно пишет язык.
5. `ChatSettingsService`:
   - смена ставит задачу;
   - та же — нет;
   - сбой очереди не роняет отправку;
   - `pushLanguageToDesk` — без контакта и без языка выход, иначе текущее значение.
6. Клиент: `setContactCustomAttributes` шлёт `PUT … { custom_attributes: { client_language } }`, 404 — успех.
7. desk-setup: контактное определение создаётся, совпадающее — не трогается, разошедшееся — обновляется; обе модели.
8. Стирание: `CLEARED_PROFILE` содержит четыре новые колонки.
9. Регрессия: существующие спеки профиля, аватара, отправки и `desk-setup` проходят.

**Только в маноре, после мёржа:**
- `prisma migrate deploy`;
- `desk:setup` на столе — определение `client_language`;
- отправка с `?lang=de` → атрибут в карточке контакта;
- `PATCH` → профиль.

## 8. Что оставляю задаче 5 (конвейер)

На этой модели данных, без новых колонок у `users`:

- **Условие перевода в обе стороны:**
  - `translationActive(user)`;
  - `chatLanguage` не `null` и не `en` (решение 4);
  - язык **не выключен** `DISABLED_LANGUAGES` в момент перевода. Сохранённый язык мог быть выключен позже;
  - профиль `chat` модуля перевода не `off`.
- **Язык ответа** — `chatLanguage` в момент вставки строки советника, пишется в `pending`. Язык перевода сообщения
  человека — всегда `en`.
- **Таблица `MessageTranslation`** (`messageId → Message onDelete Cascade`, `language`, `status`, `content?`,
  `engine?`), `@@unique([messageId, language])`. Удаление сообщения удаляет и перевод.
- **`Message.translation`** в `toDto`: история, `message.new`, сверка; только у советника, без `engine`.
- **`pending`** — в той же транзакции, что строка; задача `chat-translation` (`jobId = tr-{messageId}`), сторож в
  сверке.
- **`message.translated`** — через доставку из сохранённой строки, без пуша.
- **`translatedFrom` → `translations`** с пределом, как `DELETED_IDS_LIMIT`. OpenAPI этих полей.
- **Отправка:** перевод на `en` до `postUserMessage`, `content_attributes.translations.en`, кэш по
  `idempotencyKey`, `desk-note` при сбое. Превью списка у стола показывает оригинал (проверка стола) — учесть там.
- **Профиль `chat`** в `translation-config.ts`.
- Если в решении 4 выбран вариант А: `LANGUAGE_NAMES` уже в `common/language` — переиспользовать.
- `client_language` уже на контакте — конвейер его не трогает.

## 9. Решения (рекомендация первой)

1. **Когда писать язык на отправке.**
   - **А:** после `ensureConversation`, **до** поста в Chatwoot. Повтор отправки, у которой пост прошёл, а ответ до
     телефона не дошёл, возвращается рано по `idempotencyKey`. Если писать язык после поста, он в таком случае
     потерялся бы. Цена: отправка, которую стол потом отклонил (422), язык всё равно запишет. Это намерение
     человека, вреда нет.
   - **Б:** только после успешной записи строки.
2. **`chat.translationEnabled` в ответе.**
   - **А:** действующее значение — `chatTranslationEnabled && consent.version === CHAT_CONSENT_VERSION`. Когда выйдет
     v2 текста, переключатель честно покажет «выкл», клиент спросит согласие заново, и ответ сойдётся с тем, что
     делает сервер.
   - **Б:** сырое значение колонки. Клиенту тогда придётся самому сверять версию.
3. **Имена колонок.**
   - **А:** `chatConsentVersion` / `chatConsentGivenAt`. Контракт называет это согласием **чата**.
   - **Б:** `chatTranslationConsent*`, как в `AURAI-0012` §2.
4. **Значение `client_language` у стола.**
   - **А:** английское название (`German`), список значений — 24 названия. Чаттеру `German` понятнее, чем `de`
     (`sk`, `sl`, `lv`, `lt` путаются). Таблица `LANGUAGE_NAMES` переезжает из адаптера Claude в
     `common/language/language-names.ts`: модулю `chatwoot` нельзя импортировать из адаптера перевода. Промпт Claude
     импортирует её оттуда, текст промпта не меняется.
   - **Б:** код (`de`), тип `text`, без переезда.
5. **Локаль агентов `en`.**
   - **А:** без кода, только запись в desk-setup и `AURAI-0012`. Пузырь берёт `translations[локаль агента]`, потом
     `[локаль аккаунта]`, потом **первый ключ** (`useTranslations.js:12-22`). Конвейер пишет только `en`, поэтому
     чаттер видит английский при любой локали. Локаль людей-агентов — их `ui_settings`, токен сервисного
     пользователя ей не хозяин.
   - **Б:** desk-setup ставит локаль аккаунта `en` (`PATCH /accounts/:id`). Это задевает язык интерфейса и писем у
     всех агентов аккаунта, а один Chatwoot сейчас на два окружения.
