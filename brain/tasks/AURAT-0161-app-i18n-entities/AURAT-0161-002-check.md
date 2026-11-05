# AURAT-0161-002 — check

Дата: 2026-11-05. Слот slave-0, ветка `feature/AURAT-0161-app-i18n-entities` от `develop` @ `307bb14` (0154–0159
слиты). `active-work.md` — slave-0 отмечен busy.

Найдено в brain:
- папка задачи — только `001-initial.md` (заглушка координатора);
- образцы шага: `AURAT-0157` (shared-слой: namespace на слайс, `SAME_AS_ENGLISH`, `translate.mjs scan/check`),
  `AURAT-0159` (форматтеры CLDR: генератор `scripts/i18n/generate-formats.mjs`, drift-тест, `shortDateLabel`);
- `AURAI-0010-evidence.json` findings[2].facts[15] — инвентарь entities: horoscope 24, campaign 4 + 1 a11y, user 1;
  advisor / session / tarot / wallet — без текстов;
- `AURAT-0149-005/006` (веб): сезонные тексты сервера остаются английскими до контракта с переводами (решение 3).

Параллельно: `AURAT-0162` (вход) в slave-1 — общие `app/i18n/namespaces.ts` и `.eslintrc.js`.

Дальше — 003 understand, 004 context.
