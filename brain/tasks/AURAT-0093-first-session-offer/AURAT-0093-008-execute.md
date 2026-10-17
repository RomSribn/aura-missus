# AURAT-0093-008 — Исполнение (app, slave-0)

Дата: 2026-10-17
Ветка: `feature/AURAT-0093-first-session-offer` (`aura-app`), **не закоммичено** — на ревью владельца.
Гейты: `tsc` ✓, `eslint src` ✓, `jest` 123 / 869 ✓.

## Что сделано
- `shared`: иконки `percent`, `sale`; токены `theme.offer` (линия зачёркивания,
  размеры купона, тень), градиенты `coupon`, `couponSheen`; `discountedMinor`
  (floor — то же округление, что у сервера; только для цены за минуту).
- `shared/ui/offer`: `PriceTag` (нарисованная коралловая линия 1.6px, stack /
  inline / `struckLast`, dark), `OffChip`, `CouponTicket` (teaser / booking,
  pop-in 450ms + один блик, уважает reduce motion). Все три — no-op при `null`.
- `entities/wallet`: `firstSessionOffer` разбирается локальным `.extend()`
  контрактной схемы (до `@aura/contracts` v0.21.0); `firstSessionOfferPct` в
  сторе; хук `useFirstSessionOffer()`.
- `entities/session`: `sessionSavingMinor(session)` = `bookedMinutes × rate − costMinor`.
- Поверхности: список советников (тизер-купон, цена справа + чип), профиль
  (Per min, тизер «Half price with {Имя}», чип-наклейка на Book), Book a session
  (цена в шапке, купон «Applied · You save», цены на длительностях, «Biggest
  saving», футер итог + зачёркнутый + «You save»), Review (купон, строка
  «Welcome offer · 50% off», Total зачёркнутый + итог, «You save · Free
  cancellation» под CTA), Booked (teal-плашка «You saved»), Quick book sheet
  (купон + цены), приглашение в чате (чип + строка, без цифр — как и раньше),
  детали сессии (строка «Welcome offer saved»).
- После брони со скидкой и после отмены такой сессии — `walletStore.load()`,
  чтобы оффер погас / вернулся везде.
- Старый BFF (плоский −$5, без `firstSessionOffer`) продолжает показываться
  как раньше — строка «First-session credit».
- Workspace: в `.claude/design_handoff_aura/` влиты `OFFER.md`,
  `rn/AuraOffer.tsx`, `prototype/offer.jsx`, иконки, экраны 42–46, §15d README;
  `OFFER.md` — в таблице build rules. `CLAUDE.md` из дропа не копировался.

## Решения по ходу
- Компоненты — в `shared/ui`, а не в `entities/offer` (как было в спеке):
  они чисто презентационные (`pct` пропом), а состояние оффера — часть ответа
  кошелька, и отдельная сущность импортировала бы `entities/wallet` (кросс-импорт
  сущностей). Хук — в `entities/wallet`.
- Контракт сужен: `offerPct` и `discountMinor` не нужны (см. спеку и `AURAT-0094-001`).
- Оффер показывается в бронировании, только если и кошелёк говорит «активен»,
  и pricing реально дисконтирует блок.
- Prettier прогнан только по новым файлам и одному до этого чистому — остальные
  затронутые файлы были неотформатированы до задачи, шум в диффе не добавлял.

## Открыто
- `@aura/contracts` v0.21.0 (`AURAT-0094`) — после тега бампнуть зависимость и
  убрать локальный `WalletWithOffer`.
- Проверка на устройстве — в маноре после мёржа и после выката BFF.
- Барьер тира $10 — отдельная задача, ID не выдан.
