# AURAT-0207-010 — fix: причина отказа Stripe в логе (живой тест)

Date: 2026-11-11. Находка из живого теста с локальным вебом: по слову владельца «запусти бек и веб
со слейвов» сессия `aura-app-manor` запустила BFF из этого слота на sandbox.

## Что было

- Старт `POST /v1/wallet/top-ups/card` ($5) → 503 «Card payments are unavailable right now».
- В логе только «Stripe refused the Checkout Session for card top-up …» — без причины.
- Тот же запрос к sandbox через MCP: «You cannot collect consent to your terms of service unless a
  URL is set in the Stripe Dashboard…». Код верен, это настройка Dashboard: ссылку на Terms
  вписывает владелец (уже есть в списке «Проверка в маноре»).

## Исправлено

- `CardPaymentRejectedError` несёт `code` и `param` Stripe (если он их назвал); `translate` в
  адаптере их передаёт.
- `rejectionReason` (`card-top-up-rules.ts`, чистая функция) — `code=… param=… — <текст>`; адреса
  почты в тексте заменяются на `<email>`: Stripe повторяет отклонённое значение («Invalid email
  address: …»), а email покупателя — единственное PII, которое мы ему передаём.
- Лог отказа при старте (`error`) — с этой причиной. Возврат из бэкофиса не менялся: там текст
  Stripe и так показывается оператору.

## Проверки

- `tsc`, `eslint` (изменённые файлы), `nest build` — чисто; prettier — только на изменённых.
- Jest по `stripe` и `wallet/card*` — 5 наборов, 217 тестов, все зелёные (+5: `rejectionReason` ×3,
  адаптер сохраняет `code`/`param`, сервис пишет причину и не пишет адрес).

## Дальше

Stage, просмотр владельцем. Шаг мёржа — следующий номер.
