# AURAT-0137-001 — Initial (исполняется в `aura-web-manor`)

Date: 2026-10-23
Фича: `AURAF-0020` (веб-клиент), строка плана `AURAF-0020-013` — «Карта дня — отдельная
страница с той же анимацией». ID выдан в `aura-app-manor/active-work.md` (абзац
«AURAT-0136 / AURAT-0137»); новых не минтить.

## Слова владельца

> давай тогда занесем это в беклог и продолжим работу по вебу за планом, что там еще
> осталось по имплементации, кроме платежки?

> а как же профайл, редактирования данных?

> Профиль /me (010), Карта дня (013), Контраст (AURAT-0123)

## Контекст из `aura-app-manor` (не слова владельца)

- Три задачи идут параллельно: `AURAT-0136` (/me) — slave-1, `AURAT-0137` (карта дня) —
  slave-2, `AURAT-0123` (контраст) — slave-3. База: aura-web develop `280988a`, brain
  master `9210fc3`.
- Вход только по телефону (`AURAD-0021` — в бэклоге). Оплаты на вебе нет до PSP
  (`AURAF-0009`).
- `AURAT-0123` может поменять цвета текста (токены); 0137 берёт цвета только из токенов
  темы, без литералов, после мёржа 0123 — на её токены. Общие файлы (router, locales,
  layout) — конфликты решает манор при мёрже. Живая проверка — в маноре на web-dev.
- Хендофф веба: на Home тонкий баннер Daily Card (README §2, NAVIGATION: «Daily Card
  banner · “Draw today’s card” — (app feature, v2 on web) → Daily Card ritual»). Баннера
  нет до этой строки (`AURAT-0112-006`).
- BFF: `GET /v1/tarot/daily` (`DailyCardQuery` / `DailyCardResponse`) и
  `POST /v1/tarot/daily/drawn` (`MarkDailyCardDrawnRequest`); оба требуют входа. Что видит
  гость и с какой причиной открывается вход — решить с владельцем на спеке.
- Анимация и поведение — как в приложении (не код): aura-app `src/screens/daily-card`,
  `src/entities/tarot` (daily-card-store, tarot-api); хендофф приложения
  `DAILY_CARD_TAROT.md`, `MOTION_AND_ICONS.md`. Карты таро в вебе есть — пикер расклада в
  чате (`AURAT-0105`); переиспользовать.

## Слот

`slave-2`, ветка `feature/AURAT-0137-web-daily-card` (master и missus), от develop
`280988a` / missus `9210fc3`.
