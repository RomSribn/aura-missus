# AURAT-0211-010 — Merge

Date: 2026-11-12

Владелец в этой вкладке на вопрос про merge (с напоминанием о `pk_test_` в Coolify до merge) —
«Да, ключ уже в Coolify — мёрж».

- `wts-finish slave-1`: `feature/AURAT-0211-bff-stripe-embedded-checkout` (71d774d) → `develop`
  merge **6d9ce2b**; push `develop` в origin — ок (06754f5..6d9ce2b). Idle-слоты 2–5 обновлены.
- Missus: «Already up to date» — шаги задачи не коммичены (коммит — при закрытии задачи).
- Слот остаётся на ветке задачи.
- По словам владельца, `STRIPE_PUBLISHABLE_KEY=pk_test_…` уже в Coolify bff-dev.

## Проверка в маноре (bff-dev + sandbox, вместе с `AURAT-0212`)

1. bff-dev поднялся после выката (ключ принят, режим test/test).
2. web-dev на `v0.32.0` до мёржа веба — оплата через страницу Stripe как раньше.
3. После `AURAT-0212`: `4242 4242 4242 4242` с 3DS — оплата в шторке, без ухода с сайта, зачисление.
4. iDEAL (если включён) — уход к банку и возврат на `/checkout`.
5. Закрыли шторку → `cancel` → сессия `expired`, ничего не списано.
6. Повтор «Pay» тем же `paymentId` → та же форма: `retrieve` под restricted-ключом `rk_test_` тоже
   отдаёт `client_secret` (через MCP подтверждено, restricted-ключом — нет).
