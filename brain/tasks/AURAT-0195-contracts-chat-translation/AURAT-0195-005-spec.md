# AURAT-0195-005 — spec: контракты перевода чата (`@aura/contracts` v0.31.0)

Дата: 2026-11-07 · Статус: **одобрено владельцем 2026-11-07 (все три решения — первый вариант), см. `006`** · slave-2
Фича `AURAF-0024`, шаг 2 разбивки `AURAI-0012` (§1–§3, §7, §8 п. 2). Решения в силе: 3, 4, 5, 6, 7, 10.
Тип: задача (без отдельного файла фичи). Факты — `004-context.md`.

## Что получится

Один выпуск контрактов, только добавления. Старые клиенты и сервер его не замечают. Новые клиенты и сервер получают
четыре вещи:
1. перевод ответа советника внутри сообщения;
2. догонку переводов через историю;
3. WS-событие о готовом переводе;
4. настройки чата пользователя: язык, переключатель перевода, согласие.

BFF и приложение кодом не меняются и собираются с новой сборкой (проверка — §6).

## 1. Перевод в сообщении — `src/chat.ts`

```ts
export const MessageTranslation = z.discriminatedUnion('status', [
  z.object({ status: z.literal('pending'),    language: z.string().min(1) }),
  z.object({ status: z.literal('translated'), language: z.string().min(1), content: z.string() }),
  z.object({ status: z.literal('failed'),     language: z.string().min(1) }),
]);

// в Message:
translation: MessageTranslation.optional().catch(undefined),
```

JSDoc (по-английски, как весь пакет), смысл по пунктам:
- **Только у `direction: 'advisor'`.** У сообщений человека и `system` поля нет никогда. Перевод сообщения человека
  на английский для стола остаётся на сервере.
- **`content` не меняется.** У советника это английский оригинал, у человека — то, что он написал. Отдельного
  `original` нет.
- **`language`** — язык, на который переводит сервер: язык чата пользователя в момент прихода ответа. Он может не
  совпасть с текущим языком интерфейса (смена языка, веб и приложение у одного человека).
- **Что показывать** (`AURAI-0012` §7):
  - `pending` — английский и «переводится…»;
  - `translated` при совпадении языка с интерфейсом — `translation.content`, подпись «Переведено ИИ» и «Показать
    оригинал»;
  - `failed` или другой язык — английский с тихой подписью. Кнопки повтора нет: дозаполняет сервер.
- **Превью** (Home, список чатов, у веба свои места) берут `translation.content` по тому же правилу.
- **Нет поля** — перевода нет и не будет: сервер выключен, нет согласия, язык `en` или неизвестен, это токен или
  подпись-заглушка, вложение без подписи, старое сообщение. Показывается `content`, как сегодня.
- **`.catch(undefined)`.** Если сервер когда-нибудь пришлёт статус, которого клиент не знает, пропадёт только
  перевод (английский останется), а не всё сообщение. Это та же беда, от которой защищает комментарий к
  `idempotencyKey`. Других `.catch` в `Message` нет. Новый статус — это всё равно новое поле контракта, а не
  тихое расширение.

## 2. Догонка — `HistoryQuery` / `HistoryResponse`

```ts
// HistoryQuery:
translatedFrom: z.string().optional(),
// HistoryResponse:
translations: z.array(MessageTranslationUpdate).optional().catch(undefined),

export const MessageTranslationUpdate = z.object({ messageId: z.string(), translation: MessageTranslation });
```

По образцу `deletedFrom` → `deletedIds` (AURAF-0018):
- **`translatedFrom`** — id сообщения. Обычно это самое старое сообщение в треде, у которого перевод ещё `pending`
  или `failed`.
- **Ответ** — текущий перевод каждого сообщения советника, стоящего на этом id или после него, если перевод есть.
  - Может пересекаться с `messages`, состояние там одинаковое. Клиент заменяет перевод по `messageId`.
  - Незнакомый id даёт пустой список, а не ошибку.
  - Длину списка сервер ограничивает так же, как `deletedIds` (`DELETED_IDS_LIMIT`), и пишет это в JSDoc.
- **Без `translatedFrom`** поля нет. Отсутствие поля значит «сервер не догоняет переводы» (старый BFF молча
  отрезает незнакомый параметр).
