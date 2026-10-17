# AURAT-0093-016 — merge

Дата: 2026-10-17

Владелец проверил на устройстве (debug → bff-dev, затем Play internal testing
сборкой versionCode 26 на bff-dev) и дал «релизь задачу»; merge gate —
«Да, мёрж и release».

- Ветка: `feature/AURAT-0093-first-session-offer`
  - `79c1717` feat(offer): first-session offer — 50% off instead of the $5 credit
  - `ef95728` fix(offer): strike through the middle of the struck figures
- `wts-finish slave-0`: в `develop` манора, origin `7ce8f06..5428c49`.
- `versionCode` в репо не тронут (23). Сборка 26 ушла в internal testing из
  slave-0 локальным бампом; следующей сборке для Play нужен ≥ 27.
