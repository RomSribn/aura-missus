# AURAT-0068-002 — Что уже есть

Дата: 2026-09-14
Слот: `aura-app-manor/slave-0`, ветка `feature/AURAT-0068-app-staging-target`
от `develop` = `cf08f8d`. Brain — `67c462b`.

Задача свежая: папки под `staging` нет ни в `tasks/`, ни в `features/`.

## Родственное, на что задача опирается

| Что | Где | Зачем здесь |
|---|---|---|
| Резолвер targets и его отказы | `AURAT-0028` | заложил `env/.env.<target>`; в `004-context` / `005-spec` прямо записано, что release-бандл «pointed at staging» должен выражаться — эта задача его и выражает |
| Биллинг в каждом AAB | `AURAT-0036-008` (`ec6e7f0`) | решение владельца: флаги включает команда сборки, закоммиченные значения остаются `false` |
| Dev-окружение на `bff-dev.aura-app.cc` | `AURAI-0004` | состав окружения и адрес |
| Команды сборки AAB | `AURAS-0002` шаг 3 | предписывает `AURA_ENV=prod ./gradlew :app:bundleRelease` — после этой задачи неверно |

## Состояние кода

- targets: `dev`, `prod`, `tunnel`; `env/.env.prod` = `https://bff.aura-app.cc`.
- `package.json`: `aab` / `apk` = `AURA_ENV=prod` + оба billing-флага инлайном.
- Старый домен в исходниках — только в `env/.env.prod` и в тесте на него.

Дальше: `003-understand`.
