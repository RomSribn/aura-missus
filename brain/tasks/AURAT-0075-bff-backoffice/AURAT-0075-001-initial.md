# AURAT-0075-001 — Бэкофис BFF: удалённые аккаунты и модерация отзывов

Дата: 2026-09-17
Статус: **заведена, не начата**
Репозиторий: `aura-bff` (`aura-bff-manor`), слот `slave-2`,
ветка `feature/AURAT-0075-bff-backoffice` (от `develop` @ `abe2039`; brain —
от `origin/master` @ `7ef788e`).
ID выдан в `aura-app-manor` (счётчик → `AURAT-0076`, запись в его
`active-work.md`).

## Что сказал владелец (близко к тексту)

> Создать небольшой бекофис без возможности регистрации на самой странице, где
> будет выводиться информация по удалённым аккаунтам, а также возможность
> вручную модерировать комментарии (сейчас только cli версия). Использовать
> дизайн-код нашей aura-app, простой desktop + mobile view. Сделать, чтобы
> доступ был по урле нашего бекенда, типа как сваггер, внутренняя защищённая
> ссылка.

## Фон, переданный вместе с запросом

- Модерация отзывов сейчас — `src/reviews-moderation.ts` + скрипты
  `reviews:pending` / `reviews:publish` / `reviews:decline` (`AURAT-0067`,
  `AURAF-0016`; `quoteStatus` PENDING/DECLINED, агрегаты пересчитываются в
  транзакции). Названо и не сделано: `reviews:hide` (снять строку целиком —
  сейчас только SQL).
- Удалённые аккаунты: `AURAT-0042` (`DELETE /v1/me`, надгробие `deleted:<uuid>`,
  `account:erase -- --user|--phone` в `OperatorCliModule`) и `AURAT-0073`
  (журнал удалений в R2 `aura-erasure-journal`: userId, время, source; правило
  бакета 45 дней).
- Логи и страница — без PII (`AURAT-0074`, правило «Secrets & PII never leak»).
- Дизайн-код приложения: `aura-app/src/shared/config/theme.ts`.
- `develop` деплоится на `bff-dev.aura-app.cc`; прод-переменные — в Coolify.
- `slave-1` числится на старой `feature/AURAT-0058-advisor-reviews`; отзывы уже
  в `develop` через `AURAT-0067` — учитывать при пересечении.

(В фоне указан `AURAF-0014` для отзывов; по brain отзывы — `AURAF-0016`,
сверить в `004-context`.)
