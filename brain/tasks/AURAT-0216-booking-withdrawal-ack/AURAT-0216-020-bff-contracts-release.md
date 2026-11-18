# AURAT-0216-020 — BFF: изменения приняты, контракты `v0.35.0` выпущены

Дата: 2026-11-18. Владелец: «принимаю» (ревью кода), затем «Да, выпускай v0.35.0».

- `aura-contracts`: коммит `16bd10e` → `main` `a610947` (`Merge feature/v0.35.0-consents`),
  аннотированный тег `v0.35.0` (`d8df4b5`); push `main` и тега — проверен `ls-remote`. Ветка удалена.
- BFF, ветка `feature/AURAT-0216-booking-withdrawal-ack`:
  - `bccae93` — код задачи (шаги `017`, `018`);
  - `e6e299b` — `@aura/contracts` `#v0.35.0` (lock → `a610947`); миграция переименована в
    `20261118150000_consents`, чтобы не совпасть по метке с `20261118120000_chatter_working_hours`
    из `AURAT-0220` (BFF slave-2, предупреждение манора).
- После чистой установки (`npm ci`, `prisma generate`): `tsc`, `npm run lint`, `nest build`, jest
  **197 / 3062** — зелёные.
- Merge в `develop` — отдельное «да» владельца. `AURAT-0220` пересекается в `sessions.*`,
  `schema.prisma`, `env.schema.ts`, README, `bff.env.example`: кто мёржит вторым — разрешает конфликты
  и гоняет проверки заново.
