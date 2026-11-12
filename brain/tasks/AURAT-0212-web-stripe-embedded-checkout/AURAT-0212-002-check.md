# AURAT-0212-002 — Check

Date: 2026-11-12. Slave: `slave-1`, ветка `feature/AURAT-0212-web-stripe-embedded-checkout`
(master и missus); `develop` aura-web `c7912bc` (мёрж `AURAT-0208`), missus — `master` `860e152`
(манор подтянут с origin fast-forward: был позади на 79 — `09982ae..860e152`).

- Папка `AURAT-0212-*` пришла с origin (`d384377`, `6216d76`). Шаг 001 взят с диска
  `aura-app-manor/project/manor/missus/` (коммит `17000a8`, ещё не в origin): к origin-версии
  добавлены «Истечение» и «Повторный маунт». Больше отличий нет.
- Пара BFF — `AURAT-0211` (`aura-bff-manor` slave-1): код принят владельцем, BFF на теге `v0.33.0`;
  merge в develop BFF — после `pk_test_` в Coolify bff-dev.
- База веба — `AURAT-0208` (done, develop `c7912bc`): hosted Checkout, порт `TopUpProvider` с
  `cancel`, адаптер `card-provider`, возврат `/checkout?payment=`, Back (041).
- `@aura/contracts` `v0.33.0` — тег в origin (`main` `3470114`, по словам координатора; сверю
  `git ls-remote`).

Задача свежая, исполнения не было. Дальше — 003.
