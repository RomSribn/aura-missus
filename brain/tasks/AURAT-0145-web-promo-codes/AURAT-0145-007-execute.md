# AURAT-0145-007 — execute

Date: 2026-10-28. aura-web `feature/AURAT-0145-web-promo-codes` (не закоммичено,
застейджено). lint, typecheck, `npm test` (98 файлов, 1792 теста), build — зелёные.

## Файлы
- `package.json`, `package-lock.json` — `@aura/contracts` `v0.24.0` → `v0.25.0`
  (`9848a02`). Отдельный коммит (правило 6).
- `shared/api/base-query.ts` — `BffError.retryAfterSeconds`: только у 429, из
  `Retry-After` в секундах (HTTP-дата / мусор → нет). Тесты в `base-query.test.ts`.
- `features/redeem-promo-code/` (новый слайс):
  - `api/promo-code-api.ts` — `redeemPromoCode`; тело `RedeemPromoCodeRequest.parse`,
    ответ `RedeemPromoCodeResponse.parse`; баланс из ответа → `walletBalanceUpdated`
    в `onQueryStarted` (как `extend-session`), ничего не перечитывается.
  - `lib/refusal.ts` — `refusalOf` (по `code`, 429 → минуты ⌈сек/60⌉, мин. 1;
    404 без кода → `unavailable`; прочее → `failed`) + тест.
  - `model/use-redeem-promo-code.ts` — поле, отправка (ref от двойного Enter),
    исход; при успехе / повторе поле очищается, при отказе код остаётся;
    ввод снимает исход. Код — только в поле и в теле запроса.
  - `config/promo-code.ts` — `CODE_MAX_LENGTH` из схемы контракта.
  - `ui/promo-code-field.tsx` + CSS — карточка хендоффа (`tag`, поле, Apply ghost),
    `<form>` (Enter = Apply), `aria-busy`, `aria-invalid` + `aria-describedby`;
    успех / повтор — `role="status"` (teal-ink), отказ — `role="alert"` (`--error`).
    На телефоне поле 44px и 16px (iOS не зумит).
  - `config/locales/` — неймспейс `redeem-promo-code`, en + 23 языка
    (`label` / `placeholder` перенесены из `me-page`, остальное — новые; плюрали
    `tooMany_*` по `Intl.PluralRules` каждого языка). Зарегистрирован в
    `app/config/i18n.ts` и `vitest.setup.ts`.
- `pages/me/ui/me-sections.tsx` — Coupons: купон / «No coupons» + `<PromoCodeField />`
  при кошельке `ready` / `error`; «Coming soon» у поля убран. Ключи
  `coupons.promo`, `coupons.promoPlaceholder` удалены из 24 файлов `me-page`;
  `.promo*` удалены из `me-sections.module.css`.
- `app/__tests__/promo-code.test.tsx` — /me?section=coupons: зачисление (код как
  набран, текст, баланс $50 → $60 в шапке без перечитывания), пустое поле, двойной
  Enter — один запрос, повтор, 5 отказов 409 (текст, код остаётся, ввод снимает),
  429 с `Retry-After` 1790 → 30 min и без него, 404 / 503, кошелёк 404 → поля нет.

## Решения по ходу
- В `006` было «404 → перечитать кошелёк → поле уйдёт» (моя приписка, не слова
  владельца). Не сделано: RTK Query при ошибке перечитывания оставляет прежние
  данные — поле бы не ушло, а текст «Promo codes aren’t available right now.»
  исчез бы вместе с полем. Поэтому 404 при отправке — только текст.
- Обратного отсчёта / блокировки после 429 нет (как в спеке).

## Открыто
- Живая проверка — манор после мёржа: web-dev против bff-dev, тестовый номер, коды
  из бэкофиса bff-dev (успех, повтор, каждый отказ, 429 после 10 неверных кодов,
  `Retry-After` доходит через CORS).
- `AURAT-0144` (app): тексты согласованы владельцем как общие (см. `006`); в
  приложении `Retry-After` тоже не читается — тот же пробел у `http-client`.
- Нативная вычитка новых строк (особенно ga, mt) — не блокирует.
