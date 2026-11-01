# AURAT-0147-021 — Живая проверка на bff-dev, часть 1 (манор)

Дата: 2026-11-01. `develop` @ `c8d78cf`, выкачен Coolify (~2 мин). Проверял манор (manor-70).

## Без кампании — ✓
- `GET /v1/app-config` → 200 `{"season":null,"promo":null,"discount":null}`,
  `cache-control: public, max-age=60`, `ETag: W/"…"`, `If-None-Match` → **304**.
- Pricing (sunshine) → `blocks[].discount` = `{kind:"first_session", pct:50, label:null}`.
- Бронь с `expectedCostMinor=999` → **409 `session_price_changed`**; с верным 1300 при балансе $0 →
  402; баланс 0, оффер активен (ничего не списано).

## Кампания владельца — ✓
Сезон `winter` + витрина `WINTER5` ($5) + скидка 20% «Winter sale», окно до 2026-11-04T00:00Z.
- `app-config`: `season` (preset `winter`, palette — 17 токенов, art hero + ticket, copy — 9 ключей,
  effect `snow`), `promo` `{code:"WINTER5", amountMinor:500, headline:"$5 on your balance"}`,
  `discount` `{label:"Winter sale", pct:20}` — у всех трёх один `campaignId` и один `endsAt`.
- Pricing у пользователя с живым оффером → по-прежнему `first_session` 50% (большая из двух — верно).
- `WINTER5` тестовым аккаунтом → 200, credited 500, balance 500; `winter-5` и `Winter 5` → 200
  `replayed: true`, та же проводка. Закрывает и непроверенный «replayed» из `AURAT-0146`.

## Не проверено
- Ветка «кампания выигрывает цену»: у обоих тестовых аккаунтов оффер активен, а потратить его без
  оплаченной брони нельзя. Нужен аккаунт с использованным оффером (у владельца): pricing должен дать
  `{kind:"campaign", pct:20, label:"Winter sale"}`, после брони оффер не меняется.
- Гонки порога, отпечаток L3, psql — дальше (`-019`).
