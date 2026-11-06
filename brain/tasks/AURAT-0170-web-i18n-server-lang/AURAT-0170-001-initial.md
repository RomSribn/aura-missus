# AURAT-0170-001 — initial (заглушка)

Дата: 2026-11-06
Репо: `aura-web-manor` (веб). Выдан из `aura-app-manor` (сессия slave-1-9e), `AURAI-0010` §6.
Фича: `AURAF-0023` строки 009 и 010 (веб — тот же контракт; на вебе i18n с `AURAT-0101-010`). Контракт `AURAT-0168`
(`v0.28.0`) заморожен — спека одобрена 2026-11-06 (`007-spec-v2`, `008-approval`; полный текст —
`/Volumes/Work/personal/ai-manors/aura-bff-manor/project/slave-1/missus/brain/tasks/AURAT-0168-bff-i18n-lang-marker/AURAT-0168-007-spec-v2.md`,
в missus пока не закоммичен). Тега на GitHub ещё нет: до тега — локальный тип по спеке, потом переключение на тег.

## Передача от сервера (`AURAT-0168-007` § «Передача клиентам»)

- `?lang` — JSON-запросы и загрузка; не адреса картинок и вложений, не сокет. Сервер начнёт читать `lang` с `AURAT-0171`;
  слать раньше безопасно — схемы query нестрогие.
- `Message.marker` — строка; `MESSAGE_MARKERS = ['session_started', 'session_finished']`. Таблица
  `session_started → started`, `session_finished → finished` к ключам `message:marker.*`; неизвестное → `content`;
  маркер важнее текста, совпадение текста — запасной путь для старых сообщений.
- При `spread` / `sessionInvite` — своё переведённое слово, не `content`.
- `disabledLanguages` — частью `AppConfigDisabledLanguages` (`z.array(z.string())`), в ответе `.default([])`; только
  коды из `LANGUAGES`, никогда `en`.
- Контракты: `LANGUAGES`, `type Language`, `SOURCE_LANGUAGE`, `isLanguage` (точное совпадение), `LANGUAGE_QUERY_PARAM`.

## Что нужно

1. **`lang` в каждом JSON-запросе к BFF** — язык интерфейса: `shared/api/base-query.ts` (`performRequest`, ~`:83` —
   весь RTK Query) и загрузка файла (`shared/api/bff-file.ts`, `fetchWith`, ~`:14-20`). **Не** в скачивание файлов и
   картинок и не в сокет `shared/api/ws-client.ts:97` (спека `AURAT-0168` §2; ревью спеки 2026-11-06). Хелпера текущего языка в `shared/i18n` нет — добавить (`i18next.resolvedLanguage`, как в
   `pages/me/model/use-languages.ts:26`). Склеивать через URLSearchParams (`entities/tarot/api/daily-card-api.ts:13`
   уже так делает с `tz`).
2. **`disabledLanguages`** из `/v1/app-config`: разбор в `entities/season/lib/parse-app-config.ts`. Язык выбирается до
   конфига (`app/main.tsx:22`, `startLanguage()` в `shared/i18n/language-choice.ts:33`) — нужен переход на английский
   после прихода конфига, если выбранный язык выключен. Выбор языка — `pages/me/model/use-languages.ts:24-44`:
   выключенные не предлагать.
3. **`Message.marker`**: `entities/message/lib/map-message.ts` (тон по регулярке `/\bstarted\b/i`) и
   `entities/message/ui/system-line.tsx` — `marker` важнее текста; текст — запасной путь для старых сообщений.
   Переводы маркеров — `message:marker.*` (их использует и приложение в `AURAT-0167`). Превью в списке чатов:
   у сообщения с `spread` / `sessionInvite` показывать своё переведённое слово, а не `content` — сервер пишет туда
   английские «Choose a card» / «Continue this reading privately» (ревью спеки 0168) — проверить, как веб делает
   сейчас.
4. **Таро на языке пользователя** (`AURAT-0171`): строки с именем карты — `pages/daily/config/locales/en.ts`
   (`bridge.title`, `draft`), `features/tarot-pick/config/locales/en.ts` (`youChose`, `open`) — имя должно стоять
   отдельно (падежи); карточка дня перезапрашивается при смене языка.

Запущена 2026-11-06 в `aura-web-manor` slave-1 — после одобрения спеки `AURAT-0168`.

## Слова владельца (дословно, 2026-11-06)

> «давай теперь шаг 5 серверный, потом по таро, надписи на самих картинках оставляем как есть»

## Контекст слота

Манор `aura-web-manor`, слот `slave-1`, ветка `feature/AURAT-0170-web-i18n-server-lang` от `develop` @ `88dd553`.
ID здесь не минтятся (выданы в `aura-app-manor`).
