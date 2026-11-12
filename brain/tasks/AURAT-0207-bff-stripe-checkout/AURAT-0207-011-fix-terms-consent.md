# AURAT-0207-011 — fix: галочка согласия с Terms настраивается

Date: 2026-11-11. Решение владельца передано из сессии `aura-app-manor`. Владелец, дословно:
«первый вариант, передай сессии BFF».

## Почему

- Stripe отклоняет `consent_collection.terms_of_service: 'required'`, пока в Dashboard не задана
  ссылка на Terms: «You cannot collect consent to your terms of service unless a URL is set in the
  Stripe Dashboard…» (это и был 503 из шага 010).
- В нашем sandbox («Silvermind OU sandbox», `acct_1UYnZiPzZXCl9nsG`) ссылку задать нельзя:
  Business details пустые, а «Activate products» открывает анкету live-аккаунта. На bff-dev с этим
  sandbox будет то же самое.

## Сделано

- `STRIPE_TERMS_CONSENT` = `required` | `none`, по умолчанию `required` (пустое значение из панели
  тоже даёт `required`).
- `none` с ключом `rk_live_…` / `sk_live_…` (при включённом `CARD_TOP_UP_ENABLED`) — ошибка схемы
  при старте: в live галочка обязательна, это доказательство в диспуте. С `rk_test_…` /
  `sk_test_…` — разрешено, в том числе при `NODE_ENV=production` (bff-dev).
- Адаптер: `consent_collection` уходит в сессию только при `required`; при `none` поля нет.
  Значение передаётся через `StripeCardPaymentsConfig.termsConsent` из `stripe.module.ts`.
- `deploy/env/bff.env.example` — переменная и пояснение; README — одна строка у старта пополнения.

## Проверки

- `tsc`, `eslint` (изменённые файлы), `nest build` — чисто. Prettier — только на изменённых;
  чужие строки, которые он переформатировал в `env.schema.spec.ts` и README, возвращены.
- Jest по `config/env.schema` и `stripe`: все зелёные (+9: умолчание и пустое, `none` с двумя
  тестовыми ключами, `none` на bff-dev, отказ с двумя live-ключами, отказ на чужое значение;
  адаптер без `consent_collection`).
- Полный Jest после шагов 010 и 011: **195 наборов, 2981 тест, все зелёные**. В первом прогоне
  под нагрузкой упали 3 теста вне карточного кода (среди них `erased-identities.service.spec.ts`).
  Отдельно этот набор зелёный, повторный полный прогон — тоже.

## «Проверка в маноре» — добавлено

- На bff-dev в Coolify — `STRIPE_TERMS_CONSENT=none`, пока у sandbox нет ссылки на Terms.
- В live ссылка появляется при активации аккаунта; там переменную не задавать (или `required`).

## Дальше

Stage, просмотр владельцем. Шаг мёржа — следующий номер.
