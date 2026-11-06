# AURAT-0168-007 — spec v2: язык на сервере — контракты v0.28.0 + BFF

Дата: 2026-11-06 · Status: **done** 2026-11-06 (`013-approved.md`) — контракт `v0.28.0` выпущен, BFF в develop `c24d55c`
Заменяет `005-spec.md`: учтены решения владельца и 11 замечаний ревью (`006-review.md`).
Фича: `AURAF-0023` строка 009. Основа для `AURAT-0169` / `0170` / `0171`.

## Что получится

- Приложение и веб шлют `?lang=<код>` в JSON-запросах к BFF и в загрузке файлов; BFF понимает его одним способом.
  Не в адресах картинок и вложений (`/v1/attachments/:id`, `/v1/avatars/:id` отдаются с `immutable`, адрес — ключ
  кэша у клиента) и не в сокете.
- Маркер сессии приходит данными: `Message.marker` — клиент переводит его сам; английский `content` остаётся для
  старых сборок.
- Язык можно выключить с сервера: `DISABLED_LANGUAGES` → `disabledLanguages` в `/v1/app-config`, и сервер сам
  перестаёт отвечать на выключенном языке.
- Язык клиента для чаттеров — **отложен** (решение владельца, §5).

## 1. Контракты `v0.28.0` (`aura-contracts`)

Только добавления: ответ `v0.27` разбирается новым клиентом, ответ `v0.28` — старым.

**Новый модуль `language.ts`** (экспорт — ровно эти четыре имени + `SOURCE_LANGUAGE`):
- `LANGUAGES = ['en', 'bg', 'cs', 'da', 'de', 'el', 'es', 'et', 'fi', 'fr', 'ga', 'hr', 'hu', 'it', 'lt', 'lv', 'mt',
  'nl', 'pl', 'pt', 'ro', 'sk', 'sl', 'sv'] as const` — набор и порядок как в `shared/config/languages.ts` приложения
  и веба; `type Language`;
- `SOURCE_LANGUAGE = 'en'` — то же имя, что у клиентов;
- `isLanguage(value: unknown): value is Language` — точное совпадение, без нормализации (`DE`, `de-AT` — не язык);
- `LANGUAGE_QUERY_PARAM = 'lang'`.
- Помощника «неизвестное → en» в контрактах **нет** — у приложения уже есть свой `resolveLanguage({enabled, stored,
  system})`; серверный живёт в BFF (§2).

**`chat.ts` — `Message.marker`:**
- `MESSAGE_MARKERS = ['session_started', 'session_finished'] as const`, `type MessageMarker`;
- `marker: z.string().min(1).optional()` — строка, не `z.enum`: новый маркер не роняет разбор у старого клиента.
  Отсутствует (не `null`) на обычном сообщении — как `spread` / `sessionInvite`.
- Значения с пространством имён `session_*`, а не клиентские `started` / `finished`: поле общее для системных
  сообщений и переживёт маркеры не про сессию. Клиенты сопоставляют значение со своим ключом типизированной таблицей
  (`map-message.ts`); неизвестное значение → рисуют `content`.
- Документировать в контракте: `content` — английский текст, не только у маркеров. Сообщение чаттера из одного
  токена получает заглушку «Choose a card» (`spread`) / «Continue this reading privately» (`sessionInvite`) —
  клиент, понимающий `spread` / `sessionInvite`, показывает своё переведённое слово, а не `content`. Флага не нужно.

**`app-config.ts`:**
- `AppConfigDisabledLanguages = z.array(z.string())` — отдельная схема части (оба клиента разбирают конфиг по частям:
  app `parse-app-config.ts:36-46`, web `parse-app-config.ts:34-41`); строки, не `Language`: код, неизвестный старому
  клиенту, не роняет конфиг;
- `AppConfigResponse.disabledLanguages: AppConfigDisabledLanguages.default([])`. Сервер шлёт только коды из
  `LANGUAGES`, никогда `en`. Правило клиента: выбранный или системный язык в списке → английский.

Выпуск: версия в `package.json`, абзац «`v0.28.0` adds…» и строка `language` в таблице модулей README, коммит
«Язык на проводе (v0.28.0)», тег. **Пуш `main` + тега — с отдельного одобрения владельца.**

