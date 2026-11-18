# AURAT-0209-013 — Проверка манора после одобрения: мелкие правки к `011`

Дата: 2026-11-17. Манор проверил `011` и `AURAT-0216-004` — «всё внесено верно», три мелочи.

1. **§07 «Refunds and your right of withdrawal», первая фраза** противоречила фразе об Apple ниже. Новая
   первая фраза: «Unused credits you bought on the web or through Google Play can be refunded on
   request, at any time and without giving a reason.» Остальное — как в `011`.
2. **App Store на лендинге и в `/delete-account/`** — вопрос владельцу. После `AURAT-0079-012` подачи
   в App Store нет, iOS-пользователей ведём в веб. Предложение:
   - на месте кнопки «App Store · Soon» — кнопка веб-приложения (на iPhone оно работает в браузере);
   - шапка delete-account — «App: Aura (web, Google Play)».

   §12 Privacy («links to the web app and to the app stores») при этом остаётся верной.
3. **`AURAT-0216`**: строка об отмене ссылается и на §06, и на §07 «Booked sessions» — шаг
   `AURAT-0216-005`.

`[MIN]` для лендинга: прод `bff.aura-app.cc/v1/advisors` 2026-11-17 — 8 советников, от $2.20 до
$3.80 в минуту. Строка: «Top-ups from $5 to $120 · sessions from $2.20/min». Если цены изменятся до
публикации, сверить.
