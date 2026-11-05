# AURAT-0161-001 — initial

Дата: 2026-11-05. Выдана по просьбе владельца: «продолжим по переводам», выбор — «entities + вход». Запуск — slave-0
(`wts-run`), от `develop` @ `307bb14`.

Шаг 3 фичи `AURAF-0023` — перенос строк. Это задача «entities» из плана `AURAI-0010` § Recommendation, п. 3. Основа уже
в develop:
- i18n — `AURAT-0154`;
- глоссарий — `AURAT-0155`;
- шрифты el/bg — `AURAT-0156`;
- shared-слой — `AURAT-0157`;
- форматтеры CLDR — `AURAT-0159`;
- лист языка — `AURAT-0158`.

Что перенести. Инвентарь — `AURAI-0010-evidence.json`, строка про entities; сверить с кодом.
- `entities/horoscope/config/signs.ts` — 12 названий знаков и 12 диапазонов дат («Mar 21 – Apr 19»). Даты — через
  форматтеры `0159` с явным языком, не руками.
- `entities/campaign/config/constants.ts` — `FALLBACK_TICKET_COPY`. В нём одиночные `{amount}` / `{pct}`, формат
  сезонных текстов с сервера: проверить, что подстановка не ломается. Плюс a11y-составление в `SeasonHero.tsx`.
- `entities/user/ui/PhotoRow.tsx` — «Change photo».
- В advisor, session, tarot, wallet текстов по инвентарю нет — подтвердить.

Правила — раздел «Translations» в `.claude/aura-build-rules.md`:
- все 24 языка — в этой же задаче; namespace на слайс; `@max` для узких мест;
- глоссарий: `node scripts/i18n/translate.mjs scan <en.ts> --web <aura-web>`;
- `i18next/no-literal-string` на `error` для перенесённых путей;
- тесты полноты.

Параллельно в slave-1 идёт `AURAT-0162` (вход). Общие файлы (`app/i18n/namespaces.ts`, overrides в `.eslintrc.js`)
трогают обе задачи — конфликт решается при мёрже второй.
