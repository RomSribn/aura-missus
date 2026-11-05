# AURAT-0161-010 — approved

Дата: 2026-11-05. Владелец проверил в маноре — **«Принято»**. Status: **done**.

Итог: entities на 24 языках — названия знаков зодиака и их даты по CLDR (`monthDayRangeLabel`, разделитель
«месяц–день» из генератора), запасные слова билета без сезона (сумма — `formatUsdMinorCompact`), «Change photo»;
`accessibilityLanguage="en"` у сезонной карточки; сжатие строк `CampaignTicket` до 0.85; `no-literal-string` для
`src/entities/**`. aura-app `develop` @ `d361bce`.

Остаётся вне задачи:
- mt и ga названия знаков — проверка носителем (не блокирует);
- `HoroscopeCard` (a11y-склейка, подсказки) — слайс home;
- `accessibilityLanguage` для серверных строк на `CampaignTicket` — следующий шаг.
