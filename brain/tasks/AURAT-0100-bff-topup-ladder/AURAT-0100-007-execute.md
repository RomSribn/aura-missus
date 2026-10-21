# AURAT-0100-007 — Execute

Date: 2026-10-19
Slave: `slave-1`, `feature/AURAT-0100-bff-topup-ladder` (не закоммичено, staged).

## Изменено (`aura-bff`)

- `src/modules/wallet/top-up-tiers.ts` — `TOP_UP_TIERS` строится из лестницы
  `aura.topup.usd1 … usd120` (`usdN` → `N × 100`), потолок —
  `TOP_UP_LADDER_MAX_USD = 120` с обоснованием ($3.80 × 30 = $114). Таблица
  заморожена; `creditForProduct` не менялся (`hasOwnProperty`, единственная
  точка поиска). Комментарий: округление — только выбор продукта в приложении,
  кредит по-прежнему отсюда; BFF выкатывается раньше продуктов в консолях.
- `src/modules/wallet/top-up-tiers.spec.ts` — четыре опубликованных продукта
  запинены отдельно со старым кредитом; вся лестница запинена поштучно; нет
  кредита для `usd0`, `usd121`, `usd9999`, `usd01`, `usd1.5`, `usd-1`, `USD10`,
  пробелов, чужих SKU, прототипных ключей; добавление в замороженную таблицу
  бросает.
- `play-top-up.service.spec.ts`, `apple-top-up.service.spec.ts` — кредит
  `usd1` / `usd29` / `usd120` через оба rail'а рядом с четырьмя прежними.
- `README.md` — строка про таблицу тиров.

Не менялось (проверено, 004): контракты, верификаторы Play/Apple,
refund-обработчики (реверсят сохранённый `creditedMinor`), схема БД, сиды.

## Brain

- Колонку BE строки `AURAF-0019-009` отмечает `aura-app-manor` — файл фичи
  живёт там (как в `AURAT-0098-008`).

## Проверка в слоте

`jest` — 119 suites / 1551 tests passed; `lint`, `typecheck`, `build` — чисто.

## Для манора после мёржа

Dev-токен Play `dev:<purchaseAccountId>:purchased:aura.topup.usd29` на
`POST /v1/wallet/top-ups/google` → `creditedMinor: 2900`; `usd121` → 400.

Next: ревью владельцем в IDE → коммит → merge gate.
