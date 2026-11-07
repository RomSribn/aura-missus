# AURAT-0169-004 — context

Код (`slave-2/master` @ `dc98590`) — ground truth:

- `shared/api/bff/http-client.ts` `performRequest` — один путь для `bffRequest` и `bffPublicRequest`; `upload.ts` `send` —
  свой `ReactNativeBlobUtil.fetch`. В путях уже бывает query: `tarot-api.ts` (`?tz=`), `chat-api.ts` (`after`, `deletedFrom`,
  `limit`). `URLSearchParams` в RN неполный — склеивать строкой.
- `shared/lib/i18n/start.ts`: `boot` читает выбор (`language-store.ts`, Documents) и `resolveLanguage({enabled, stored,
  system})` до React; `currentLanguage()` (псевдоязык → `en`); `chooseLanguage` применяет язык напрямую.
  `app/i18n/start.ts` `startAppI18n()` — из `index.js`, до регистрации приложения и headless-обработчиков пушей.
- `entities/campaign`: `parse-app-config.ts` (по частям, `type AppConfig = AppConfigResponse`, `NO_CAMPAIGN`),
  `config-cache.ts` (сырой ответ в Caches), `campaign-store.ts` (hydrate из кэша → refresh раз в минуту / на foreground),
  `use-app-config-sync` — в `app/index.tsx`. Public API slice не отдаёт store.
- `features/app-language`: `SHEET_LANGUAGES`, `languageOptions(onScreen, system, deviceLabel)`, `useLanguageSheet`.
- `shared/config/languages.ts`: свой `LANGUAGES` (тот же набор и порядок, что `aura-contracts/src/language.ts` v0.28),
  `SOURCE_LANGUAGE = 'en' satisfies Language` (литерал — нужен `TranslatedLanguage`; в контрактах он типа `Language`,
  поэтому реэкспорт из контрактов сломал бы типы → свой список + тест на совпадение).
- Таро: `entities/tarot/model/daily-card-store.ts` держит карту в памяти, `load()` no-op при `ready`; `TarotCard.name` —
  «English name» в v0.27. Фразы `daily-card` `bridge.title` / `draft` во всех 23 языках уже ставят имя отдельно там,
  где падежи (cs/sk/pl/lt/lv/hr/sl/bg/el/fi/et/ro — «karta {{card}}», hu — «ez a kártya: {{card}}»); риск — de `draft`
  («Ich habe heute {{card}} gezogen» → «Der Turm» в аккузативе), зависит от того, с артиклем ли имена в `AURAT-0171`.
  Home `DailyCardBanner` ставит имя заголовком — отдельно.
- Чат: `ChatProvider.syncThread` — дельта по `after`; `mergeServerMessages` добавляет только новые id — уже показанная
  карта расклада на смену языка не обновится. `features/chat/**`, `features/tarot-spread/**` — в работе у `AURAT-0167`.
- `Message.marker`: `HistoryResponse.parse` (zod strip) выбросит поле, пока пин — `v0.27.0`. Маркер читается только после
  перехода на тег `v0.28.0`.

Противоречий между заглушкой и кодом нет. Уточнение к заглушке: `app-config` публичный и одинаковый для всех — `lang` в
нём сейчас серверу не нужен, но строка 011 (сезонные тексты на языке пользователя) его потребует; единое правило «каждый
JSON-запрос» проще исключений.
