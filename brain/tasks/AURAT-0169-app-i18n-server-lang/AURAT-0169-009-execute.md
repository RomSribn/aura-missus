# AURAT-0169-009 — execute: этапы A + B, пин на тег `v0.28.0` (часть C)

Дата: 2026-11-06. Слот `slave-2`, ветка `feature/AURAT-0169-app-i18n-server-lang`. Не закоммичено — staged на ревью.

## Сделано

**A — `lang` в запросах.**
- `shared/api/bff/language-query.ts` (новый): `withLanguage(path, language)` — `?` / `&`, строкой; параметр — `LANGUAGE_QUERY_PARAM` из контрактов.
- `http-client.ts` `performRequest`, `upload.ts` `send`: `await i18nReady()`, затем `withLanguage(path, currentLanguage())`.
  Покрывает `bffRequest`, `bffPublicRequest` (и `/v1/app-config`), повтор после 401, загрузку. Вложения, аватар, сокет — без `lang`.

**B — `disabledLanguages`.**
- `shared/lib/i18n/start.ts`: на уровне модуля `wanted` (язык без учёта выключенных), `storedChoice`, `disabled`.
  `startI18n(all, { readDisabledLanguages })` — ждётся только при `I18N_ENABLED`, ошибка → `[]`.
  Новое: `applyDisabledLanguages`, `currentLanguageChoice`, `disabledLanguages`, `subscribeDisabledLanguages`.
  `chooseLanguage` хранит выбор в памяти и применяет через фильтр. `ready` резолвится и при сбое старта (сеть ждёт его).
- `shared/lib/i18n/resolve-language.ts`: `disabledLanguagesOf` (коды сборки, без `en`, порядок `LANGUAGES`),
  `allowedLanguage`. Отступление от буквы спеки: `resolveLanguage` не получил параметр `disabled` — фильтр
  накладывается отдельно (`allowedLanguage(wanted, disabled)`), потому что «выбранный язык без учёта выключенных»
  нужен сам по себе: к нему приложение возвращается, когда язык включат обратно.
- `shared/lib/i18n/use-disabled-languages.ts` (новый): `useDisabledLanguages()`.
- `entities/campaign`: `parse-app-config.ts` — часть `disabledLanguages` (контрактная `AppConfigDisabledLanguages`), `NO_CAMPAIGN`
  с `[]`; тип `CampaignParts` — в `active-parts`, `use-campaign`, `ticket-content`, `hero-content`, `prefetch-art`.
  `model/disabled-languages.ts` (новый): `readCachedDisabledLanguages`, `useConfigDisabledLanguages` (null до hydrate).
- `app/i18n/start.ts` — передаёт `readCachedDisabledLanguages`; `app/i18n/use-disabled-languages-sync.ts` (новый) —
  в `app/index.tsx` рядом с `useAppConfigSync`; `app/i18n/dev-menu.ts` — «next language» пропускает выключенные.
- `features/app-language`: `languageOptions(…, disabled)` — без выключенных строк, подпись «Язык устройства» — язык,
  который откроется; `useLanguageSheet` — отметка по `currentLanguageChoice()`.

**C, первая часть — тег.** `@aura/contracts` → `github:RomSribn/aura-contracts#v0.28.0` (lock: `7055dc9`, «Язык на
проводе (v0.28.0)»). Локальные `AppConfigDisabledLanguages` / `LANGUAGE_QUERY_PARAM` заменены импортом; `AppConfig =
AppConfigResponse`. Тест `shared/config/__tests__/languages.test.ts`: `LANGUAGES` и `SOURCE_LANGUAGE` === контракты.

## Тесты (новые / дополненные)

`language-query.test.ts`; `http-client.test.ts` (`lang` после query, публичный маршрут, псевдоязык → `en`); `upload.test.ts`;
`attachment-cache.test.ts` (адрес без `lang`); `shared/lib/i18n/__tests__/disabled-languages.test.ts` (12: свежий процесс с
флагом — выключенный системный / выбранный, кэш не читается, флаг выключен — не ждём; на ходу — выключили / включили,
тот же список, fr→de, «Язык устройства», псевдоязык, подписчики); `parse-app-config.test.ts` (поле); `campaign/model/__tests__/
disabled-languages.test.tsx` (кэш, null до hydrate); `app/i18n/__tests__/use-disabled-languages-sync.test.tsx`; `dev-menu.test.ts`;
`LanguageSheet.test.tsx` (нет строки, сценарии (a) и (b)); `languages.test.ts`.

## Проверки

`npx tsc --noEmit` — чисто; `npm run lint` — чисто; `npx jest --no-watchman` — 199 наборов, 2643 теста, все зелёные
(в `package.json` нет скрипта `typecheck` — запускается `tsc`). Предупреждения `● Console` — те же 13 наборов, что на `develop`
(сверено прогоном базы).

## Осталось

- C, вторая часть — `Message.marker` в `map-message.ts`: ждёт мёржа `AURAT-0167` (на `dc98590` её ещё нет).
- D — таро: ждёт мёржа `0167`; дополнения координатора — `010`.
