# AURAT-0079-006 — URL уведомлений Apple проставлены; доставка ещё не подтверждена

Дата: 2026-09-30
Статус: настройка сделана, **проверка доставки не прошла — перепроверить**
Закрывает хвост из `AURAT-0082-009` («задать URL уведомлений V2»).

## Что сделано

**Ручка BFF проверена до того, как на неё направили Apple:**

| Запрос | Ответ | Что значит |
|---|---|---|
| `POST https://bff.aura-app.cc/webhooks/apple` с `{}` | `401` | ручка есть и требует подпись |
| `GET` того же пути | `404` | метод не тот — ожидаемо |
| `POST https://bff.aura-app.cc/webhooks/nope` | `404` | отличие настоящего пути от выдуманного видно |

**URL заданы через App Store Connect API** (`PATCH /v1/apps/6813629245`).
Поля называются «subscription», но это и есть App Store Server Notifications:

```
subscriptionStatusUrl                  = https://bff.aura-app.cc/webhooks/apple
subscriptionStatusUrlVersion           = V2
subscriptionStatusUrlForSandbox        = https://bff.aura-app.cc/webhooks/apple
subscriptionStatusUrlVersionForSandbox = V2
```

Перечитаны обратно — сохранились.

## Чего не получилось

`POST /inApps/v1/notifications/test` на песочнице
(`api.storekit-sandbox.itunes.apple.com`) отвечает:

```
404 {"errorCode":4040007,"errorMessage":"No App Store Server Notification URL
found for provided app. Check that a URL is configured in App Store Connect
for this environment."}
```

Пять попыток за три минуты — одно и то же. При том, что API отдаёт URL как
заданные. Похоже на задержку распространения на стороне Apple, но это
**предположение, а не проверенный факт**.

**Перепроверить так:** повторить тестовое уведомление тем же ключом
(`38A56B99DQ`, issuer `9bc0ba73-046e-410f-9499-ecfedfebab2a`, в теле токена
обязателен `bid: cc.silvermind.aura`). Получен `testNotificationToken` →
`GET /inApps/v1/notifications/test/{token}` показывает, что именно ответила
наша ручка. Пока этого не произошло, **возвраты на iOS вживую не проверены** —
они покрыты только юнит-тестами (`AURAT-0082-009`).

## Состояние продуктов

Все четыре — `MISSING_METADATA`, и не хватает им **только скриншота для
ревью**: локализация (`$10 wallet credit` и описание) и цены заданы 25 сентября
и на месте. Скриншот снимается с экрана пополнения в сборке `1.0.0 (2)`.
