# AURAT-0170-004 — context

Дата: 2026-11-06

## Источники
- Спека сервера `AURAT-0168-007-spec-v2.md` (bff-manor slave-1, не закоммичена) — передача клиентам.
- Контракты: `aura-contracts` ветка `feature/AURAT-0168-v0.28.0`, правки не закоммичены, тега нет. `src/language.ts` (`LANGUAGES`, `Language`, `SOURCE_LANGUAGE`, `isLanguage`, `LANGUAGE_QUERY_PARAM`), `chat.ts` (`MESSAGE_MARKERS`, `Message.marker`), `app-config.ts` (`AppConfigDisabledLanguages`, `disabledLanguages.default([])`).
- `AURAT-0169-001` (приложение, тот же шаг), `AURAT-0171-001` (колода на 23 языках, резолвер `?lang`), приложение `AURAT-0167` (slave-0): превью «Tarot spread» / «Private session invitation» с иконками `cards` / `cal`.

## Код веба (develop @ 88dd553)
- Транспорт: `shared/api/base-query.ts:76-96` `performRequest` — весь RTK Query; `shared/api/bff-file.ts:14-22` `fetchWith` — и скачивание (`fetchBffFile`), и загрузка (`sendBffFile`) → `lang` только в `sendBffFile`. Других `fetch` к BFF нет; сокет — `ws-client.ts:97`.
- Язык: `shared/i18n/language-choice.ts` (`startLanguage`, `chooseLanguage` — пишет в `localStorage`), свой `isLanguage` в двух файлах; хелпера «текущий язык» нет.
- app-config: `entities/season/lib/parse-app-config.ts` — разбор по частям из сырого тела (поэтому `disabledLanguages` читается своей схемой части); `useSeason` — единственный читатель; `app/root.tsx` — app-уровневые хуки (`SeasonDocument`).
- Профиль → Язык: `pages/me/model/use-languages.ts` — все `LANGUAGES`.
- Маркеры: `entities/message/lib/marker.ts` (`sessionMarkerOf` по точному тексту), `map-message.ts` (`toneOf` по `/\bstarted\b/i`), `ui/system-line.tsx`, `ui/message-preview.tsx`.
- Превью: `entities/message/lib/preview.ts` — у `spread` / `sessionInvite` сейчас показывается `content`, т.е. английские «Choose a card» / «Continue this reading privately» на любом языке. Тред рисует их своими компонентами — там уже переведено.
- Таро: имя карты внутри фраз — `daily-page:bridge.title`, `daily-page:draft`, `tarot-pick:youChose`, `tarot-pick:open` (24 языка). Остальные места рисуют имя отдельно (`card-reveal`, `tarot-card-face`, `daily-banner`, диалог карты).
- Кэш: карта дня — `getDailyCard` (ключ — `tz`), меняется язык → не перечитывается. История — `getThread` с вклеенными догрузками; `refreshThread` перечитывает новейшую страницу (`refreshServerMessages`), не трогая локальные копии.

## Важное
- `Message.parse` по схеме v0.27 **выбрасывает** `marker` (zod `object` режет лишние ключи) → маркер не прочитать до перехода на v0.28.0; локальный тип тут не помогает. `disabledLanguages` читается и до тега (своя схема части), `lang` не зависит от контракта, кроме имени параметра.