- **`.catch(undefined)`** — то же, что в §1: при незнакомом статусе пропадает догонка, а не страница истории.

## 3. WS `message.translated`

```ts
z.object({
  type: z.literal('message.translated'),
  advisorId: AdvisorId,
  messageId: z.string(),
  translation: MessageTranslation,   // 'translated' | 'failed'; 'pending' приходит в message.new
}),
```

- **Пуша нет.** `MessagePushData` не меняется, фоновый клиент догоняет через `translatedFrom`.
- **Порядок переводов между собой не важен:** порядок задают сообщения.
- **Старые сборки** отбрасывают незнакомое событие (`safeParse` → `return`, проверено в `ChatProvider.tsx:663`).
  Так же было с `message.deleted` в v0.22.0.

## 4. Язык, переключатель, согласие — новый `src/chat-settings.ts`

```ts
/** Version of the consent text a client shows before the first chat message (AURAI-0012 decision 6). */
export const CHAT_CONSENT_VERSION = 1;

export const ChatConsent = z.object({ version: z.number().int().positive(), givenAt: z.string() });

export const ChatSettings = z.object({
  language: z.string().min(1).nullable().default(null),    // только чтение
  translationEnabled: z.boolean().default(false),
  consent: ChatConsent.nullable().catch(null).default(null),
});

// ProfileResponse (profile.ts):
chat: ChatSettings.optional(),

/** Body of PATCH /v1/me/chat-settings → answers with ProfileResponse, like the avatar routes. */
export const ChatSettingsPatchRequest = z.object({
  consentVersion: z.number().int().min(1).max(CHAT_CONSENT_VERSION).optional(),
  translationEnabled: z.boolean().optional(),
}).strict();

export const ChatSettingsRefusalCode = z.enum([
  /** translationEnabled: true without a consent of CHAT_CONSENT_VERSION, stored or in the same body. HTTP 409. */
  'chat_consent_required',
]);
```

**`language`** (решения 3, 4, 5):
- язык, на который переводятся ответы, один на пользователя для всех советников;
- пишет **только отправка сообщения** со своим `?lang`, побеждает последнее значение;
- запрос без `?lang` язык не меняет, `en` меняет (человек может вернуться к английскому);
- `en` или `null` — ответы не переводятся, вызовов нет;
- в теле запроса его нет: менять язык другим путём нельзя.

**`consent`** (решение 6, `AURAI-0012-legal.md`):
- галочка явного согласия: чувствительные данные в чате **и** ИИ-перевод (Anthropic, USA). Поэтому это согласие
  чата, а не «согласие на перевод»;
- клиент показывает её перед первым сообщением в чат, если `consent` нет или `consent.version < CHAT_CONSENT_VERSION`.
  Затем шлёт `consentVersion` — версию показанного текста;
- время ставит сервер. Повтор той же или более ранней версии ничего не меняет, `givenAt` остаётся прежним;
- с согласием нужной версии перевод включается, если в том же теле нет `translationEnabled: false`;
- согласие старой версии для перевода не считается;
- **отзыв** — `translationEnabled: false`. Записи «согласия нет» через API нет: чат целиком отзывается удалением
  аккаунта, как сейчас (legal);
- новый текст согласия — это `CHAT_CONSENT_VERSION + 1`, minor-выпуск контрактов.

**`translationEnabled`** — переключатель «Переводить мой чат» в профиле. Действует в обе стороны: и на ответы, и
на перевод сообщений человека для стола.

**`chat` отсутствует** — сервер настроек чата ещё не знает: не показывать ни галочку, ни переключатель. По
разбивке сервер (задача 3) всё равно выходит раньше клиентов.

**Отправка без согласия не отклоняется.** Старые сборки галочку не показывают, отказ сломал бы им чат. Без
согласия просто нет перевода.

**JSDoc `SendMessageRequest` и `language.ts`:** `?lang` на отправке — единственный запрос, где язык остаётся
надолго. Клиент без выбора языка (`AURA_I18N_ENABLED` выключен) не шлёт `?lang` **на отправке** — ни JSON, ни
multipart, иначе каждое сообщение записывает `en`.

## 5. Выпуск

