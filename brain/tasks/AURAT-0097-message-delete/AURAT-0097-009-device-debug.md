# AURAT-0097-009 — Debug-сборка на телефон (bff-dev)

Дата: 2026-10-18

Владелец: «поставь дебаг версия на телефон, я проверю удаление на устройстве,
бек вливает свои изменения в дев, поставь дебаг сборку на bff-dev».

- Код — staged-состояние slave-0 (не закоммичено), как в `AURAT-0093-015`.
  Отступление от правила слотов (Metro в слоте) — по прямой просьбе владельца.
- На 8081 уже висит Metro манора (с 2026-10-15, код manor master) — не тронут.
  Свой Metro из `slave-0/master` на **8082**:
  `AURA_ENV=staging AURA_BILLING_ENABLED=true AURA_STORE_BILLING_ENABLED=true
  npx react-native start --port 8082 --reset-cache`; `adb reverse tcp:8082 tcp:8082`.
- `run-android --port 8082 --no-packager --deviceId R58M37RG00M` с тем же env →
  BUILD SUCCESSFUL, установлено `cc.silvermind.aura` 1.0.2 (debug), бандл отдан
  Metro 8082, JS стартовал. Приложения на телефоне до этого не было — вход заново.
- BFF: `AURAT-0098` смержена и запушена в `origin/develop` (`bb00d30`); выкатку
  на bff-dev (Coolify) отсюда не видно.

Дальше — проверка владельцем по A6 спеки.
