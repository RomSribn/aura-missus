# AURAT-0077-012 — Push-подписки заведены

Дата: 2026-09-18
Делалось после мёржа, потому что подписка прибивает URL маршрута

## Что есть

| Подписка | Эндпоинт | Audience | OIDC как |
|---|---|---|---|
| `play-rtdn-bff-dev` | `https://bff-dev.aura-app.cc/webhooks/play` | тот же URL | `play-billing-api@aura-2781b` |
| `play-rtdn-bff-prod` | `https://bff.aura-app.cc/webhooks/play` | тот же URL | то же |

Обе на теме `play-rtdn`. Проверено чтением: эндпоинт, сервисный аккаунт и
audience у каждой те, что нужно.

Одна тема, две подписки — каждая получает каждое уведомление. Безопасно потому,
что возврат по токену, которого нет в базе окружения, ничего не делает: dev
реагирует на свои покупки, прод на свои.

## Грабли: zsh не разбивает параметр на слова

Первая попытка была циклом с `set -- $pair`. В bash это работает, **в zsh —
нет**: незакавыченный параметр не подвергается разбиению на слова, и имя
подписки вышло `play-rtdn-bff-dev bff-dev`. Pub/Sub отверг оба имени, так что
ничего лишнего не создалось. Команды в `AURAS-0002` переписаны явно, с пометкой
почему.

## Значения для окружений

```
# bff-dev
PLAY_RTDN_AUDIENCE=https://bff-dev.aura-app.cc/webhooks/play
PLAY_RTDN_SERVICE_ACCOUNT_EMAIL=play-billing-api@aura-2781b.iam.gserviceaccount.com

# прод
PLAY_RTDN_AUDIENCE=https://bff.aura-app.cc/webhooks/play
PLAY_RTDN_SERVICE_ACCOUNT_EMAIL=play-billing-api@aura-2781b.iam.gserviceaccount.com
```

`SERVICE_ACCOUNT_EMAIL` одинаков, `AUDIENCE` — разный. Это и есть смысл
audience: токен, выписанный для dev, на проде не примут.

## Порядок

Переменные должны лечь в окружение **до** деплоя: при `BILLING_ENABLED=true`
сервис без них не поднимется. Наоборот — не стартует.

С этого момента Pub/Sub уже пытается доставлять в оба эндпоинта. Пока маршрут
не задеплоен, там 404, Pub/Sub ретраит с backoff и хранит сообщение до 7 суток —
доставит, когда выкатим. За этим всё равно стоит часовой проход, читающий все
30 дней.
