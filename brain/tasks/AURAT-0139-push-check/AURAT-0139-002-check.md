# AURAT-0139-002 — check

Дата: 2026-10-25

Задача новая, папки `AURAT-0139-*` в brain не было (ни в локальном клоне манора, ни в
`origin/master`). Связанное — закрытые задачи:

- `AURAT-0005` (BFF, доставка: WS + `fcm-fanout`), `AURAT-0006` (приложение, `features/push`;
  `008-verify-device` — Android A50, пуш в фоне подтверждён через `dumpsys notification`,
  тап по уведомлению «not cleanly exercised»).
- `AURAT-0043` (capability Push, `aps-environment`), `AURAT-0070` (классификация ошибок FCM).
- `AURAT-0079` (релиз в App Store) — в нём загружен ключ APNs (см. 004).

Feature-спеки по пушам нет; отдельную не заводим — это проверка, а не новая функция.
