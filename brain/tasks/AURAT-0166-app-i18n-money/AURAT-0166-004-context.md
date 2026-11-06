# AURAT-0166-004 — context

Дата: 2026-11-06.

## Источники
- Код slave-3 @ `7f58117` (ground truth): `features/store-topup`, `features/promo-code`, `features/paid-session`,
  `shared/ui/offer`, `screens/profile/config/constants.ts`; потребители — `screens/booking`, `screens/chat-thread`,
  `screens/profile`, `screens/home`, `screens/advisors`, `screens/advisor-profile`.
- Образцы: `AURAT-0162` 005–008 (namespace на слайс, `@max` по замеру, `@sensitive`), `AURAT-0164-007` (`/min` —
  `shared:price.perMinute`, ещё в slave-1), `AURAT-0163` (строка промокода в профиле оставлена английской).
- `AURAI-0010-evidence.json`: store-topup — 49 строк (16 с подстановкой) + бренды; paid-session — 21; promo-code —
  ~17. Риск: `CheckoutVerb` — подпись и ключ логики сразу. Рекомендация 13: убрать или спрятать заглушку
  «Visa ···· 4242 / Change».
- aura-web: `pay`, `redeem-promo-code`, `extend-session`, `finish-session`, `wallet` — английский во многом совпадает
  (Pay with, Aura balance, «… · not enough», «… left after», все отказы промокода, Add more minutes, End this
  session?, Keep going, End session, End session early, «Balance {{amount}}»). Top-up через стор на вебе нет.

## Что нашёл
- **Склейки:** `Pay ${storePrice} & ${verb}` (глагол из типа); `Use my balance · ` + вложенный Text;
  `` `Charged by ${STORE_VENDOR} as ${price}` ``; `` `${STORE_NAME} couldn't complete the payment.` `` (бренд —
  подлежащее: в славянских языках глагол прошедшего времени требует рода); `formatMinutes` = `` `${n} min` `` без
  плюралов; Alert «The remaining N min are…» из двух кусков; `` `Extend +${…}` ``; `−${formatUsdMinor(…)}` вместо
  знака CLDR; `OffChip` — `` `−${pct}%` `` без правил языка (de «−50 %», fr — пробел перед %).
- **Модель держит готовый текст:** `use-checkout` (CTA, balanceSub, remainder, localNote), `use-paid-session`
  (rateLabel, extendLabel, Alert), `use-promo-code` хранит отказ строкой в state — при смене языка останется
  старым.
- **Заглушка** в TopUpSheet вне store-rail: «Visa ···· 4242» + «Change» — карта, которой нет (PSP не подключён).
- **Чужие слайсы с денежным текстом** (из «известных мест» заглушки): `savedWith` / `discountLine` / «Biggest
  saving» / `Confirm & pay …` / `Start now · …` — `features/booking` и `screens/booking` (объём `AURAT-0165`);
  `Extend · …`, «Choose a block», тост «Added N minutes» — `screens/chat-thread` (задача чата).
- **`shared/ui/offer`:** PriceTag, CouponTicket, CampaignTicket уже на `t()` (`0157`/`0161`); «Half price with
  {{name}}» в 23 языках уже сформулировано без падежа (апозиция / «· {{name}} ·»). Остаётся `OffChip`.
- Литералы-бренды: `STORE_NAME` (App Store / Google Play), `STORE_VENDOR` (Apple / Google Play) — не переводятся.

## Противоречия
- Заглушка `001` относит к «деньгам» склейки из `features/booking`; `AURAT-0165-001` берёт `features/booking` и
  `screens/booking` целиком, оплату (`Pay … & book`, checkout) отдаёт сюда. Граница — решение владельца (спека, 1).
