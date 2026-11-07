# AURAT-0169-011 — правки по ревью кода A / B + develop с 0167

Дата: 2026-11-06. Ревью — координатор `slave-1-9e` (1 среднее, 5 мелких; отступление `allowedLanguage(wanted, disabled)` принято).
Решение владельца (через координатора): сценарий (b) — как есть (выбран fr, выключили → English отмечен; Choose без
изменений ничего не пишет; fr включили — вернулся).

1. **`i18nReady` в запросе — тест.** `shared/api/bff/__tests__/language-wait.test.ts`: свежий процесс, флаг включён, чтение
   выбора держится на своём промисе; `bffRequest` / `bffUpload` не зовут `fetch` / `ReactNativeBlobUtil.fetch` до его
   разрешения, после — один вызов с `?lang=de`. Проверено: без `await i18nReady()` тест падает.
2. **Выключенный выбор в открытом листе** — `use-language-sheet.ts`: пик, попавший в `disabled`, отбрасывается (`livePick`),
   Choose не сохранит язык без строки. Тест в `LanguageSheet.test.tsx`.
3. **Сбой старта** — тест в `disabled-languages.test.ts`: `initI18n` бросает → `startI18n` отклоняется, `i18nReady()` разрешается.
4. **Описания** — `resolve-language.ts` (это `wanted` до фильтра), `I18nGate.tsx` (ждёт и кэш выключенных; сбой старта
   пропускает).
5. **Пункты спеки** — `avatarUrl('a1')` без `lang=` (`avatar-api.test.ts`); (b) через лист: fr выключен → Deutsch → fr
   включили → de (`LanguageSheet.test.tsx`).
6. **dev-menu.test** — пункты регистрируются в `beforeAll`, сброс в `afterEach`; `-t "steps past"` в одиночку проходит.

Затем `develop` @ `74755ee` (мёрж `AURAT-0167`) влит в ветку fast-forward'ом (своих коммитов у ветки нет; пересечений
файлов с изменениями A / B — ноль). После: tsc, lint чисто; jest 202 / 2798 зелёные.
