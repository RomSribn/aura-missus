# AURAT-0153-007 — execute

## Файлы (aura-web, `features/auth-by-phone`)
- `config/time-zone-regions.ts` — новая таблица «страна → IANA-пояса» для 35 стран `SMS_REGIONS`.
  Собрана из `zone.tab` + старые имена, которые ещё может отдать браузер (`Europe/Kiev`,
  `America/Indianapolis`, пояса, объединённые в 2022, `Europe/Belfast`).
- `config/__tests__/time-zone-regions.test.ts` — ключи таблицы = `SMS_REGIONS`; каждый пояс только у
  одной страны; каждый пояс известен `Intl`.
- `lib/countries.ts` — `preferredCountry({ timeZone, locales })`: пояс → регион локали → ES, ответом
  считается только страна из `SMS_REGIONS`.
- `lib/__tests__/countries.test.ts` — тесты на каждое звено цепочки.
- `model/use-phone-step.ts` — `browserTimeZone()` (`Intl…resolvedOptions().timeZone`, в `try`).

Строки, контракт и BFF не менялись.

## Проверки (slave-1)
`typecheck`, `lint` (eslint + steiger) и `build` прошли. `npm test`: 108 файлов, 1892 теста.
Тесты прогнаны также с `TZ=UTC` и `TZ=America/New_York`: от пояса машины они не зависят.

## Согласование с AURAT-0152
Приложение утвердило цепочку SIM → сеть (только Android) → пояс → локаль → ES. Звенья, общие с
вебом, совпадают. Сессии приложения отправлен путь к таблице поясов, чтобы списки были одинаковые.
В спеке 0152 написано «36 стран», но в обоих репозиториях `SMS_REGIONS` = 35 одинаковых стран.

## Важно для проверки
У этой машины пояс `Europe/Madrid`, поэтому здесь +34 — правильный ответ автоопределения.
Чтобы увидеть другую страну, в маноре задать пояс в Chrome DevTools → Sensors → Location
(Berlin → DE, Kyiv → UA, Moscow → регион локали или ES).

## Сверка с AURAT-0152 (ответ сессии приложения)
Сессия приложения сверила таблицы. Ни один пояс не отнесён к разным странам; 6 канадских поясов с
веба добавлены в aura-app (`e8687a0`), опечатка «36» в спеке 0152 исправлена на 35. В ответ на веб
добавлены ссылки tzdata `backward`, которые были только в приложении: `US/*`, `Canada/*`,
`America/Fort_Wayne`, `America/Knox_IN`, `Navajo`, `GB`, `GB-Eire`, `Eire`, `Iceland`, `Poland`,
`Portugal`. Теперь в обеих таблицах по 133 записи. Тесты `auth-by-phone`, `typecheck` и `lint` после
этого снова прошли.
