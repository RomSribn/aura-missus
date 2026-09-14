# AURAT-0068-008 — Мёрж

Дата: 2026-09-14

Владелец одобрил ревью без замечаний и мёрж.

- Коммит на ветке: `6b6d9d3` (`feature/AURAT-0068-app-staging-target`).
- `wts-finish slave-0`: `aura-app` `develop` = **`933ca1d`**, push в origin
  прошёл (`cf08f8d..933ca1d`).
- Слот остаётся на ветке до проверки в маноре. Missus не закоммичен — уйдёт
  одним коммитом при закрытии, вместе с `AURAS-0002` шаг 3.

Зависимости не менялись — `npm install` в маноре не нужен. Metro со сбросом кеша
тоже не нужен: смена env-файла сама меняет `cacheVersion`.

Дальше — проверка в маноре по `005`: versionCode 18, `npm run aab:staging`,
установка из Play, вход / советники / сообщение в `Aura (dev)`,
`BILLING_ENABLED` в Coolify `development`.