## 2. BFF: язык запроса — **реализует `AURAT-0171`** (решение владельца, `008`)

Устройство ниже — обязательное для `0171`; в этой задаче кода резолвера нет (правило 8: без потребителя это мёртвый
код). `DISABLED_LANGUAGES` из §4 и `LANGUAGES` / `isLanguage` из контрактов — отсюда.


- **Чистое ядро** — `src/common/language/request-language.ts`:
  `languageFromQuery(raw: unknown, disabled: readonly Language[]): Language | null` — код из `LANGUAGES`, не
  выключенный; иначе `null` (нет параметра, неизвестный код, `DE`, массив из `?lang=de&lang=fr`, выключенный).
  `languageOrDefault(language: Language | null): Language` → `SOURCE_LANGUAGE` при `null`.
- **Обёртка** — `@RequestLanguage()` = `Query(LANGUAGE_QUERY_PARAM, RequestLanguagePipe)`; пайп `@Injectable`, берёт
  провалидированный `DISABLED_LANGUAGES` из `ConfigService` (модуль конфига глобальный) и зовёт `languageFromQuery`.
  `@ApiLanguageQuery()` — одно описание параметра для Swagger.
- Выключенный язык → `null` → ответ на английском. Так выключатель работает и для клиентов со старым кэшем конфига,
  а не только у тех, кто успел его перечитать.
- `Accept-Language` не читается (iOS шлёт его сам из языка устройства — `AURAI-0010` §6).
- Почему не глобальный хук: язык нужен трём маршрутам, а хук — неявная связь и работа на каждом запросе. Остальным
  маршрутам `lang` не мешает: схемы query нестрогие; `.strict()` — только у тел (`ProfilePatchRequest`,
  `contracts profile.ts:224`; пресет кампании), на query не влияет.
- Первые потребители — маршруты `AURAT-0171`:
  - `GET /v1/tarot/daily`;
  - `POST /v1/tarot/spread/:messageId/pick`;
  - `GET /v1/advisors/:advisorId/messages` — карта открытого расклада в истории (`chat.service.ts:137`, `toSpreadDto`).
- **Почему сокету язык не нужен** (инвариант для `0171`): в сокет уходят только новые вставки (`fanOut` лишь при
  `inserted`, `chat.service.ts:251-258, 277-283`), а у только что выложенного расклада карты ещё нет. В `0171`
  `toDto` получит параметр языка; клиенты перезапрашивают историю при смене языка.

## 3. BFF: `Message.marker`

- Тексты переезжают из `sessions.service.ts:83-86` в `src/modules/chat/session-markers.ts`:
  `SESSION_MARKER_CONTENT: Record<MessageMarker, string>` и чистая `markerOf(direction, content)`. **Формулировки не
  меняются** (`AURAT-0167` и веб узнают их по точному совпадению); `SessionsService.announce` берёт текст оттуда.
- `toDto` (`chat.service.ts:337`) — единственное место, где строка становится DTO (история, сокет, ответ отправки):
  `marker` есть, если `direction === 'system'` и `content` точно равен тексту маркера. Вся история — без миграции;
  удалённое (`content: ''`) — без маркера; пользователь, набравший «Your session has started», — без маркера.
- `messageOpenApi` — свойство `marker`.

## 4. BFF: `disabledLanguages` (решение владельца: env)

- `DISABLED_LANGUAGES` — коды через запятую, по умолчанию пусто; trim + нижний регистр, как у других списков
  (`env.schema.ts:135-143`). Проверка при старте: каждый код из `LANGUAGES`, `en` запрещён; дубли схлопываются,
  порядок — как в `LANGUAGES`. Отказ при старте = провал деплоя, старая версия продолжает работать
  (`docker-entrypoint.sh`) — как с любой переменной.
- `buildAppConfig` получает список в контексте; поле в ответе всегда (`[]`, если пусто). ETag — от тела, меняется
  сам. Кэш ответа — 30 с на реплику + `invalidate()` (`app-config.service.ts:13, :64`); смена env — это перезапуск,
  так что новый список виден сразу после деплоя.
