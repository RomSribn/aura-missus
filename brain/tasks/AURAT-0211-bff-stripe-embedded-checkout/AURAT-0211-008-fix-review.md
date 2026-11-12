# AURAT-0211-008 — Fix: ревью координатора

Date: 2026-11-12

Ревью кода — координатор (`aura-app-manor`, «Анализ платёжек для aura-web»): код принят, ошибок нет.
Передал слова владельца: «передай, остальное по рекомендации». Его прогон: 6 наборов, 384 теста
зелёные. Две мелочи:

1. **Повтор открытой сессии без данных для показа** (embedded без `clientSecret`, hosted без `url`):
   раньше молча шёл в `apply` → `redirect(successUrl)`, а первый старт в том же случае пишет
   `logger.error`. Сделано: `logNothingToShow` — та же ошибка и на повторе; ответ прежний
   (`redirect` на страницу возврата). Тест «says so on a repeat that finds the session open but
   without a client secret».
2. **Проверка в маноре.** Решение 3 подтверждено через MCP, не restricted-ключом. На bff-dev с
   `rk_test_` проверить: повтор «Pay» тем же `paymentId` отдаёт ту же форму — `retrieve` под
   restricted-ключом тоже возвращает `client_secret`. Пункт остаётся в шаге проверки.

Файлы: `src/modules/wallet/card-top-up.service.ts`, `card-top-up.service.spec.ts`.
Прогон: `tsc`, `eslint`, `prettier` (два файла) ок; спека сервиса — 66 тестов зелёные.

Дальше — каждое отдельным «да» владельца в этой вкладке: тег и push `v0.33.0` → BFF на тег →
`pk_test_…` в Coolify bff-dev → merge.
