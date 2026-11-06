# AURAT-0169-001 — initial (заглушка)

Дата: 2026-11-06
Репо: `aura-app-manor` (приложение). Выдан из `aura-app-manor` (сессия slave-1-9e), `AURAI-0010` §6.
Фича: `AURAF-0023` строки 009 и 010 (клиентская часть шага 5). Ждёт контракт `AURAT-0168` (`v0.28.0`): до тега —
локальный тип по одобренной спеке 0168, потом переключение на тег.

## Что нужно

1. **`lang` в каждом запросе к BFF** — язык интерфейса (`currentLanguage()` из `shared/lib/i18n`, псевдоязык → `en`):
   `shared/api/bff/http-client.ts` (`performRequest`, ~`:58` — покрывает `bffRequest` и `bffPublicRequest`),
   `upload.ts` (~`:73`), `attachment-cache.ts:89`, `entities/user/api/avatar-api.ts:67`; сокет `ws-client.ts:69` — если
   так решит спека 0168. Склеивать через URL / URLSearchParams: в путях уже бывает query (`tarot-api.ts:20`, `?tz=`).
2. **`disabledLanguages`** из `/v1/app-config`: разбор в `entities/campaign/api/parse-app-config.ts` (кэш-файл уже
   есть). i18n стартует раньше React и app-config (`start.ts` → `resolveLanguage`), а `shared` не может импортировать
   `entities/campaign` — либо кэшированный список в `boot`, либо перепроверка из app-слоя после обновления конфига
   с переходом на английский. Правило резолвера: выбранный или системный язык выключен → английский. Лист языка
   (`features/app-language`) — выключенные не показывать или показывать неактивными (решить в спеке).
   `LANGUAGES` из контрактов — сверить со своим списком (тест на совпадение) или брать оттуда.
3. **`Message.marker`** — только после мёржа `AURAT-0167` (там маркеры переводятся по точному совпадению в
   `features/chat/lib/map-message.ts`): поле `marker` важнее текста, совпадение текста — запасной путь для старых
   сообщений.
4. **Таро на языке пользователя** (`AURAT-0171`): когда сервер начнёт присылать переведённые имена, проверить строки с
   именем карты в `screens/daily-card` («Wondering what {{card}} means for you?», черновик «I drew {{card}} today…»)
   и `screens/home` — имя должно стоять отдельно (падежи); карточка дня перезапрашивается при смене языка
   (`daily-card-store` держит её в памяти). «You chose {{card}}» в `tarot-spread` — в `AURAT-0167`.

Не здесь: перевод маркеров по точному совпадению и строки `tarot-spread` — `AURAT-0167`.

Конфликт с `AURAT-0167` (идёт в slave-0): `features/chat/lib/map-message.ts`, `features/chat/model/types.ts`,
`screens/chat-thread/ui/{SessionMarker,MessageBubble,SpreadMessage}.tsx`, `screens/chats/lib/preview.ts`,
`features/tarot-spread/**` — трогать после её мёржа. Без конфликта: `shared/api/bff/*`, `entities/user/api`,
`entities/tarot/api`, `shared/lib/i18n/{start,resolve-language}.ts`, `entities/campaign/**`,
`features/app-language/**`, `app/index.tsx`, `package.json`, `screens/daily-card/**`, `screens/home/**`.

Запуск — после одобрения владельцем спеки `AURAT-0168`.

## Слова владельца (дословно, 2026-11-06)

> «давай теперь шаг 5 серверный, потом по таро, надписи на самих картинках оставляем как есть»

## Контекст слота

Заполняется при запуске: манор `aura-app-manor`, свободный слот, ветка `feature/AURAT-0169-app-i18n-server-lang` от
`develop`.
