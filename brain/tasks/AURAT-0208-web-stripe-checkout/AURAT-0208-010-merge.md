# AURAT-0208-010 — Merge

Date: 2026-11-11. Слот slave-1, ветка `feature/AURAT-0208-web-stripe-checkout`.

## Основание

- Пир из `aura-app-manor` сообщил (около 21:15):
  - `AURAT-0207` смёржен в `develop` BFF (`06754f5`) и выкачен на bff-dev;
  - `CARD_TOP_UP_ENABLED=true`, sandbox-ключи заданы, вебхук включён;
  - dev-сервер слота погашен.
- Владелец в этой вкладке на вопрос о мёрже ответил «Да, мёрж».

## Что сделано

- `wts-finish slave-1`: ветка смёржена в `develop` aura-web. Новый `develop` — `c7912bc` (был
  `84d4b33`), запушен в origin.
  - Коммиты задачи: `0b48100` (контракты `v0.32.0`), `f10a86c` (Stripe Checkout).
  - Изменено 68 файлов, +1362 −608.
- Missus в manor: «Already up to date». Шаги задачи не закоммичены, это ожидаемо: коммит будет при
  закрытии задачи.
- Свободные слоты slave-2 – slave-5 обновлены до нового `develop`.
- Слот остаётся на feature-ветке.

## Дальше

- Coolify, web-dev: `VITE_PSP_ENABLED=true` и пересборка. `VITE_PSP_FAKE` не задаётся. Прод остаётся
  `false`, пока не пройдены ворота live `AURAD-0023`.
- Проверка на web-dev (против bff-dev, sandbox) — по списку из `007-spec-v2`, раздел «Проверка в
  маноре».
- После «Принято» владельца:
  - пиру — строки `AURAF-0020` 037, 038, 040, 041 → UI ✓ (039 — BFF) и пункты `AURAD-0023`;
  - коммит missus, `wts-release`.
