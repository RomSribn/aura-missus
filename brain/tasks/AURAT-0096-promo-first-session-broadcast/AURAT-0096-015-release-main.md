# AURAT-0096-015 — релиз в `main` + prod dry-run

2026-10-17, с подтверждения владельца. Merge-коммит `d771b43` (родители `30930a2` main и
`bce50b6` develop; дерево = develop) → `origin/main` (`30930a2..d771b43`). Рабочая копия manor
не трогалась (`commit-tree` + push).

Выкатка: прод-BFF `de0sra2t2v3utotwvpbnfcsc-190635810875` на `d771b43`; `aura-chatwoot`
(rails + sidekiq) пересоздан, как и ожидалось. `bff.aura-app.cc/health` 200, `chat.aura-app.cc` 200.
Контейнер: `CHATWOOT_ACCOUNT_ID=1`, inbox 2, прод-Postgres `tguxhllbce5dodl7k9bo0q7f`.

## `--dry-run` (prod)
`recipients 77 · skipped: 0 already sent, 2 offer used, 0 no thread · would send 75 (25 without a device)`.

Дальше — только по отдельному слову владельца: `--only <prod-userId владельца>`, затем полный
прогон днём (~75 с при 1 msg/s).
