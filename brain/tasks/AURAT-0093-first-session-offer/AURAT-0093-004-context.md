# AURAT-0093-004 — Контекст

Дата: 2026-10-17

## Сервер (`aura-bff` @ `a474b40`) — как устроен кредит $5 сейчас
- `src/modules/sessions/session-policy.ts:12` — `FIRST_SESSION_CREDIT_MINOR = 500`
  (`AURAD-0009`); `creditForBooking` = `min(500, subtotal)`; `costAfterCredit`.
- Это **скидка на списание, не деньги в кошелёк**: в леджере строки нет, след —
  колонка `sessions.creditMinor`. Возврат при отмене считается от `costMinor`,
  поэтому скидка никогда не возвращается деньгами.
- Право на кредит: нет ни одной сессии с `creditMinor > 0`; повторная проверка
  внутри транзакции брони под локами (гонка двух первых броней закрыта).
- Отмена кредит **не восстанавливает** — решение владельца в `AURAT-0023`.
- Продление (`extend`) — по полной цене, без кредита.
- `GET /v1/advisors/:id/sessions/pricing` → `{ priceMinorPerMinute, blocks:[{minutes,
  subtotalMinor, creditMinor, costMinor}] }`; длительности из env
  `SESSION_BLOCK_MINUTES` (`10,20,30`).
- Деск чаттеров: чип «Trial» = `creditMinor > 0`.
- Цены советников: 220…380 центов/мин.
- Константа политики, не env — сознательно.

## Контракты (`aura-contracts` @ `v0.20.0`, отдельный репозиторий)
- `SessionPricing.blocks[].creditMinor` — «flat first-session credit».
- `Session` DTO без `creditMinor`/subtotal. `WalletResponse` — `{balanceMinor, currency,
  purchaseAccountId?}`. `Advisor.priceMinorPerMinute` — единственная цена.
- Признака «оффер активен» на уровне пользователя нет нигде.

## Приложение (`aura-app` @ `d2bba51`)
- Клиент ничего не считает: `creditMinor` читается только на Review
  (`BookReviewScreen.tsx:113`, строка «First-session credit −$5.00»).
- Цены рисуются: `AdvisorRow.tsx:40` (в строке роли), `StatsCard.tsx:24`,
  `BookSessionScreen.tsx:63,114`, `DurationPicker.tsx` (цены нет, только минуты),
  `BookReviewScreen.tsx:101-126,185`, `QuickBookSheet.tsx:116,146`,
  `SessionDetailScreen.tsx:93`, приглашение в чате (`AURAF-0013`).
- Нет i18n — копирайт английский в компонентах/`config/copy.ts`.
- Есть `Gradient` (svg), `Pill`, `AuraIcon` (без `percent`/`sale`), `formatUsdMinor`.
  Общего стиля зачёркивания нет (локальный в `RescheduleScreen.tsx:270`).
- Порт дизайнера `rn/AuraOffer.tsx` тянет `expo-linear-gradient` — в проекте его
  нет, заменяется нашим `Gradient`.

## Дизайн (`design_handoff_aura 2/OFFER.md`, экраны 42–46)
- −50% на всю первую платную сессию, автоматически; расходуется при оплате;
  **возвращается при отмене с полным возвратом (≥24 ч)** — противоречит
  `AURAT-0023` (см. открытые вопросы спеки).
- Данные: `User.firstSessionOffer {active, pct}`, сервер переоценивает.
- Компоненты `PriceTag` / `OffChip` / `CouponTicket`; без таймеров и фейковых
  счётчиков.
- В прототипе длительности 30/45/60 и цены $0.99–$2.99 — иллюстрация, у нас
  10/20/30 и $2.20–$3.80.

## Важное из `AURAI-0005`
Цель — снять барьер первой оплаты. Но даже с −50% самый дешёвый блок (ivan, 10 мин)
= $11.00, а минимальный тир пополнения — $10. Барьер «положи $25» снижается, но
не исчезает — вынесено в открытые вопросы.
