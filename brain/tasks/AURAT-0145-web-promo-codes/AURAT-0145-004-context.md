# AURAT-0145-004 — context

## Источники
- `AURAF-0021-promo-codes.md` (high) — фича, BE ✓.
- `AURAT-0143-005-spec.md` §1 (high) — форма контракта; `@aura/contracts`
  `v0.25.0` (`src/promo.ts`) сверен с тегом: `RedeemPromoCodeRequest`
  (`code` 1…64), `RedeemPromoCodeResponse`, `PromoCodeRefusalCode`. Разница
  с `v0.24.0` — только новый модуль (аддитивно).
- `AURAT-0144` (app) — только `001-initial`, текстов ещё нет; веб не ждёт.
- Веб-хендофф: `web/web-sessions.jsx` (Coupons) — `CouponTicket`, под ним
  карточка: иконка `tag`, поле (h 42, r 12, `--line`) «Enter a promo code»,
  кнопка `btn-ghost` «Apply». NAVIGATION §2.10: «Welcome ticket + promo code
  field (Apply)». Состояний (отправка, успех, ошибки) хендофф не рисует.
  Мобильный хендофф — только строка «Coupons & Promo Codes».
- `/Volumes/Work/personal/aura_web` — промокода нет.

## Код (ground truth, develop `d3a1961`)
- `pages/me/ui/me-sections.tsx` → `Coupons`: ticket / «No coupons right
  now.», карточка `.promo` с disabled input и `<Soon />`.
- `entities/wallet`: `useWallet()` (статусы `none/off/loading/ready/error`,
  404 → `off`), `walletBalanceUpdated(balanceMinor)` — кладёт баланс из ответа
  в кэш `getWallet` (его читают `BalanceChip` в шапке и `BalanceCard`).
- `shared/api/base-query.ts`: `BffError { status, code? }` — заголовков не
  несёт; **`Retry-After` взять негде** → нужно расширить `BffError`
  (`retryAfterSeconds` только у 429). В приложении `Retry-After` тоже не
  читается — тот же пробел у `AURAT-0144`.
- Образец мутации с отказом по `code` — `features/delete-account`.
- `shared/ui/Button` (`ghost`, `type="submit"`), `formatUsdMinor` (Intl).
- Аналитики на вебе нет — событий не добавляем.
- Тестов на `/me` Coupons нет.

## Противоречий нет.
