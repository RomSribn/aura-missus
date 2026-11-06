# AURAT-0168-008 — approval

Дата: 2026-11-06

Владелец одобрил `007-spec-v2.md` («Одобряю»). Контракт `v0.28.0` заморожен: изменение — `v0.28.1` и сообщение в
0169 / 0170 / 0171.

Решения владельца:
1. `disabledLanguages` — env `DISABLED_LANGUAGES` + передеплой (через координатора, подтверждено одобрением v2).
2. Язык клиента для чаттеров — отложен до решения 8 (§5 спеки — набросок и замечания ревью).
3. Резолвер `?lang` (`languageFromQuery`, `@RequestLanguage()`, пайп, `@ApiLanguageQuery()`) пишет `AURAT-0171`
   вместе с первыми маршрутами, по устройству из §2 — здесь его кода нет (правило 8).

Объём реализации здесь: контракты `v0.28.0` (`language.ts`, `Message.marker`, `AppConfigDisabledLanguages`) + BFF
(`session-markers.ts`, `marker` в `toDto`, `DISABLED_LANGUAGES` → `disabledLanguages`, OpenAPI).

Координатору `slave-1-9e` — сообщение об одобрении.
