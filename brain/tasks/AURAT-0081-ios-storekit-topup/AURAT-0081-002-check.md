# AURAT-0081-002 — Проверка состояния

Дата: 2026-09-30
Слот: `slave-0`, ветка `feature/AURAT-0081-ios-storekit-topup` (создана, коммитов
поверх `develop` нет). Missus у слотов нет — шаги пишутся в `manor/missus`.

Найдено:

- Папка задачи есть, в ней только `001-initial.md` (заведена 2026-09-25, не
  начата). Кода по задаче нет.
- `AURAD-0017` — принято, пять правил `AURAD-0010` переносятся без изменений.
- `AURAT-0082` (BFF) — только `001-initial.md`: ключ In-App Purchase создан и
  проверен на песочнице 2026-09-30; эндпоинта `POST /v1/wallet/top-ups/apple`
  ещё нет.
- `AURAF-0010-store-billing-topup` — спека рельса Play; iOS там не описан.
- `@aura/contracts` v0.19.0 (последний тег): `GooglePlayTopUpRequest/Response`
  есть, Apple-схем **нет**.

Дальше: разбор задачи.
