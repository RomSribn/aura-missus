# AURAT-0168-001 — initial (заглушка)

Дата: 2026-11-06
Репо: `aura-bff-manor` (BFF) + `aura-contracts` (минорная версия `v0.28.0`). Выдан из `aura-app-manor` (сессия
slave-1-9e), `AURAI-0010` §6 и Recommendation п. 5.
Фича: `AURAF-0023` строка 009 и атрибут языка для чаттеров (шаг 5 — серверная часть; v1 не блокирует).

## Что нужно

1. **Контракты `v0.28.0`:**
   - `LANGUAGES` — 24 кода: en + bg cs da de el es et fi fr ga hr hu it lt lv mt nl pl pt ro sk sl sv (тот же набор,
     что `shared/config/languages.ts` в приложении и вебе);
   - `lang` — необязательный query-параметр; неизвестное значение → `en`, не 400 (как `tz` у `GET /v1/tarot/daily`);
   - `Message.marker` — необязательное поле системного сообщения (например `session_started` / `session_finished`):
     строка со списком известных значений в константе (как `SESSION_DISCOUNT_KINDS`, `SEASON_EFFECTS`), не строгий
     `z.enum` — новое значение не должно ронять разбор сообщения у старого клиента. `content` остаётся английским
     текстом — для старых клиентов;
   - `AppConfigResponse.disabledLanguages: string[]`, по умолчанию `[]` — ответ v0.27 по-прежнему разбирается.
2. **BFF:**
   - резолвер `lang` — одно место для всех маршрутов (Fastify `onRequest` или interceptor) либо схема на маршрутах —
     решить в спеке. `Accept-Language` не читать: iOS шлёт его сам из языка устройства (`AURAI-0010` §6);
   - `marker` в `toDto` для всех SYSTEM-сообщений по точному `MARKER_CONTENT` — вся история без миграции;
     удалённые (`deletedAt`, пустой `content`) — без маркера. Формулировки маркеров не менять: приложение
     (`AURAT-0167`) распознаёт их по точному совпадению;
   - `disabledLanguages` в `/v1/app-config`: env (меняется передеплоем) или настройка в бэкофисе — решить в спеке.
     ETag считается от тела и покроет поле сам; если из базы — `invalidate()` при изменении;
   - язык для чаттеров: атрибут разговора в Chatwoot (`client_language` или как решит спека) — откуда BFF знает язык
     (последний `lang` пользователя → `users.language`?), когда обновляется. `setConversationCustomAttributes`
     заменяет всю карту — писать полный набор. Хранение языка пользователя на сервере — строка в политике
     конфиденциальности (за владельцем) и пункт NOT in scope фичи «язык на сервере в v1»: в спеке — вопрос владельцу,
     делать ли атрибут сейчас.
3. Пуши — работы нет: FCM шлёт только `{type: 'message.new', advisorId}`, текст рисует устройство.

Не здесь: колода таро на языке пользователя — `AURAT-0171` (берёт `lang` и `LANGUAGES` отсюда); клиенты —
`AURAT-0169` (приложение), `AURAT-0170` (веб); персоны и сезонные тексты — строка 011, ждут решения 8 владельца
(на каком языке отвечают чаттеры).

## Карта кода (исследование координатора 2026-11-06, read-only — перепроверить)

- Контракты: `chat.ts:19` `MessageDirection`, `:94-175` `Message` (по образцу `spread` / `sessionInvite` — поле
  отсутствует, а не `null`); `app-config.ts:147-153` `AppConfigResponse`, шапка `:5-20` (публичный, ETag, 304);
  выпуск — версия в `package.json`, абзац «vX.Y.0 adds…» в README, коммит «… на проводе (v0.28.0)», тег; потребители
  пинят `github:RomSribn/aura-contracts#v0.27.0`.
- BFF (NestJS 11 + Fastify): `src/app.setup.ts:17-55`, единственный глобальный хук — `APP_GUARD`
  (`src/app.module.ts:62`); query валидируется на маршруте `ZodValidationPipe`; образец мягкого параметра — `tz`
  (`tarot.controller.ts:47-56`, `tarot.service.ts:164`).
- App-config: `src/modules/campaigns/app-config.controller.ts:22-41` (ETag, `max-age=60`),
  `app-config.service.ts:37-67` (кэш 30 с, `invalidate()`), `app-config.builder.ts:24-57`.
- Маркеры: `MARKER_CONTENT` — `src/modules/sessions/sessions.service.ts:83-86`; запись — `announce`
  (`:586-602`) → `chat.ingestSystemMarker` (`chat/chat.service.ts:234-260`); DTO — `toDto` (`chat.service.ts:337-376`).
- Chatwoot: атрибуты разговора — `chatwoot/desk-attributes.ts:139-163`, определения `:49+` (`npm run desk:setup`);
  запись — `provisioning.service.ts:58`, `chatwoot-messaging.service.ts:117-128`; у `User` нет поля языка
  (`schema.prisma:14-59`).
- Тесты рядом: `app-config.*.spec.ts`, `sessions.service.spec.ts:1467-1495`, `chat.service.spec.ts:676`,
  `desk-attributes.spec.ts`, `src/contracts/*.spec.ts`.

Запущена 2026-11-06 в `aura-bff-manor` slave-1.

## Слова владельца (дословно, 2026-11-06)

> «давай теперь шаг 5 серверный, потом по таро, надписи на самих картинках оставляем как есть»

Ответ на список «что осталось по переводам»: п. 3 «Шаг 5 — сервер», п. 4 «Колода таро на языке пользователя».

## Контекст слота

- Манор: `aura-bff-manor`, слот `slave-1`, ветка `feature/AURAT-0168-bff-i18n-lang-marker` (master `aura-bff` от
  `develop` @ `c8d78cf`, missus — от `origin/master` на момент запуска).
- Контракты: `v0.27.0` @ `8699e32` → этот слот выпускает `v0.28.0`.
- В маноре BFF `node_modules/@aura/contracts` устарел (0.23.0 при пине v0.27.0) — `npm ci` перед сборкой и проверками.
- Дальше: `AURAT-0169` / `0170` / `0171` запускаются, когда владелец одобрит спеку этой задачи (контракт v0.28) —
  после одобрения напиши координатору, сессия `slave-1-9e` в `aura-app-manor` (SendMessage).
- ID здесь не минтятся (выданы в `aura-app-manor`).
