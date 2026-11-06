# AURAT-0170-001 — initial (заглушка)

Дата: 2026-11-06
Репо: `aura-web-manor` (веб). Выдан из `aura-app-manor` (сессия slave-1-9e), `AURAI-0010` §6.
Фича: `AURAF-0023` строки 009 и 010 (веб — тот же контракт; на вебе i18n с `AURAT-0101-010`). Ждёт контракт
`AURAT-0168` (`v0.28.0`): до тега — локальный тип по одобренной спеке 0168.

## Что нужно

1. **`lang` в каждом запросе к BFF** — язык интерфейса: `shared/api/base-query.ts` (`performRequest`, ~`:83` — весь
   RTK Query), `shared/api/bff-file.ts` (`fetchWith`, ~`:14-20`), сокет `shared/api/ws-client.ts:97` — если так решит
   спека 0168. Хелпера текущего языка в `shared/i18n` нет — добавить (`i18next.resolvedLanguage`, как в
   `pages/me/model/use-languages.ts:26`). Склеивать через URLSearchParams (`entities/tarot/api/daily-card-api.ts:13`
   уже так делает с `tz`).
2. **`disabledLanguages`** из `/v1/app-config`: разбор в `entities/season/lib/parse-app-config.ts`. Язык выбирается до
   конфига (`app/main.tsx:22`, `startLanguage()` в `shared/i18n/language-choice.ts:33`) — нужен переход на английский
   после прихода конфига, если выбранный язык выключен. Выбор языка — `pages/me/model/use-languages.ts:24-44`:
   выключенные не предлагать.
3. **`Message.marker`**: `entities/message/lib/map-message.ts` (тон по регулярке `/\bstarted\b/i`) и
   `entities/message/ui/system-line.tsx` — `marker` важнее текста; текст — запасной путь для старых сообщений.
   Переводы маркеров — `message:marker.*` (их использует и приложение в `AURAT-0167`).
4. **Таро на языке пользователя** (`AURAT-0171`): строки с именем карты — `pages/daily/config/locales/en.ts`
   (`bridge.title`, `draft`), `features/tarot-pick/config/locales/en.ts` (`youChose`, `open`) — имя должно стоять
   отдельно (падежи); карточка дня перезапрашивается при смене языка.

Запуск — после одобрения владельцем спеки `AURAT-0168`.

## Слова владельца (дословно, 2026-11-06)

> «давай теперь шаг 5 серверный, потом по таро, надписи на самих картинках оставляем как есть»

## Контекст слота

Заполняется при запуске: манор `aura-web-manor`, свободный слот, ветка `feature/AURAT-0170-web-i18n-server-lang` от
`develop`. ID здесь не минтятся (выданы в `aura-app-manor`).
