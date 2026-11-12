# AURAT-0213-009 — Merge

Date: 2026-11-12

Владелец в этой вкладке на «Мёржить в develop и пушить?» — «да».

- `wts-finish slave-2`: `feature/AURAT-0213-bff-stripe-elements-checkout` (3e1bb75) → `develop` merge
  **cd0975b**. Push `develop` в origin прошёл (6d9ce2b..cd0975b). Idle-слоты 1, 3–5 обновлены (slave-1
  свободен: AURAT-0211 выпущена, в `active-work.md` — `free`).
- Missus: «Already up to date» — шаги задачи не коммичены, коммит будет при закрытии. Backup push
  missus дал warning: в manor missus нет коммитов origin/master (non-fast-forward — их пушит
  координатор). На код это не влияет. **Перед `wts-release`:** `git -C …/manor/missus/aura-missus
  fetch` и `merge --ff-only origin/master`. Конфликтов не будет: в ветке задачи только новые файлы.
- Слот остаётся на ветке задачи.
- Новых env нет. Миграция `20261112200000_stripe_elements_checkout` (`ADD VALUE 'ELEMENTS'`)
  применится при старте контейнера (`prisma migrate deploy`).
- bff-dev `/health` → 200. Какая версия выкачена, снаружи не видно.

## Проверка в маноре (bff-dev + web-dev + sandbox, вместе с `AURAT-0212`)

1. bff-dev поднялся после выката cd0975b, миграция прошла.
2. Пока веб не смёржен: hosted и embedded работают как раньше.
3. После веба: кошелёк из шторки → Booked; `4242…`, `…3155` (3DS), `…9995` — отказ на шаге карты.
4. `test+location_NL@example.com` — евро в выборе валюты, зачисление в USD.
5. Смена длительности → новая сессия, старая `expired`; закрыли шторку → `cancel`.
6. Банк (если включён) — уход и возврат на `/checkout`.
7. 21-я новая попытка за 10 минут → 429, веб читает `Retry-After`.
8. Повторный маунт тем же `paymentId` под `rk_test_` → тот же `client_secret`.

Перед live — проверка Terms (шаг 005, раздел «Перед live»).
