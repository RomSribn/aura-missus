# AURAT-0213-008 — Контракты v0.34.0 выпущены, BFF на теге

Date: 2026-11-12

Владелец в этой вкладке на вопрос «Посмотрел в IDE? Выпускать v0.34.0?» ответил: «Да, выпускай v0.34.0».

- `aura-contracts`: коммит 5ca4c2d на `feature/v0.34.0-card-elements-checkout`, merge в `main` 016b5b0,
  аннотированный тег `v0.34.0` (54d8c66 → 016b5b0). Push `main` и тега прошёл, `git ls-remote`
  показывает оба.
- BFF: `npm install @aura/contracts@github:RomSribn/aura-contracts#v0.34.0` — `package.json` и
  `package-lock.json` (resolved #016b5b0). `tsc` и `build` проходят; `jest` — 197 наборов / 3031 тест
  зелёные на пакете с тега.
- Коммит BFF в ветку задачи: 3e1bb75. Missus не коммичен (по wts-task — в конце задачи).

Дальше: merge в `develop` (`wts-finish slave-2`) — отдельное «да». Новых env нет.
