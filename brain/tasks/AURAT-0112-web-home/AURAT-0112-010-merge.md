# AURAT-0112-010 — Merge

Date: 2026-10-21

- `AURAT-0108` вошла в develop (`ca6bdca`) — develop влит в ветку ещё раз: `3676b1e`. Конфликты
  текстовые в 3 файлах (`app/config/i18n.ts`, `vitest.setup.ts` — обе стороны, у 0108 ещё
  `asyncUtilTimeout`; `shared/config/index.ts` — экспорты обеих задач).
- Проверки после слияния: typecheck, lint (eslint + steiger), build, prettier — чисто;
  `npm test` 1206 / 1206 (часовой тест профиля починен в 0108).
- Владелец подтвердил merge и push (AskUserQuestion, два вопроса — второй уточнил, что wts-finish
  пушит develop).
- `wts-finish slave-3`: `feature/AURAT-0112-web-home` → develop в маноре, `6752a62`; push
  `ca6bdca..6752a62 develop -> develop` — ок.
- Missus: нечего сливать (не закоммичен — коммит один в конце задачи). Backup-push missus с
  предупреждением: manor missus `master` отстаёт от `origin/master` на 1 коммит (`4a630d2`,
  AURAT-0113) — перед `wts-release` его нужно подтянуть (fast-forward).

Дальше — проверка в маноре (сценарии — `005`, «Проверка в маноре»).
