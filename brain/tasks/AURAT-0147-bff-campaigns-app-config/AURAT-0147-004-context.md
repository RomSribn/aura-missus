# AURAT-0147-004 — context

Дата: 2026-10-31. Код: `aura-bff` `develop` @ `af00d64`, `aura-contracts` `main` @ `9848a02` (`v0.25.0`).

## Цена сессии и оффер
- `session-policy.ts`: `FIRST_SESSION_DISCOUNT_PCT = 50`, комментарий «policy is not config»;
  `firstSessionDiscount` (floor в пользу клиента), `discountForBooking`, `costAfterDiscount`.
- `sessions.service.ts` `getPricing` (гость видит оффер) и `book` → `prisma-sessions.repository.ts`
  `book`: право на оффер решается **под замками** (`firstSessionOfferUsed` в транзакции), в сессию
  пишутся `creditMinor` / `costMinor`. `extend` скидку не даёт (цена × минуты).
- `firstSessionOfferUsed` = «есть сессия с `creditMinor > 0`, кроме полностью возвращённой».
  **Ловушка:** если скидку кампании тоже писать в `creditMinor`, она будет считаться «оффер
  использован». Нужна пометка, чья скидка (колонка на `Session`) и фильтр в предикате.
- `wallet.service.ts`: `firstSessionOffer {active, pct}` в `GET /v1/wallet`.
- Контракт `SessionPricing.blocks[]`: `subtotalMinor`, `creditMinor`, `costMinor` — подписи скидки нет.
  Приложение (`use-booking.ts`, `DurationPicker`, `QuickBookSheet`) рисует `%` из
  `wallet.firstSessionOffer.pct` при `creditMinor > 0`; сумма — из `creditMinor`. Старый клиент при
  скидке кампании покажет верную цену, но `%` / «First Session» может быть не тот (до `AURAT-0148`).

## Бэкофис
- Серверный HTML (`views/*.view.ts`, `html` tagged template), вкладки в `layout.view.ts`
  (`Section`, `Chrome.promoCodes` за `BILLING_ENABLED`).
- Шаблон AURAT-0143: форма → `POST confirm` (ничего не пишет) → `POST` (создаёт; `creationKey`
  против двойной отправки) → страница сущности; гарды `SameOriginGuard → BackofficeSessionGuard`;
  оператор — id + снимок логина без FK (`PromoBatch.createdBy*`).
- Ролей нет; журнала действий нет нигде — будет первый.

## Публичные эндпоинты / ассеты / время
- Публичный шаблон: `advisors.controller.ts` (`@Public()`, ответ одинаков для всех). ETag /
  `Cache-Control` в коде пока не используются.
- Ассеты: «каталог хранит ключи, а не URL» + `*_ASSETS_BASE_URL` (`env.schema.ts:185-206`).
- Бизнес-часовой пояс: `SESSION_SLOT_TIMEZONE` (по умолчанию UTC), `common/time/zoned-date.ts`.

## Клиенты (для формы контракта)
- Веб: CSS-токены `--accent`, `--accent-soft`, `--accent-ink`, `--paper` …, тест контраста ≥ 4.5.
- Приложение: статичный `theme.ts`; сезонные слоты и пресеты палитр — `AURAT-0148` / бриф `AURAT-0150`
  («пресеты палитр `winter`, `valentine`» — палитры живут в клиентах).

## Параллельная работа
- `AURAT-0146` (slave-1) меняет `promo-codes` (вид `public`, формат vanity-кода) и берёт контракты
  `v0.26.0`. Эта задача читает `promo_codes` только для проверки витрины кода — место возможного
  конфликта при мёрже; контракты `v0.27.0` поверх `v0.26.0`, если та смёржится раньше.
- `aura-contracts` — общий клон `/Volumes/Work/personal/ai-manors/aura-contracts` (main @ `v0.25.0`);
  работать в отдельном git worktree, чтобы не мешать slave-1.
