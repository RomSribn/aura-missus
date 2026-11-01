# AURAT-0149-007 — execute

Дата: 2026-10-31 · Слот slave-1, ветка `feature/AURAT-0149-web-seasonal-theme`. Не закоммичено — ждёт
просмотра владельцем.

## Сделано (aura-web)

- **Контракт до тега** — `shared/api/contracts-next/`: дословная копия черновика `v0.27.0`
  (`app-config.ts`, `season-contrast.ts` с P1–P20, `SessionPricingNext` с `blocks[].discount`).
  После тега — бамп `@aura/contracts` отдельным коммитом, папка удаляется.
- **`entities/season`** (новый слайс): `getAppConfig` (публичный, разбор по частям: кривая/неполная
  палитра → нет сезона, promo/discount живы; лишние поля отбрасываются; палитра без контраста —
  отказ); `useSeason` (каждая часть гаснет по своему `endsAt`, таймер ограничен 2³¹ мс);
  `paintSeason` / `rememberSeason` / `paintKeptSeason` (17 `--season-*` + `data-season` на `<html>`,
  кэш в `localStorage` с `endsAt`, истёкший/битый удаляется); `useSeasonDocument` (ответ красит или
  снимает, перечитывание при возврате на вкладку через 5 мин); `ticketKind` (ничья 50 = 50 →
  discount); частицы (сид Park–Miller из прототипа, 14 шт., ≤ 12 с); `SeasonHero`, `SeasonTicket`.
- **Пять мест:** hero на Home (200 / 164 px по `seasonal.css`, арт, частицы, reduced motion);
  `CouponTicket` — виды welcome / discount / code, цвета `--season-ticket-*`, глиф `art.ticket`;
  орб логотипа; Daily banner (фон, Free, свет, веер); активный пункт навигации. Без сезона значения
  `--season-*` = сегодняшние токены. При `data-season`: бар `#F4EFE5`, подпись баннера белый 0.70,
  кольцо фокуса баннера белое (фоны контракта). Тени `--shadow-orb-accent`, `--shadow-coupon` — на
  `color-mix` от токенов.
- **Билет** во всех 8 местах через `SeasonTicket` (Book sheet и вход — только welcome); `/me` →
  Coupons показывает «No coupons», только когда билета нет.
- **`/promo/:code`:** `app/promo-link/use-promo-link.ts` (в `AppLayout`, по образцу
  `useBookSheetOnArrival`): адрес → `/`, затем гость — вход `promo` (возврат по `?resume=1`),
  вошедший — шторка `promo` (`features/redeem-promo-code`: `PromoCodeSheet`, ленивая). Сам гасится
  только код, равный `app-config.promo.code`, и только после входа. Код из ссылки чистится как на
  сервере (`codeFromLink`, порт `promo-code-format.ts`), не той формы — шторка пустая.
- **Бронь:** `offerPctFromPricing` больше не считает скидку кампании офером;
  `campaignDiscountFromPricing`; итог брони «20% OFF · Winter sale» (неизвестный `kind` → «20% OFF»);
  цены вариантов зачёркиваются и при скидке кампании.
- **Строки** на 24 языках: `season` (новое), `shared` (`code`, `tapToApply`), `auth-by-phone`
  (`promo`), `redeem-promo-code` (`sheet`), `book-session` (`total.campaign`, `total.discount`).
- Тесты: ticket-kind, parse-app-config, контраст обоих пресетов (P1–P20), частицы, season-document
  (кэш), code-from-link, offer (кампания), booking-total, `app/__tests__/season.test.tsx` (hero,
  один билет, ничья, `/promo` гость / автопогашение / чужой код / кривой код), contrast.test
  (фоны мест = фоны контракта, тени без rgba). Нестабильный `promo-code.test.tsx` (синхронный
  `getByText` после `findByRole`) — исправлен одной строкой.

## Проверки (слот)

`typecheck` ✓, `lint` (eslint + steiger) ✓, `vitest` 106 файлов / 1870 тестов ✓, `build` ✓.
Prettier ругается на 5 файлов, которых задача не трогала (так же на develop).

## Решения по ходу

- `/promo/:code` обрабатывает layout, а не страница: страница ссылки размонтируется до открытия
  диалога, а хост диалогов берёт адрес из React-состояния (переход в transition).
- `409 session_price_changed` (§4, второй этап) — после тега, как в спеке.

## Открыто

- Тег `v0.27.0` и 0147 на bff-dev → бамп контракта, удаление `contracts-next`, `409`, мёрж.
- Строка `AURAF-0022-007` — UI отметится после проверки в маноре.
