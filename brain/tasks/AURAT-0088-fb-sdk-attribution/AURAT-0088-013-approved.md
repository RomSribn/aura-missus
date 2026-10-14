# AURAT-0088-013 — Принято

Дата: 2026-10-14
Статус: **done** — владелец: «принято»

## Итог в Events Manager (2026-10-14, Overview)

| Событие | Total |
|---|---|
| App installs | 1 |
| Activate app | 5 |
| Initiate checkout | 3 |
| Purchase | **3** — три тестовые покупки по $25, каждая ровно один раз |

Параметры покупки (Test events): `fb_mobile_purchase`, `_valueToSum 25`,
`fb_currency USD`, `fb_content_id aura.topup.usd25` — сумма из `creditedMinor`
ответа BFF.

## Критерии `001`

| Критерий | |
|---|---|
| Установка из Play в Events Manager | ✓ |
| Покупка с суммой журнала BFF, ровно один раз | ✓ 3 = 3 |
| Data safety переподана | ✓ на ревью Google вместе с 23 (`012`) |
| Meta в политике приватности | ✓ (`011`) |
| iOS не тронут | ✓ |

## Код

- `aura-app` `develop` @ `b58e24b` (мёрж `3b51203`); подъём версии `3ee5faa`
  (23 / 1.0.2) уходит в `develop` с `wts-release`.

## Хвосты (вне задачи)

- Ревью Google по 23 + декларациям → Publish (владелец).
- Complete Registration не проверен вживую — нужен вход с новым номером;
  покрыт тестом `CreateAccountScreen`.
- Возражение по письму технически не исполнимо без переключателя в
  приложении (`011`) — задача по запросу.
- `AURAT-0089` — R8 для release + edge-to-edge (Play, срок Feb 2027).
- Атрибуция на iOS — отдельная задача с ATT и App Privacy.
