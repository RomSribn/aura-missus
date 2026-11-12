# AURAT-0211-011 — Approved

Date: 2026-11-12
Status: done

Владелец, дословно (в `aura-app-manor`, передал координатор «Анализ платёжек для aura-web»):
«передай бекам одобрено, остальное по рекомендации». По рекомендации координатора задача принята.

## Что проверено

- Встроенная форма (`ui: 'embedded'` → `embedded_page`) проверена владельцем на web-dev против
  bff-dev (`develop` **6d9ce2b**, `STRIPE_PUBLISHABLE_KEY=pk_test_…` в Coolify). bff-dev поднялся.
- Функционально всё работает: оплата, отмена, вебхук.
- Пункт 6 из шага 010 (повтор «Pay» тем же `paymentId` под `rk_test_`) **через UI не проверен**:
  веб на каждое нажатие делает новый `paymentId`. `retrieve` с `client_secret` для `embedded_page`
  проверен координатором в sandbox через MCP; под restricted-ключом BFF — нет.

## Что дальше

- Замечания владельца были к виду формы, не к BFF. Веб переходит на Stripe Elements: веб
  `AURAT-0212` v2, BFF `AURAT-0213` (`ui: 'elements'`, `aura-bff-manor` slave-2).
- Режим `embedded` в BFF остаётся, пока его не снимут отдельной задачей.
