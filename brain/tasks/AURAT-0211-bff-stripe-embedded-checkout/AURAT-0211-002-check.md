# AURAT-0211-002 — Check

Date: 2026-11-12
Slot: `aura-bff-manor` slave-1, ветка `feature/AURAT-0211-bff-stripe-embedded-checkout`
(master от `develop` 06754f5, missus от `master` 4668229).

Старт: владелец — «запусти AURAT-0211 в aura-bff»; координатор — `aura-app-manor` slave-0
(«Анализ платёжек для aura-web»).

- Папки задачи в общем мозге на origin нет. Шаг 001 скопирован с диска `aura-app-manor`
  (коммит d384377 там только локальный, missus aura-app-manor расходится с origin) — без правок.
- Поправка `AURAD-0023` от 2026-11-11 и строки `AURAF-0009` — в том же d384377, в этот missus
  не копировались (придут с пушем из `aura-app-manor`); читались с диска.
- База: `AURAT-0207` закрыта (`013-approved`, develop 06754f5), проверена на bff-dev и web-dev
  со Stripe sandbox.
- Пара: веб `AURAT-0212` (`aura-web-manor`) — стартует после этой задачи и контрактов `v0.33.0`.

Следующий шаг: 003-understand.
