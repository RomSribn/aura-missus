# AURAT-0149-009 — контракт v0.27.0 и второй этап (409)

Дата: 2026-11-01 · Повод: сообщение манора — `@aura/contracts v0.27.0` выпущен (main `8699e32`,
аннотированный тег). BFF 0147 на `#v0.27.0`, но ещё не смёржен и на bff-dev его нет.

## Сделано (не закоммичено — ждёт просмотра)

- **Бамп** `@aura/contracts` `v0.25.0` → `v0.27.0` (`package.json`, `package-lock.json`) — пойдёт
  отдельным коммитом.
- **Переход на контракт:** `shared/api/contracts-next` удалена; `entities/season`, `entities/session`
  и тесты импортируют `AppConfig*`, `SeasonPalette`, `SeasonCopy`, `fillSeasonCopy`, `SEASON_TOKENS`,
  `seasonPalettePasses`, `checkSeasonPalette`, `SEASON_CONTRAST_PAIRS`, `SessionPricing`
  (с `blocks[].discount`), `SessionDiscountKind` из `@aura/contracts`. Тег сверен с тем, на что
  опирается веб: P1–P20 (20 пар), `seasonPalettePasses` требует все 17 токенов,
  `SESSION_PRICE_CHANGED = 'session_price_changed'`, `BookSessionRequest.expectedCostMinor`.
- **`409 session_price_changed` (спека §4):**
  - бронь шлёт `expectedCostMinor` — `costMinor` выбранного блока, который человек видел (и в
    записи оплаты картой для возврата на `/checkout`; запись старого вида — без него);
  - ответ с этим кодом → исход `priceChanged`: ничего не списано, цена этого советника
    перечитывается (тег `Pricing`), время остаётся выбранным, ключ попытки сбрасывается — следующая
    попытка новая;
  - тексты: «The price has just changed. Nothing was charged — check the new price and confirm
    again.»; после пополнения картой — «… {{amount}} is on your balance …»; на `/checkout` кнопка
    «See the new price» → шторка брони с новой ценой. 24 языка.
- Тесты: 4 прежних теста брони ждут `expectedCostMinor` в теле; новый тест — 409 → текст,
  перечитывание цены, вторая попытка с новым ключом; `pending` — запись старого вида.

## Дальше

Мёрж — после 0147 на bff-dev (спека §6), через подтверждение; затем проверка в маноре.
