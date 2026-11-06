# AURAT-0168-013 — approved

Дата: 2026-11-06 · Status: **done**

Владелец проверил в маноре («увидел, тогда закрываем все норм»): `disabledLanguages` в `/v1/app-config` и в превью
кампании бэкофиса (JSON «Что увидят приложение и веб»), маркеры в истории.

Итог:
- `@aura/contracts` `v0.28.0` — `main` `7055dc9`, тег запушен: `LANGUAGES`, `Language`, `SOURCE_LANGUAGE`
  (литерал), `LANGUAGE_QUERY_PARAM`, `isLanguage`; `Message.marker` + `MESSAGE_MARKERS`;
  `AppConfigDisabledLanguages`, `AppConfigResponse.disabledLanguages`.
- aura-bff — develop `c24d55c` (коммит `6ccfa18`): маркер в `toDto`, `DISABLED_LANGUAGES` → `disabledLanguages`,
  OpenAPI, пин `#v0.28.0`.
- `AURAF-0023`: строка 009 BE ✓; шаг 5 — 0168 done.

Следом (не здесь): резолвер `?lang` + колода — `AURAT-0171` (slave-2); клиенты — `AURAT-0169` / `0170`; язык для
чаттеров (§5 спеки v2, с замечаниями ревью) — после решения 8 владельца. Известное: плавающий
`backoffice-auth.spec.ts` под нагрузкой полного прогона (scrypt против таймаута jest) — не из этой задачи.
