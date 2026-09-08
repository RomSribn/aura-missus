# AURAT-0063-011 — Проверено в маноре

Дата: 2026-09-08
`aura-bff` `develop` = `d41aa5d`. Контракты v0.16.0 опубликованы тегом.
Стек манора (`docker compose up -d --build`), Postgres 16, всё через тот же
путь, каким это происходит на проде.

## Схема

- **Миграция применилась**: `16 migrations found`, `Applying migration
  20260908120000_user_profile`, `All migrations have been successfully applied`.
- **Колонки те, что заказывали** (`\d users`):

  ```
  displayName    | text     |          |
  email          | text     |          |
  birthDate      | date     |          |          ← DATE, не timestamp
  marketingOptIn | boolean  | not null | false
  ```

  Уникальных индексов прибавилось **ноль**: в `Indexes` по-прежнему только
  `users_pkey` и `users_firebaseUid_key`. Емейл не логин.
- **Рукописный SQL сошёлся с каноничным**: `prisma migrate diff
  --from-config-datasource --to-schema` на живой базе — `No difference detected`.
- **Повторный старт идемпотентен**: рестарт контейнера → `No pending migrations
  to apply`, сид отработал снова, ничего не удвоилось.

## Маршруты

- `/docs-json` знает **`/v1/me`** с двумя глаголами: `GET` (200) и `PATCH`
  (200, 400), с описаниями полей и правил.
- **`GET /v1/me` без токена → 401**, с мусорным токеном → 401
  `{"message":"Invalid or expired token"}`. `PATCH` — так же.
- **Контрольная проверка, ради которой всё затевалось**: `/v1/horoscope` в том
  же стеке отвечает **404** (`AURAT-0039` не построена), а `/v1/me` — 401.
  Разница между «маршрута нет» и «нужен токен» видна на глаз: дыра закрыта
  ровно наполовину, и это та половина, которую закрывали.
- `/health` → `{"status":"ok"}`, `/health/ready` → `{"status":"ok","checks":
  {"database":true,"redis":true}}`.

## Круг записи и чтения на настоящей базе

Тело с настоящими данными через HTTP получить нельзя — BFF проверяет настоящие
Firebase-токены и режима обхода не имеет (та же граница, что в `AURAT-0058`).
Поэтому профиль прогнан через живой Postgres **тем же кодом, что и маршрут** —
`PrismaUsersRepository` из `dist`, а не самодельным запросом:

```
1. ensureUser на новом аккаунте: {"displayName":null,"email":null,"birthDate":null,"marketingOptIn":false}
2. записали 1994-05-21, прочитали: "1994-05-21"
   в колонке DATE лежит: "1994-05-21"
3. после записи имени/емейла/согласия: {"displayName":"Ann","email":"ann@example.com","birthDate":"1994-05-21","marketingOptIn":true}
4. стирание (null): {"birthDate":null,"email":null,"displayName":"Ann"}
5. частичная запись не тронула согласие: {"displayName":"Bea","marketingOptIn":true}
6. два аккаунта с одним емейлом: 2 — конфликта нет
7. повторный вход не стёр профиль: {"displayName":"Bea","email":"same@example.com"}
```

Пункт 7 стоил отдельной строки: `ensureUser` в ветке `update` пишет
`firebaseUid` и `phoneE164` на **каждом** запросе (`AURAT-0050`), и профильные
колонки обязаны это переживать.

### Дата не съезжает ни в одну сторону

Тот же прогон под `TZ=Asia/Tokyo`, `TZ=America/Los_Angeles` и
`TZ=Pacific/Kiritimati` (UTC+14) — во всех трёх `1994-05-21` и на входе, и в
колонке, и на выходе. Это была настоящая опасность, а не формальность: голый
`node-postgres` разбирает `DATE` в **локальную** дату процесса, и на сервере
восточнее UTC день рождения уехал бы на сутки назад при каждом чтении. Адаптер
Prisma отдаёт UTC-полночь независимо от зоны — теперь это проверено, а не
предположено.

## Что в логе и не наше

`fetch failed` / `reconciliation failed for conversation` — `ReconciliationService`
стучится в Chatwoot, которого в локальном стеке нет. Было и до этой задачи.

## Стек

Оставлен поднятым (`localhost:3000`) — если захочешь потыкать сам или проверить
с устройства.

## Осталось

Клиентская половина `AURAT-0062` в `aura-app-manor` теперь разблокирована:
маршрут в `develop` и в проде.
