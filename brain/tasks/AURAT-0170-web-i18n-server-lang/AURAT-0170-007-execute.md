# AURAT-0170-007 — execute

Дата: 2026-11-06 · Ветка `feature/AURAT-0170-web-i18n-server-lang` (master), не закоммичено — на ревью владельца.

## Контракты
- Тег `v0.28.0` вышел во время работы (координатор: `main 7055dc9`). `package.json` / lock → `github:RomSribn/aura-contracts#v0.28.0`, lock `resolved` = `7055dc9…`. Отдельным коммитом (правило 6).

## Сделано
1. **`?lang`** — `shared/i18n/current-language.ts` (`currentLanguage()`), `shared/api/with-language.ts` (`URLSearchParams`, `LANGUAGE_QUERY_PARAM` из контрактов); `base-query.ts` (весь RTK Query, и публичные — `/v1/app-config` тоже), `bff-file.ts` `sendBffFile`. Не в `fetchBffFile` и не в сокет.
2. **`disabledLanguages`** — `parse-app-config.ts` (часть `AppConfigDisabledLanguages` → только `LANGUAGES`, без `en`, без дублей; `NO_APP_CONFIG`, `liveAppConfig`); `entities/season` → `useDisabledLanguages`; `shared/i18n/language-choice.ts` — `effectiveLanguage`, `applyDisabledLanguages` (список в `localStorage` `aura.disabledLanguages`, выбор человека не трогается), `startLanguage` по запомненному списку; `app/language/use-language-guard.ts` + `<LanguageGuard />` в `app/root.tsx`; Профиль → Язык — выключенные скрыты. `isLanguage` / `SOURCE_LANGUAGE` — в `shared/config` (один на веб; был в двух файлах).
3. **Маркеры** — `lib/marker.ts` `markerOf(marker, content)` (типизированная таблица `Record<MessageMarker, SessionMarker>`, неизвестный → нет маркера, нет поля → точный текст); `ChatMessage.marker`; `map-message.ts` — тон от маркера (регулярка ушла); `system-line.tsx`, `message-preview.tsx` — по `marker`.
4. **Превью** — `spread` → `cards` + «Tarot spread», `sessionInvite` → `cal` + «Private session invitation» (`message:preview.spread/invite`, 24 языка — слова приложения `AURAT-0167`).
5. **Таро** — `daily-page:bridge.title` без имени, `daily-page:draft`, `tarot-pick:youChose`, `tarot-pick:open` — имя после двоеточия, 24 языка. Карта дня: `getDailyCard({ tz, language })` / `markDailyCardDrawn` — язык в ключе кэша. Лицо карты без картинки: `overflow-wrap: anywhere` (имена до 24 знаков, `AURAT-0171-009` «Длины»). Остальные места имени / `keywords` переносятся сами (нет `nowrap` / многоточий), две строки капса — без обрезки.

## Тесты
Новые: `with-language`, `bff-file` (загрузка с `lang`, файл — без), `base-query` (`lang=de`, публичный маршрут), `language-choice` (выключен → en, выбор сохраняется, возврат), `languages` (= контрактам), `parse-app-config`, `marker`, `map-message`, `preview`, `use-language-guard`, профиль (выключенные скрыты), карта дня (смена языка → `lang=de`, новое имя). Обновлены ожидания URL (`?lang=en`) и тексты четырёх фраз.

`typecheck` ✓, `lint` (eslint + steiger) ✓, `build` ✓. `vitest`: последние 3 полных прогона — 1911 / 1911 ✓. Раньше
3 полных прогона подряд падали на `booking.test.tsx › a short balance offers no payment…` (отдельно файл и весь
`src/app` проходили); `develop` @ 88dd553 в одном прогоне — зелёный. Причину не нашёл; похоже на тест, чувствительный
ко времени / нагрузке, — держу в виду в маноре.

## Открыто
- Греческий капс (`keywords`, `text-transform: uppercase`, `<html lang="el">`): снимает ли браузер ударения — проверка в маноре.
- Сервер начнёт отвечать на языке с `AURAT-0171`; до того `lang` безвреден.
- `prettier --check .` ругается на 2 файла, которых задача не трогала (`pages/booked/config/locales/el.ts`, `pages/match/lib/__tests__/match-advisors.test.ts`) — так на `develop`.
