# AURAT-0168-010 — ревью кода: правки

Дата: 2026-11-06

Ревью кода от координатора (`slave-1-9e`; владелец: «передавай все сразу»), 6 замечаний, блокирующих нет. Все
приняты и исправлены — до пуша тега, так что это всё ещё `v0.28.0`, не `v0.28.1`.

1. **Контракты** `language.ts`: `SOURCE_LANGUAGE = 'en' satisfies Language` вместо аннотации `: Language` — литерал
   сохраняется, `Exclude<Language, typeof SOURCE_LANGUAGE>` у клиентов не схлопывается в `never`. В `dist`:
   `declare const SOURCE_LANGUAGE = "en"`.
2. Передача для 0169: три места, где ломается проверка типов (`NO_CAMPAIGN`, возврат `parseAppConfig`,
   `activeParts` — пропускать поле) — дописано в «Передачу клиентам» `007-spec-v2.md`.
3. `openapi.ts`: `disabledLanguages.items` — просто `{ type: 'string' }`; «сегодня — коды из LANGUAGES, никогда en» —
   в description, через `SOURCE_LANGUAGE`, без хардкода `'en'`.
4. Превью кампании в бэкофисе показывает настоящий `DISABLED_LANGUAGES` (было `[]`) — превью подписано как кусок
   `GET /v1/app-config`. Тест в `campaigns-admin.service.spec.ts`.
5. `env.schema.ts`: в тексте ошибки — список без `SOURCE_LANGUAGE`; тест. Попутно: refine `code !== SOURCE_LANGUAGE`
   с литеральным типом стал предикатом типа — финальный `transform` переписан через `Set<string>`.
6. `sessions.service.spec.ts`: `it.each` для `started` и `finished` с буквальными текстами в
   `postActivityMessage` и `ingestSystemMarker`.

Проверки: lint — 0; tsc — 0; build — ок; jest — 1974 / 1975. Упал `backoffice-auth.spec.ts` («forgets earlier
failures…» / «stops checking after the allowed failures…») — плавающий и не связанный: файлы бэкофис-входа не
тронуты; отдельно три прогона — 2 зелёных, 1 с падением.
