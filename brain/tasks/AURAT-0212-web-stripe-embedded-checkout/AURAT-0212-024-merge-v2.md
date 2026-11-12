# AURAT-0212-024 — Merge v2 (Elements)

Date: 2026-11-12

Координатор передал слова владельца: «выкатил бек на bff-dev, передай вебу на merge» — BFF
`AURAT-0213` (`cd0975b`) на bff-dev. Владелец в этой вкладке на вопрос о мёрже: «Да, мёрж».

- Брейн манора: `fetch` + `merge --ff-only origin/master` → `51df11f` (был позади на 5).
- `wts-finish slave-1`: ветка `feature/AURAT-0212-web-stripe-embedded-checkout`, коммиты `79f3b16`
  (`@aura/contracts` `v0.34.0`) и `b7a504f` (Stripe Elements). develop aura-web
  `0e7b88d..9cf617d`, push в origin — ок. Idle-слоты 2–5 обновлены. Missus — не закоммичен (по
  wts-task — при закрытии задачи).

Слот остаётся на ветке до `wts-release`.

Дальше — выкат web-dev (владелец, Coolify), затем проверка в маноре:
- список `005` с поправками `008`;
- экраны макета: кошельки в шторке, «or» и «Other ways to pay», без кошельков — «Pay {{сумма}}»,
  шаг Payment, отказ карты;
- валюта, выбранная в шторке, сохраняется на шаге оплаты;
- 429 и `Retry-After` — «Try again in N min»;
- кошелёк с аккаунта без email;
- шрифт Hanken в полях Stripe, нарушений CSP в консоли нет;
- Terms (live) — отдельно, на sandbox со ссылкой на Terms, до live.
