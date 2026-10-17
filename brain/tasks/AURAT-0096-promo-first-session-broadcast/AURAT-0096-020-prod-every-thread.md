# AURAT-0096-020 — прод: рассылка во все диалоги

2026-10-17. `616fdd4` → `develop` @ `37ea006` (`bff-dev`: `--dry-run --every-thread --exclude …` →
1 excluded, would send 2) → `main` @ `7ae4228` → прод `de0sra2t2v3utotwvpbnfcsc-193715114362`.

- Prod dry-run: `78 · 2 excluded · 46 already sent · 2 offer used · would send 51` (= 58 − 7) — сошлось.
- Прогон `--every-thread --exclude cmvcet9ep… --exclude cmvcscstk…`: `sent 51 (33 without a device)`, exit 0.
- Store после: 151 из 164 диалогов держат объявление; **ни одного диалога с двумя копиями**;
  Justine — 0; у исключённых — только 1 сообщение, отправленное первым прогоном в 19:15:49
  (до исключения). Без объявления 13 диалогов: 8 у двух исключённых (5 + 3 — второй открыл ещё
  один во время релиза) и 5 у юзеров с использованным оффером (в т.ч. 3 у Justine).
- Логи прод-BFF: 0 warn/error. Повторный dry-run: `would send 0`.
