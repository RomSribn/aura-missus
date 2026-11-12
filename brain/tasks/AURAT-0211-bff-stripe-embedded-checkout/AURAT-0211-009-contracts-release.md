# AURAT-0211-009 — Контракты v0.33.0 выпущены, BFF на теге

Date: 2026-11-12

Владелец в этой вкладке на вопрос «Выпускать?» — «Да, выпускай v0.33.0».

- `aura-contracts`: коммит 83af429 на `feature/v0.33.0-card-embedded-checkout`, merge в `main`
  3470114, аннотированный тег `v0.33.0` (66a51e7 → 3470114). Push `main` и тега — ок,
  `git ls-remote` показывает оба.
- BFF: `npm install @aura/contracts@github:RomSribn/aura-contracts#v0.33.0` — `package.json`
  и `package-lock.json` (resolved #3470114). `tsc`, `build` ок; `jest` — 195 наборов / 3006
  тестов зелёные на теговом пакете.
- Коммит BFF в ветку задачи: 71d774d. Missus не коммичен (по wts-task — в конце задачи).

Дальше:
1. Владелец кладёт `STRIPE_PUBLISHABLE_KEY=pk_test_…` того же sandbox в Coolify bff-dev — **до** merge.
2. Merge в `develop` (`wts-finish slave-1`) — отдельное «да».
