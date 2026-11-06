# AURAT-0170-005 — spec: веб — язык на проводе, маркеры, таро

Дата: 2026-11-06 · Status: **done** 2026-11-06 (`011-approved.md`) · Фича `AURAF-0023` (строки 009, 010) · Контракт `AURAT-0168` v0.28.0

## 1. `?lang` в запросах к BFF
- `shared/i18n/current-language.ts`: `currentLanguage(): Language` — `i18next.resolvedLanguage`, если это язык из
  `LANGUAGES`, иначе `SOURCE_LANGUAGE`. Экспорт из `@/shared`; `use-languages.ts` переходит на него.
- `shared/api/with-language.ts` (чистая, с тестом): `withLanguage(path, language)` — ставит
  `LANGUAGE_QUERY_PARAM=<код>` через `URLSearchParams`, сохраняя существующий query (`?tz=`, `?limit=&after=`).
- Подключение: `base-query.ts` `performRequest` (весь RTK Query, и публичные маршруты) и `bff-file.ts`
  `sendBffFile` (загрузка). **Не** `fetchBffFile` (вложения, аватары — адрес = ключ кэша) и **не** сокет.
- Кэш RTK Query не трогается (ключ — аргументы эндпоинта); язык берётся в момент запроса.

## 2. `disabledLanguages`
- `parse-app-config.ts`: новая часть `disabledLanguages: readonly Language[]` — схема части
  `AppConfigDisabledLanguages`, затем только коды из `LANGUAGES`, без `en`, без дублей; не разобралось → `[]`.
  `NO_APP_CONFIG` и `liveAppConfig` — с полем.
- `entities/season` экспортирует `useDisabledLanguages(): { languages, answered }` (тот же запрос `getAppConfig`).
- `shared/i18n/language-choice.ts`:
  - `effectiveLanguage(disabled)` = (`rememberedLanguage()` ?? `detectLanguage()`), а если он выключен — `en`
    (правило контракта: выбранный или системный язык выключен → английский);
  - `applyDisabledLanguages(disabled)` — запоминает список в `localStorage` (`aura.disabledLanguages`) и, если
    `effectiveLanguage` ≠ текущему, переключает i18next **без** записи выбора — выбор человека сохраняется и
    вернётся, когда язык включат обратно;
  - `startLanguage()` учитывает запомненный список — следующий визит сразу стартует на английском, без вспышки
    выключенного языка.
- `app/root.tsx`: `<LanguageGuard />` — после ответа app-config (`answered`) зовёт `applyDisabledLanguages`.
- Профиль → Язык: выключенные языки не показываются (`use-languages.ts`).

## 3. Маркеры и превью
- `ChatMessage.marker?: SessionMarker` (`'started' | 'finished'`). `map-message.ts`: типизированная таблица
  `Record<MessageMarker, SessionMarker>` (`session_started → started`, `session_finished → finished`); маркер
  важнее текста; нет или неизвестный → запасной путь `sessionMarkerOf(content)` (старые сообщения, старый сервер).
  `tone` — от маркера (`started` → teal), регулярка `/\bstarted\b/i` уходит; без маркера — `muted`, как сейчас.
- `system-line.tsx`, `message-preview.tsx` читают `message.marker` вместо разбора текста.
- `preview.ts`: у `spread` — иконка `cards` и слово `message:preview.spread` «Tarot spread», у `sessionInvite` —
  `cal` и `message:preview.invite` «Private session invitation» — как в приложении (`AURAT-0167`); `content` не
  показывается.

## 4. Таро на языке человека
Надписи на картинках карт не трогаем (владелец). Имя карты стоит отдельно — без склонения внутри фразы:

| ключ | было | станет |
|---|---|---|
| `daily-page:bridge.title` | Wondering what {{card}} means for you? | Wondering what this card means for you? (имя — заголовок выше) |
| `daily-page:draft` | I drew {{card}} today. What could it mean for me? | My card today: {{card}}. What could it mean for me? |
| `tarot-pick:youChose` | You chose {{card}} | You chose: {{card}} |
| `tarot-pick:open` | Open {{card}} full size | Open full size: {{card}} |

