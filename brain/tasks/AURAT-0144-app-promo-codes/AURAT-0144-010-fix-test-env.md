# AURAT-0144-010 — fix: тест профиля зависел от локального env

Дата: 2026-10-28. Манор после `npm ci`: падает `ProfileScreen.test.tsx` › «the inert rows are gone
from the menu». Тест полагался на `AURA_BILLING_ENABLED=false` из `env/.env.dev`, а в маноре есть
`env/.env.dev.local` с `true` (babel-плагин вклеивает) — строка промокодов появлялась.

Правка: в моке `@/shared` этого теста закреплён `BILLING_ENABLED: false` (как
`ProfilePromoCode.test.tsx` закрепляет `true`).

Проверено в слоте с временным `env/.env.dev.local` (`AURA_BILLING_ENABLED=true`, `--no-cache`):
до правки — 1 падение, после — 14/14 тестов профиля; без локального файла — 14/14. Временный
файл удалён. Коммит в ветке — см. 011-merge.
