# AURAT-0145-006 — approval

Date: 2026-10-28. Владелец: «Спека ок», с правками текстов (единые с
приложением, `AURAT-0144`):

- `promo_code_campaign_used` — «You’ve already used a code from this promotion.»
  («offer» путается с купоном оффера прямо над полем).
- 404 при отправке — «Promo codes aren’t available right now.» (и перечитать
  кошелёк → поле уйдёт).
- сеть / 400 / 5xx / прочее — «Couldn’t apply the code. Please try again.»
- 429 без `Retry-After` — «Too many tries. Try again later.»
- остальное — как в §2 спеки (успех, повтор, not_found, already_used, expired,
  disabled, «Too many tries. Try again in {{count}} min.»).

Поле только в Coupons, как в хендоффе, — да.

Дальше: выполнение.
