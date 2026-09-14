# AURAT-0068-005 — План реализации

Дата: 2026-09-14
Статус: **ждёт одобрения владельца**

Задача без файла фичи: инфраструктурная правка сборки, продолжение `AURAT-0028`.

## Что меняется

```
env/.env.staging                 новый target: bff-dev, флаги false
package.json                     aab / apk  →  aab:staging / apk:staging   (D1)
env/__tests__/resolve.test.js    состав targets, закреплённый staging-origin,
                                 staging в стороже флагов
env/README.md                    таблица targets, строка prod, раздел о release-сборках
env/resolve.js                   пример в тексте отказа: AURA_ENV=staging (одна строка
                                 сообщения, логика не меняется)
src/shared/config/env.ts         комментарий со списком targets
```

**Не трогается:** `env/.env.prod` (включая его устаревшую шапку — указание
владельца), логика резолвера, `android/`, `ios/`, тест prod-origin
(`resolve.test.js:303–309`).

### `env/.env.staging`

```
# staging — the hosted development environment (Coolify `development`), test data.
# Named `staging` because `dev` already means the BFF on this Mac.
AURA_BFF_ORIGIN=https://bff-dev.aura-app.cc

AURA_BILLING_ENABLED=false
AURA_STORE_BILLING_ENABLED=false
AURA_AUTH_TEST_MODE=false
```

Флаги в файле — `false`, как во всех targets: включает их команда сборки
(`AURAT-0036-008`), сторож в тестах это проверяет. `AURA_BFF_ORIGIN_IOS` не
задаётся — хост один на обе платформы, как у `prod`.

## Решение, которое выношу

### D1 · Как собирать internal testing

**Предлагаю назвать target в самой команде:** `aab:staging` / `apk:staging` с
теми же billing-флагами, что сегодня у `aab`; голые `aab` / `apk` убрать;
`aab:prod` сейчас **не** заводить.

- Привычный `npm run aab` падает громко (`Missing script: "aab"`), а не
  собирает не тот backend. Это тот же принцип, по которому резолвер отказывает
  release-бандлу без `AURA_ENV`: сборка обязана назвать цель. (npm 10.9.8
  новое имя сам не подсказывает — проверено; его называют README и
  `AURAS-0002`.)
- У prod-сборки до запуска нет законного применения: `bff.aura-app.cc` сейчас —
  алиас dev-BFF, который снимут. Команда `aab:prod` заводится при запуске, вместе
  с настоящим продом и решением по биллингу в нём (`AURAS-0002`). До того
  собрать prod можно руками — `AURA_ENV=prod ./gradlew bundleRelease`, README
  это покажет.

Отвергнутые:

| Вариант | Почему нет |
|---|---|
| Переключить `aab` / `apk` на `staging` | Самый короткий дифф, но имя не говорит, куда ходит сборка, и при запуске та же команда снова тихо сменит смысл |
| Оставить `aab` = prod, добавить `aab:staging` | Привычная команда продолжит собирать на уходящий алиас. Такая загрузка в internal testing перестанет работать у тестировщиков в день снятия алиаса, а после запуска будет ходить в настоящий прод |
| Рекомендация + `aab:prod` уже сейчас | Дёшево, но это команда без применения до запуска, а её billing-флаги — решение, которого ещё нет |

## Тесты

- `ships dev, prod and tunnel` → `['dev', 'prod', 'staging', 'tunnel']`.
- Новый `points staging at the hosted development backend`: origin
  `https://bff-dev.aura-app.cc` закреплён литералом (как у prod — переезд надо
  сделать дважды и сознательно), iOS-origin `null`.
- `keeps both rollout flags off in every committed target`: в перечень
  добавляется `staging`.

## Проверка в слоте

- `npm test`, `tsc --noEmit`, `npm run lint`.
- `AURA_ENV=staging npm run env:show` → `bff-dev`, оба флага `false`.
- `AURA_ENV=staging NODE_ENV=production node env/fingerprint.js` проходит
  release-политику; без `AURA_ENV` — отказ, как и был, с новым примером.
- JS release-бандл без Gradle и keystore:
  `AURA_ENV=staging … npx react-native bundle --platform android --dev false`
  → в бандле есть `bff-dev.aura-app.cc` и нет `bff.aura-app.cc`.

`bundleRelease` в слоте не запускается: нативного изменения нет, а подпись
требует keystore вне репозитория — это сборка манора.

## После мержа, в маноре

1. `versionCode 18` — отдельный `build:`-коммит, как 9…17.
2. `npm run aab:staging` → internal testing → установка **из Play**.
3. На устройстве: вход, список советников, сообщение доходит в inbox
   `Aura (dev)` — это проверяет и `bff-dev`, и webhook.
4. Только после того, как тестировщики обновились, — снять алиас
   `bff.aura-app.cc` (BFF-сторона, не эта задача).

Одна вещь, которую стоит глянуть в маноре до сборки: AAB несёт биллинг
включённым, а покупки заработают, только если `BILLING_ENABLED` включён и в
Coolify `development`. Сервер тот же, что отвечал на `bff.aura-app.cc`, так что
при переименовании ничего не должно было поменяться — но `AURAI-0004` заранее
называл эту переменную различающейся в dev.

## Документы при закрытии

`AURAS-0002` шаг 3: команды сборки → `npm run aab:staging`; строка про prod —
«при запуске». Уходит единым missus-коммитом задачи.