- `package.json` → `0.31.0`.
- `README.md` — абзац v0.31.0 в стиле v0.30.0. Строка «What's inside» — `chat-settings`.
- `index.ts` — `export * from './chat-settings'`.
- Клон `/Volumes/Work/personal/ai-manors/aura-contracts`, ветка `feature/v0.31.0-chat-translation` от `main`
  `14073f1` (создана), застейджено, **без коммита**. Тег `v0.31.0` и push делает координатор при мёрже, с
  одобрения владельца.

## 6. Проверка (в слоте, без стека)

1. Контракты: `typecheck`, `build`.
2. BFF slave-2: свежий пакет (`dist`, `package.json`) подложен в `node_modules/@aura/contracts` (сейчас там 0.28.0
   при lock на v0.30.0). Затем `lint`, `typecheck`, `build`, `jest` — **без правок кода BFF**.
3. Приложение — **ничего не пишется в манор `aura-app-manor`**:
   - `tsc --noEmit` по конфигу из scratchpad;
   - конфиг наследует `tsconfig` манора приложения (`e0ed5de`) и подменяет путь `@aura/contracts` на новую сборку.
4. Совместимость — скрипт в scratchpad, обе сборки рядом (v0.30.0 из `node_modules` приложения, только чтение):
   - ответы v0.30 (сообщение, история, профиль текущего BFF) разбираются новой сборкой;
   - новое сообщение с `translation` разбирается старой (поле отрезается);
   - `message.translated` старой сборкой отбрасывается;
   - незнакомый статус: сообщение живо, `translation` — `undefined`;
   - `ChatSettingsPatchRequest` отклоняет `consentVersion: 2`, `language` и незнакомый ключ.

## 7. Что дальше (номера выдаёт координатор)

**Сервер, задача 3 — язык и согласие:**
- `User.chatLanguage`, `chatTranslationEnabled`, согласие (версия + время сервера);
- правило записи на отправке: нужен «сырой» `?lang`. `@RequestLanguage()` подставляет `en` вместо отсутствующего
  параметра, а здесь отсутствие должно отличаться от `en`;
- `ProfileResponse.chat` в `toProfileResponse`, то есть на всех маршрутах профиля и аватара;
- `PATCH /v1/me/chat-settings`: `409 chat_consent_required`, правила §4;
- атрибут контакта `client_language`, OpenAPI;
- переход на `#v0.31.0`.

**Сервер, задача 5 — конвейер:**
- `Message.translation` в `toDto`: история, `message.new`, сверка. Только у советника, без `engine`;
- `pending` пишется в той же транзакции, что строка;
- `message.translated` — через доставку из сохранённой строки, без пуша;
- `translatedFrom` → `translations` с пределом, как у `DELETED_IDS_LIMIT`;
- удаление сообщения удаляет и перевод.

**Приложение, задача 7 (и веб, задача 8):**
- рендер и подписи по §1, превью Home / Chats;
- разбор `message.translated`;
- догонка `translatedFrom` при синке;
- галочка перед первым сообщением по `chat.consent` / `CHAT_CONSENT_VERSION`;
- переключатель в профиле;
- без `?lang` на отправке (JSON и upload) при выключенном выборе языка;
- при отсутствии `chat` — ничего не показывать;
- строки на 24 языках.

## 8. Решения (рекомендация первой)

1. **Новые поля ответов — `.optional()`, а не `.default(...)`.** BFF собирается без правок: он строит ответы по
   выходному типу, и `.default` сделал бы `translations` / `chat` обязательными. А отсутствие поля честно говорит
   клиенту «сервер этого ещё не умеет». Б — `.default([])` / `.default(null)`, как `deletedIds`: тогда BFF не
   перейдёт на v0.31.0 без кода задач 3 и 5.
2. **Согласие и переключатель — отдельный маршрут `PATCH /v1/me/chat-settings`, ответ `ProfileResponse`.**
   Б — поля в `PATCH /v1/me`. Б опасен: BFF, перешедший на v0.31.0 раньше задачи 3, примет новые поля строгой
   схемой и **молча ничего не запишет**. Новый маршрут на таком сервере даёт 404.
3. **Подтверждение 18+ (решение 10) — не в этой задаче.** Оно про вход, а не про чат. Отдельный шаг контрактов —
   у координатора.
