# AURAT-0096-017 — полный прогон на проде

2026-10-17. Владелец: «да, всё норм, делай рассылку» (пуш и пузырь у себя на телефоне — ок).

- `node dist/promo-first-session.js` в прод-BFF (`de0sra2t2v3utotwvpbnfcsc-190635810875`, аккаунт 1):
  `recipients 77 · skipped: 1 already sent (владелец), 2 offer used · sent 74 (25 without a device)`, exit 0.
- Store: 75 копий объявления у 75 разных юзеров, 19:12:14 (`--only`) … 19:15:55 UTC — все
  вернулись через webhook.
- Логи прод-BFF за прогон: ни одного warn/error.
- Повторный `--dry-run`: `75 already sent · 2 offer used · would send 0`.

Рассылка выполнена. Повторный запуск безопасен (никому второй раз не уйдёт).
