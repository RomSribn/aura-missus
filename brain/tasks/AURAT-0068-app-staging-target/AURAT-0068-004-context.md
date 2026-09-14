# AURAT-0068-004 — Что показал код

Дата: 2026-09-14

Проверено: `aura-app` (`develop` = `cf08f8d`) — `env/`, `package.json`,
`android/app/build.gradle`, `src/shared/config/env.ts`; brain — `AURAT-0028`,
`AURAT-0036-008`, `AURAI-0004`, `AURAS-0002`.

## 1 · Резолвер — правок кода не нужно, тестам нужны

`resolveAuraEnv` берёт любой `env/.env.<target>`, имя проверяется регэкспом
`^[a-z0-9][a-z0-9-]*$` — `staging` проходит. Release-бандл без `AURA_ENV` и с
`http://` отказывается собираться; у `staging` https, значит ограничений нет.

Но **ломается не только строка 307**. В `resolve.test.js` три места знают
состав targets:

- `:283` `ships dev, prod and tunnel` — `listTargets` сверяется целиком, новый
  файл его роняет;
- `:303` `points prod at the real backend` — prod-origin, **не трогается**;
- `:316` `keeps both rollout flags off in every committed target` — перечисляет
  `['prod', 'tunnel']` вручную; без `staging` в этом списке сторож не покрывает
  новый файл, и `true` в нём прошёл бы молча.

## 2 · Скрипты `aab` / `apk`

Появились в `ec6e7f0` (`AURAT-0036-008`): владелец попросил биллинг в **каждом**
AAB, и флаги стали частью команды, а не памяти. Закоммиченные значения
`false` во всех targets — это закреплено тестом.

Цель у `prod` сейчас фактически пустая: `bff.aura-app.cc` — алиас dev-BFF,
который уберут. AAB, собранный с `prod` до запуска, сначала говорит с тестовыми
данными, а после снятия алиаса — ни с чем. Законного применения у prod-сборки до
запуска нет.

## 3 · Остальные места, которые перечисляют targets

- `src/shared/config/env.ts:9` — комментарий «`dev`, `prod` or `tunnel`».
- `env/README.md` — таблица targets; строка `prod` устарела («**empty** until
  AURAD-0005 hosting exists», адрес закоммичен с `AURAT-0036-008`); фраза
  «Targets that name a single real host — `prod`, `tunnel`».
- `env/resolve.js` — пример в отказе release-бандла без `AURA_ENV`:
  `Example: AURA_ENV=prod ./gradlew bundleRelease`. Тот, кто собрал руками и
  получил отказ, скопирует ровно эту строку — и соберёт на уходящий алиас.

## 4 · Нативная сторона — ничего

Gradle уже учитывает target через `env/fingerprint.js` как вход
`createBundle*JsAndAssets` (`build.gradle:136`), так что переключение
`prod` → `staging` между сборками не упакует прежний JS. iOS читает
`AURA_ENV` из окружения (`ios/.xcode.env.local`) — правок нет.

## 5 · Вне задачи, но рядом

- `versionCode` = 17 (`e33dce8`, 03.09). Поднимается отдельным коммитом
  `build: versionCode N` при сборке в маноре — так сделаны 9…17. Для загрузки в
  internal testing понадобится 18, но это шаг манора при сборке.
- `env/.env.prod`: шапка файла всё ещё рассказывает «Deliberately empty». Не
  трогается — указание владельца.
- Одно окружение под тремя именами: Coolify `development`, домен `bff-dev`,
  target `staging`. Имя `dev` в приложении уже занято локальным BFF на Mac, так
  что расхождение неизбежно — его надо записать в README, а не оставлять
  догадке.
- `AURAS-0002` шаг 3 — команды сборки в brain устареют вместе со скриптами.

Дальше: `005-spec`.
