# AURAT-0068-016 — Третий мёрж: аватар на Android и versionCode 19

Дата: 2026-09-14

Владелец принял ревью без замечаний и выбрал «мёрж + versionCode 19».

- `4de2342` — `ProfileAvatar`: `source={[source]}`; тест на массив.
  **В коммит не попал комментарий над `source`**, который был в
  застейдженном диффе: файл изменился на диске до коммита (дерево после коммита
  чистое). Не возвращался — объяснение несёт тест
  `the source is an array, so Android keeps the token on the request`.
- `405fcbb` — `versionCode 19`.
- `wts-finish slave-0`: `aura-app` `develop` = **`506a318`**, push в origin
  (`faf0bb8..506a318`). В маноре `build.gradle:100` — `versionCode 19`.

Зависимости не менялись. Слот остаётся на ветке, missus не закоммичен.

Дальше, в маноре: `npm run aab:staging` → internal testing → установка из Play.
Проверка аватара — запросы `GET /v1/avatars/<id>` в логах BFF дают 200, а не 401.
Колода — правка ключей `.png` → `.jpg` в `aura-bff` (другой манор). Вложения —
ждут примера.
