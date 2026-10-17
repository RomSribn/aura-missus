# AURAT-0096-019 — `--every-thread` выпущен; add: `--exclude`

2026-10-17, с подтверждения владельца («да, всё цепочкой»): `9758ba8` → `develop` @ `793a8a7` →
`bff-dev` (`--dry-run --every-thread`: would send 2; обычный — 0) → `main` @ `798d44e` → прод.

Прод `--dry-run --every-thread`: `recipients 78 · 46 already sent · 2 offer used · would send 58`
вместо ожидаемых 54 → остановился. Разница — живые юзеры:
- `cmvcet9ep003w01oxbuz7yl04` (с 13:05) открыл 5 новых диалогов в 19:22–19:24;
- `cmvcscstk00jh01r8mzjo7m82` (зарегистрирован 19:24) — 2 диалога (19:25, 19:31).

Владелец: «без этих двух юзеров» → `--exclude <userId>` (повторяемый; с `--dry-run` и отправкой,
не с `--only`), счётчик `excluded` в отчёте. Тесты, README. lint / typecheck — чисто;
`jest` 122 / 1551 — зелёные (`apple-refund.service.spec` один раз упал и при повторе прошёл —
к задаче не относится).