Каждый ключ — во всех 24 языках в той же правке (правило 9). Имена старших арканов придут **с артиклем** (de «Der
Narr», fr «Le Mat», es «El Loco», `AURAT-0171`), «The Lovers» — множественное: поэтому имя только в приложении
после двоеточия (именительный, без согласования с глаголом), либо в кавычках после слова «карта» там, где язык
иначе не может (de «die Karte „{{card}}“»). Проверяю все 23 перевода на винительный падеж, двойной артикль (el) и
согласование числа.

**Регистр.** `keywords` рисуются капсом через CSS `text-transform: uppercase`
(`pages/daily/ui/daily-page.module.css:133-138`, `entities/tarot/ui/tarot-card.module.css:39`); `<html lang>` уже
ставится при смене языка. Снимает ли браузер греческие ударения при `lang="el"` — проверка в маноре (в слэйве
браузера нет). Если нет — капс функцией без ударений, как `upperLabel` приложения (`shared/lib/dates.ts:186-198`),
отдельной правкой.

**Длина.** По таблице самых длинных `name` / `keywords` из `AURAT-0171` — проверка мест карты (лицо карты,
`card-reveal`, баннер Home, строка выбора, лист карты); правки CSS — если что-то не влезает.

**Смена языка.** Карта дня: язык — часть ключа кэша (`getDailyCard({ tz, language })`, `markDrawn` — тот же
ключ), поэтому смена языка — новый запрос, а ответ, опоздавший на старом языке, ложится в свой старый ключ и
поверх нового не попадает. Открытые переписки отдельно не перечитываются: в чате
сервер переводит только имя и `keywords` выбранной карты, а язык меняют в Профиле — при следующем открытии
переписки `refreshThread` и так перечитывает новейшую страницу (решение владельца, `006`). Маркеры, заголовки
расклада и приглашения, превью — строки веба, меняются сразу.

## 5. Контракты и порядок
`@aura/contracts#v0.27.0` → `#v0.28.0` — отдельным коммитом (правило 6). `marker` до перехода не прочитать: схема
v0.27 выбрасывает поле при разборе. Поэтому работа идёт против `v0.28.0`, собранной из ветки контрактов локально
(в `node_modules`, в коммит не попадает); мёрж — после появления тега. Тест: `LANGUAGES` веба совпадает с
контрактным. `SOURCE_LANGUAGE` — свой (в контрактах он пока типа `Language`, не литерал; `0168` исправит до тега).
`AppConfig` веба — свой интерфейс, на v0.28 компилируется без правок; добавляется только разбор части.

Решения владельца по приложению (`0169`), держу веб так же: выключенный язык в выборе — скрыт; `lang` — и в
`/v1/app-config`; мёрж — после тега v0.28.0 (подтверждено и для веба, 2026-11-06).

## Проверки
Unit: `withLanguage`, `currentLanguage`, `effectiveLanguage` / `applyDisabledLanguages`, `parseAppConfig` (поле,
мусор, `en`, неизвестный код), `mapMessage` (маркер / неизвестный маркер / старое сообщение), `previewOf`,
`base-query` и `sendBffFile` шлют `lang`, `fetchBffFile` — нет; app-тесты: язык выключен → английский, лист без
выключенного; смена языка перечитывает карту дня (новый ключ), опоздавший ответ не ложится поверх. `lint`, `typecheck`, `test`, `build`. В маноре после мёржа:
`?lang` в запросах (DevTools), `DISABLED_LANGUAGES=mt` на bff-dev, история с маркерами.

## Не здесь
Резолвер `?lang` и колода на 23 языках — BFF `AURAT-0171`; язык для чаттеров — отложен (`AURAT-0168` §5).
