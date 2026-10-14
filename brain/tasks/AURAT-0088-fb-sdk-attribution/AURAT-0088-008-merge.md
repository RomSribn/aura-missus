# AURAT-0088-008 — Мёрж

Дата: 2026-10-14

- Владелец просмотрел дифф в IDE, одобрил («ок, одобряю, коммить»), мёрж
  подтвердил отдельным ответом.
- Коммит `3b51203` на `feature/AURAT-0088-fb-sdk-attribution`.
- `wts-finish slave-0` → `aura-app` `develop` `7c12b02..b58e24b`, пуш в
  origin прошёл. slave-1 обновлён. slave-0 остаётся на ветке.
- Missus не закоммичен (коммит один, при закрытии задачи).

## Консоль Meta — сделано владельцем

«Log In-App Purchases Automatically» **выключено** (скриншот, 2026-10-14).
Key hashes оставлены (нужны только Facebook Login). Install Referrer
Decryption Key пуст — для атрибуции через SDK, по нашему пониманию, не нужен;
первое, что проверять, если установки не появятся в Events Manager.

## Осталось до закрытия

- Prod-сборка (`aab:prod`, versionCode 23+) → internal testing → установка
  и события в Events Manager; покупка = запись журнала BFF.
- Политика приватности: Meta + способ отказа.
- Play: Advertising ID «да», Data safety — в той же отправке в production.
