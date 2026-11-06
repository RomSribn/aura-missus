# AURAT-0165-001 — initial

Дата: 2026-11-06. Выдана по просьбе владельца: «да, выдавай и запускай» — на предложение выдать номера и запустить две
из трёх оставшихся задач шага 3 в новых слотах. Запуск — slave-2 (`wts-run`), от `develop` @ `7f58117`.

Шаг 3 фичи `AURAF-0023` — перенос строк. Это задача «бронь и сессии» из плана `AURAI-0010` § Recommendation, п. 3.
В develop уже есть: основа i18n, глоссарий, шрифты el/bg, shared-слой, форматтеры CLDR, лист языка, entities, вход
(`AURAT-0154`…`0159`, `0161`, `0162`). На ревью: `AURAT-0163` — профиль, `AURAT-0164` — витрина.

Что входит; границы уточнить в спеке:
- **Экраны:** `screens/booking`, `screens/reschedule`, `screens/sessions` (сегменты Upcoming / Past уже `0157`),
  `screens/session-detail` с листом отмены, `screens/write-review`.
- **Фичи:** `features/booking` (DateStrip, слоты, Quick book), `features/advisor-review` (форма отзыва, `REVIEWS.md`).
- **Оплата** (`Pay … & book`, checkout) — задача «деньги» (`AURAT-0166`), не здесь.

Известные места (`AURAI-0010-evidence.json`):
- `DateStrip` фиксированной ширины 58 pt — день недели и число по CLDR. Для bg / lt месяц числом, для cs / fi —
  проверить. Форматтеры `0159` уже дают `shortDateParts` и `relativeDay`.
- a11y DateStrip `…${hasFree ? '' : ', fully booked'}` — целая строка с вариантами.
- `${quick.instant ? 'Start now' : 'Book'} · ${cost}` — целые строки.
- `pastDate` «24 May», `slotLabel` «16:50, Jun 02» (Reschedule) — через форматтеры с явным языком.
- **Отмена сессии** (возврат, правила отмены) — `@sensitive` (cancellation / refund): до маркетинга в стране нужна
  проверка носителем.
- `/min` — ключ `shared:price.perMinute` добавляет `AURAT-0164` (ещё не в develop). Если он нужен здесь — смёржить
  develop после мёржа 0164 или договориться при мёрже.

Правила — раздел «Translations» в `.claude/aura-build-rules.md`:
- все 24 языка в этой же задаче, namespace на слайс;
- глоссарий: `translate.mjs scan … --web <aura-web>`, на вебе есть book-session, sessions, cancel-session,
  write-review;
- `@max` и замер шрифтом для узких мест (как в `0162-008`, `0164-007`), `@sensitive`;
- `i18next/no-literal-string` на `error` для перенесённых путей.

Параллельно: `AURAT-0166` (деньги) — в slave-3. Общие файлы (`app/i18n/namespaces.ts`, `.eslintrc.js`,
`translations.test.ts`, `shared/config/locales/*`) — конфликт решает та, что мёржит позже.
