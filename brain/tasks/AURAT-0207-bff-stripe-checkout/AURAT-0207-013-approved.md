# AURAT-0207-013 — approved

Дата: 2026-11-12 · Status: `done`

Записано из `aura-app-manor` (сессия slave-0): сессия этого слота (slave-1-e6) к этому времени закрыта.
Владелец, дословно: «закрой bff, я уже влил ее в дев».

- **Смёржена:** `develop` BFF `06754f5`, коммит `e961fb9`. Merge — с «да» владельца во вкладке slave-1-e6
  (шаг 012).
- **Проверено на bff-dev и web-dev, Stripe sandbox, 2026-11-11:**
  - Первый старт с флагом остановила защита «restricted key in production»: в Coolify стоял `sk_test_`.
    Владелец создал restricted-ключ `rk_test_` — Checkout Sessions и Refunds — Write; PaymentIntents,
    Charges, Disputes, Events, Products — Read. После этого BFF поднялся.
  - Запросы без входа: app-config — 200, старт оплаты — 401, вебхук без подписи — 400. CORS для
    `https://web-dev.aura-app.cc` разрешён.
  - Вебхук `we_1UaexWPzZXCl9nsGFRm9tpP7` включён. На web-dev владелец сделал:
    - оплату — `checkout.session.completed`, $22, `paid`;
    - две отмены — `checkout.session.expired`, сессии закрыл BFF.
  - Все три события доставлены (`pending_webhooks: 0`) — секрет вебхука верный.
  - Веб `AURAT-0208` владелец принял на web-dev.
- **Живая проверка до мёржа** — локально из слотов, 2026-11-11, шаги 010 и 011:
  - причина отказа Stripe пишется в лог;
  - `STRIPE_TERMS_CONSENT`: в sandbox нельзя задать ссылку на Terms.
- **Coolify bff-dev:** `STRIPE_SECRET_KEY=rk_test_…`, `STRIPE_WEBHOOK_SECRET`,
  `STRIPE_TOP_UP_PRODUCT_ID=prod_Vbsi7vgwZsBxxs`, `CARD_TOP_UP_ENABLED=true`, `STRIPE_TERMS_CONSENT=none`.
- **Дальше:**
  - встроенный Checkout — `AURAT-0211`, по команде владельца;
  - live — по воротам `AURAD-0023`.
