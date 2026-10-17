# AURAT-0093-011 — Правка: вызов `useFirstSessionOffer` в литерале `return`

Дата: 2026-10-17
Вопрос владельца: безопасно ли в `useAdvisorProfile` возвращать `offerPct: useFirstSessionOffer()`.

- Было безопасно: в обоих хуках (`use-advisor-profile`, `use-advisors`) ранних
  `return` до литерала нет (`return` на строках 35/54 — внутри `useCallback`),
  так что хук вызывался безусловно и в том же порядке. В кодовой базе такой приём
  уже есть, но только для `useCallback` (`use-session-detail`, `use-reschedule`).
- Всё равно перенесено наверх, к остальным чтениям данных (`useAdvisor`,
  `useChat`, `useReviewAccess`): хук состояния читается как источник данных, а
  не прячется в отдаваемом объекте. Если потом в хуке появится ранний `return`,
  вызов не окажется условным.
- `tsc`, `eslint`, тесты advisors / advisor-profile (56) ✓. Застейджено.
