# AURAT-0159-001 — initial

Дата: 2026-11-05. Контекст: ждёт слота; стартует после слияния `AURAT-0156` (владелец: раньше `AURAT-0158`).

Выделена из `AURAT-0157` решением владельца (`AURAT-0157-006`): шаг 2 фичи `AURAF-0023`, часть B — форматтеры по
CLDR языка интерфейса (решение владельца 2 в `AURAI-0010`). Черновик — `AURAT-0157-005-spec.md` § B с правками
`AURAT-0157-006` / `007`:
- генератор таблиц CLDR из Node ICU (`scripts/i18n/generate-formats.mjs`) + drift-тест в Jest; во время работы
  `Intl` не используется;
- вывод CLDR как есть, **без** замены U+202F → U+00A0: `AURAT-0156` добавляет U+202F в Hanken;
- API с явным языком: `formatUsdMinor` / `formatUsd` / `formatUsdMinorCompact`, `formatClockTime` (24h; da / fi —
  «16.05» по CLDR, решение владельца), `formatFileSize`, `longDateLabel`, `shortDateParts`, `relativeDay` → данные
  + `relativeDayLabel`, `useLanguage()`; ручные короткие месяцы bg / lt (проверить cs / fi);
- все 33 файла-потребителя (43 вызова `formatUsdMinor`); таблицы `features/booking/lib/slots.ts` и
  `screens/home/lib/format-date.ts` удаляются;
- шапка Home: заглавные через `toLocaleUpperCase(language)`, `accessibilityLabel` — в обычном регистре (VoiceOver
  читает слово из заглавных по буквам); тесты шапки Home поправить;
- порядок английской даты — решение владельца в `AURAT-0157-006` / `007` (US или en-GB для дат; деньги — en).

**Решение владельца 2026-11-05 (`AURAT-0157-008`):** английская дата — по региону телефона (вариант C): US (+
территории), CA, PH → US-порядок, остальные регионы → en-GB; шапка Home — «день недели · число месяц» из двух
частей CLDR («WEDNESDAY · NOVEMBER 4» / «WEDNESDAY · 4 NOVEMBER»); деньги en — «$1.99» у всех; время 24h везде,
включая US. Генератор выпускает две английские таблицы, drift-тест — обе.
