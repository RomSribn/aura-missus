# AURAT-0166-001 — initial

Дата: 2026-11-06. Выдана по просьбе владельца: «да, выдавай и запускай» — на предложение выдать номера и запустить две
из трёх оставшихся задач шага 3 в новых слотах. Запуск — slave-3 (`wts-run`), от `develop` @ `7f58117`.

Шаг 3 фичи `AURAF-0023` — перенос строк. Это задача «деньги» из плана `AURAI-0010` § Recommendation, п. 3. В develop
уже есть: основа i18n, глоссарий, шрифты el/bg, shared-слой, форматтеры CLDR (`formatUsdMinor` / `Compact`),
лист языка, entities (запасной билет промокода), вход. На ревью: `AURAT-0163` — профиль, `AURAT-0164` — витрина.

Что входит; границы уточнить в спеке:
- `features/store-topup` (TopUpSheet), `features/promo-code` (лист промокода и строка «Coupons & Promo Codes» в
  профиле — её оставил `AURAT-0163`), `features/paid-session` (оплата сессии, SessionBlockSheet, checkout).
- `shared/ui/offer`: PriceTag, OffChip, CouponTicket — что осталось после `0157` / `0161`.
- Дизайн: `CHECKOUT.md`, `OFFER.md`.

Известные места (`AURAI-0010-evidence.json`):
- `Pay ${storePrice} & ${verb}`: тип `CheckoutVerb` ('book' | 'start now' | 'extend') используется как текст — нужны
  целые строки на каждый глагол.
- Склейки из фрагментов:
  - «You save {amount} · one-time, new clients»;
  - «Use my balance · {amount}»;
  - «{n}» + « min» в вложенных Text;
  - «You saved ${amount} with ${savedWith}», где `savedWith` — фрагмент или серверная метка кампании;
  - «Half price with ${advisorName ?? 'any advisor'} · no code needed» — имя в падежном слоте, переформулировать;
  - `${discountLine} — applied for you`.
- Узкие места: тег «Biggest saving» (absolute), однострочные плитки оплаты и билеты, корешок билета 74 pt — `@max` и
  замер шрифтом.
- **Платёжные тексты** (оплата, возврат, промокоды с деньгами) — `@sensitive`: до маркетинга в стране нужна проверка
  носителем (решение владельца 7 в `AURAI-0010`).
- `/min` — ключ `shared:price.perMinute` добавляет `AURAT-0164` (ещё не в develop): перейти на него, когда он будет в
  develop.

Правила — раздел «Translations» в `.claude/aura-build-rules.md`:
- все 24 языка в этой же задаче, namespace на слайс;
- глоссарий: `translate.mjs scan … --web <aura-web>`, на вебе есть top-up, redeem-promo-code, checkout;
- деньги — только через форматтеры `0159` с явным языком;
- `@max` и замер, `@sensitive`;
- `i18next/no-literal-string` на `error` для перенесённых путей.

Параллельно: `AURAT-0165` (бронь и сессии) — в slave-2. Общие файлы (`app/i18n/namespaces.ts`, `.eslintrc.js`,
`translations.test.ts`, `shared/config/locales/*`) — конфликт решает та, что мёржит позже.
