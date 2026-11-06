# AURAT-0166-009 — approved

Дата: 2026-11-06. Статус: **done**.

- Владелец: проверка в маноре — «Принято» (de / el / hu / ga / pl: плитки PayCompact, кнопки оплаты, баннер и лист
  платной сессии, промокод, минус у сумм и «−50%»).
- Код в develop @ `dc98590` (`692c496` + мёрж develop `d2b1430`), вместе с `0165`.
- `AURAF-0023` шаг 3: `AURAT-0166` — done.

## Хвосты (не блокируют)
- Тост промокода `credited` «+{{amount}} added to your balance» — плюс приклеен к сумме (nl «+US$ 5», CLDR —
  «US$ +5»). Владелец предложение поправить не выбрал — оставлено как есть; при правке нужен компактный вариант
  `formatUsdMinorSigned`.
- `entities/campaign` fr `discountTitle` — U+202F перед % (из `0161`); остальные fr-строки — U+00A0.
- Носитель: список в `007` («Для носителя»), `translate.mjs review` — store-topup / promo-code / paid-session.
- `TECH-DEBT.md` строка 13: «Half price» при любом `pct`.
