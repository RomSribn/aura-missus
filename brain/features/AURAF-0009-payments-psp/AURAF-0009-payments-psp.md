# AURAF-0009 — Real payments (PSP)

Type: product
Status: **ready** (2026-11-11). Провайдер выбран — Stripe Checkout на вебе (`AURAD-0023`). Задачи:
BFF `AURAT-0207`, веб `AURAT-0208`, условия `AURAT-0209`. См. «Состояние» в конце.
Priority: P1 (blocks nothing today; unblocks several things that are parked)

## What

Connect a real payment provider so money can enter the product. Today the wallet
is credited by a **BFF stub** that takes no payment and refuses to run in
production (`AURAT-0007`), so every balance in the app is dev-only.

Minted 2026-08-14 because the PSP had been referenced across a dozen documents
for months — as the reason things were deferred — without ever having an ID of
its own. This is that ID.

## Why it exists

Things already waiting on it, each recorded elsewhere:

- **The Top Up sheet is theatre.** It shows amounts and a "Visa ···· 4242" row
  and credits the wallet without charging anyone (`AURAT-0007`, `AURAT-0019`).
- **The Review screen's card row** ships **disabled, marked "Soon"**
  (`AURAT-0016`). The owner chose to keep it visible as a signpost; this feature
  is what turns it on.
- **`AURAD-0008` deferred the whole booking half** because the design pays by
  card. `AURAD-0009` then removed the PSP from the critical path by paying the
  slot from the wallet — so the card became an *addition* to Review rather than
  a prerequisite for it. That is the shape this feature lands into.
- **BFF `TECH-DEBT #7`** — DB-level append-only enforcement on `ledger_entries`
  is explicitly wanted *before* billing is enabled anywhere real.

## Scope sketch (not a spec)

- Provider choice and its own decision record (fees, EU/SCA, payouts to
  chatters, refunds) — the first real question, and not a technical one.
- Card capture and charge on top-up; the wallet stays the internal rail, so
  sessions and refunds keep working exactly as `AURAD-0009` describes.
- Webhooks and reconciliation: a top-up is only real when the provider says so,
  which makes the credit asynchronous for the first time.
- Refunds to the card vs to the balance — `AURAD-0009` refunds a cancelled
  session to the **balance**; money leaving the product is a different question.
- Production guards: the stub must become unreachable, not merely discouraged.

## NOT in scope

Paying an advisor a slot directly by card (bypassing the wallet). The wallet is
the rail by `AURAD-0002` and `AURAD-0009`; a second rail is a separate decision.

## Open questions

1. Which provider, and does it settle in EUR or USD? The wallet is USD minor
   units end to end (`AURAD-0002`).
2. Does the −$5 first-session credit survive real money, and who funds it?
3. Do chatters get paid through the same provider, or is payout a separate
   rail entirely?

## Состояние (2026-11-11)

**Охват сузился до веба.**
- Android пополняет через Google Play Billing (`AURAD-0010`), iOS — через StoreKit (`AURAD-0017`).
- Карта нужна только на вебе: исследование — `AURAI-0013`, решение — `AURAD-0023`.

**Ответы на открытые вопросы:**
1. **Провайдер и валюта.** Stripe, аккаунт Silvermind OÜ. Цена и зачисление — в USD. Покупатель
   платит в своей валюте через Adaptive Pricing, деньги приходят в USD (multi-currency
   settlement).
2. **Кредит −$5.** Его заменил оффер −50% на первую сессию (`AURAF-0017`, `OFFER.md`). Это скидка
   на списание с кошелька, на PSP она не влияет.
3. **Выплаты советникам** — не через Stripe и не в этой фиче. Советники — команда (Terms §05).

**Задачи** (порядок: контракты и BFF → веб; условия — параллельно):

| ID | Где | Что |
|---|---|---|
| `AURAT-0207` | `aura-bff-manor` | Checkout Session, вебхук, зачисление, статус, отмена, возврат на карту из бэкофиса, диспуты, сверка; контракты |
| `AURAT-0208` | `aura-web-manor` | настоящий `TopUpProvider` вместо фейка, флаг в прод-сборке, отмена, Back из bfcache, правило суммы, строки на 24 языках |
| `AURAT-0209` | `aura-app-manor` | Terms §06–07, Privacy (Stripe), данные продавца (рег. код, адрес, телефон) |
| `AURAT-0211` | `aura-bff-manor` | встроенный Checkout (`embedded_page`): `client_secret` и публичный ключ в ответе старта, контракты `v0.33.0`; после merge `AURAT-0207` (`AURAD-0023`, поправка 2026-11-11) |
| `AURAT-0212` | `aura-web-manor` | форма Stripe в шторке Book без ухода с сайта, CSP для Stripe.js, строки на 24 языках; после merge `AURAT-0208` и `v0.33.0`; с 2026-11-12 — Elements (спека v2 `015`) |
| `AURAT-0213` | `aura-bff-manor` | `ui: 'elements'` (Stripe Elements с Checkout Sessions), контракты `v0.34.0`, лимит частоты старта; пара `AURAT-0212` v2 (`AURAD-0023`, поправка 2026-11-12) |

**2026-11-11:** `AURAT-0207` (`06754f5`) и `AURAT-0208` (`c7912bc`) смёржены и проверены владельцем на
bff-dev / web-dev со Stripe sandbox. Веб принят. Подробности — «Состояние» в `AURAD-0023`.

**2026-11-12:** встроенная форма смёржена.
- `AURAT-0211`: BFF `develop` `6d9ce2b`, контракты `v0.33.0` (`3470114`), выкачена на bff-dev с `pk_test_`.
- `AURAT-0212`: веб `develop` `0e7b88d` — коммиты `6af1bf4`, `8c03c38`, `351dcd3`.
- Код проверен координатором дважды: логика, FSD, читаемость. Проверка владельцем на web-dev — впереди.

**2026-11-12, позже:** смёржены Stripe Elements вместо готовой формы.
- `AURAT-0213`: BFF `develop` `cd0975b`, контракты `v0.34.0`, выкачен на bff-dev.
- `AURAT-0212` v2: веб `develop` `9cf617d`.
- Код проверен координатором: логика, FSD, читаемость.
- Впереди — выкат web-dev и проверка в маноре. Подробности — «Состояние (2026-11-12)» в `AURAD-0023`.

**Ворота live** (`AURAD-0023`):
1. Stripe активировал аккаунт Silvermind OÜ.
2. Опубликован `AURAT-0209`.
3. Закрыт вопрос НДС (`AURAI-0013` шаг 4).
4. Прод-веб работает на `web.aura-app.cc` (`AURAD-0020`).
5. Live-ключи и live-вебхук стоят в прод-BFF.
6. В live включены Adaptive Pricing и методы оплаты.

После этого `main` BFF и веба — через merge gate.