- `appConfigResponseOpenApi` (`src/contracts/openapi.ts:814`) — поле `disabledLanguages`.

## 5. Язык клиента для чаттеров — ОТЛОЖЕНО

Решение владельца: не делаем сейчас; вернуться после решения 8 (на каком языке отвечают чаттеры). `users.language`
и атрибут Chatwoot не появляются. Набросок из `005` §5 (атрибут контакта `client_language` через очередь
`contact-name`; Chatwoot сливает атрибуты контакта — `contacts_controller.rb:177-193`) и замечания ревью к нему —
чтобы не потерять:
- задача `contact-name` пропускает пользователей без имени (`profile.service.ts:68-72`) — язык не дойдёт;
- Prisma `not` не запишет первый язык, пока поле `NULL` (сравнение с `NULL`) — нужен явный `OR language IS NULL`;
- запись языка не должна ронять отправку сообщения;
- `?lang` всё равно попадает в лог запросов (`http-logger.options.ts:38-44`, `url` / `query`);
- при двух устройствах сохраняется язык последнего;
- плюс из `005`: строка в политике конфиденциальности, пункт NOT in scope `AURAF-0023`, `CLEARED_PROFILE`.

## 6. Пуши

Работы нет: FCM шлёт только `{type: 'message.new', advisorId}`, текст рисует устройство.

## Передача клиентам (0169 / 0170)

- `?lang` — JSON-запросы и загрузка; не адреса картинок / вложений, не сокет.
- `marker`: таблица `session_started → started`, `session_finished → finished`; неизвестное → `content`; маркер
  важнее текста, совпадение текста — запасной путь для старых сообщений.
- При `spread` / `sessionInvite` — своё переведённое слово, не `content`.
- `disabledLanguages` — разбирать частью (`AppConfigDisabledLanguages`). В приложении после перехода на v0.28
  проверка типов ломается в трёх местах (`type AppConfig = AppConfigResponse`): `NO_CAMPAIGN`
  (`parse-app-config.ts:13-17`), возврат `parseAppConfig` (`:41-48`) и `activeParts`
  (`entities/campaign/lib/active-parts.ts:13-17`) — он должен пропускать `disabledLanguages` как есть, а не
  сбрасывать (поле не кампания и не истекает по `endsAt`). Дополнено ревью кода, `010`.
- `SOURCE_LANGUAGE` в контрактах — литерал `'en'` (`satisfies Language`), так что
  `Exclude<Language, typeof SOURCE_LANGUAGE>` у клиентов работает и с константой из контрактов.

## Проверки и порядок выпуска

1. Контракты: ветка → правки → `npm run typecheck && npm run build` → `main` + тег `v0.28.0` → **пуш с одобрения
   владельца**. До тега BFF проверяется локальной копией `dist` (в коммит не попадает).
2. BFF перепинивается на `github:RomSribn/aura-contracts#v0.28.0` (`npm install`, lock — с настоящим sha; никаких
   `file:` / `dist` в коммите).
3. Unit: `markerOf` и `toDto` (system / user / удалённое / чужой текст); `announce` пишет те же тексты;
   env `DISABLED_LANGUAGES` (пусто, пробелы и регистр, мусор, `en`, дубли); `buildAppConfig` и `etagOf` с полем;
   контрактные спеки `app-config` и `message`.
4. `npm run lint`, `npm run typecheck`, `npm run build`, `npm test` → ревью владельца → гейт мёржа.
5. В маноре после мёржа: `GET /v1/app-config` с `DISABLED_LANGUAGES=mt`; история с маркерами.
6. **После одобрения спеки контракт заморожен**: любое изменение — `v0.28.1` и сообщение в 0169 / 0170 / 0171.

## Не здесь

Резолвер `lang` с тестами (`languageFromQuery` — нет, неизвестный, `DE`, массив, выключенный `mt` при
`DISABLED_LANGUAGES=mt` → `null`; `languageOrDefault`), колода таро на языке пользователя и подключение `@RequestLanguage()` к маршрутам — `AURAT-0171`; клиенты —
`AURAT-0169` / `0170`; персоны и сезонные тексты — строка 011; язык для чаттеров — §5.
