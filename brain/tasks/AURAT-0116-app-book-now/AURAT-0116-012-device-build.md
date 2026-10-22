# AURAT-0116-012 — APK на устройство

Date: 2026-10-22

По просьбе владельца в маноре собран `npm run apk:staging` (release, bff-dev) из `develop` @
`551b95e`: 1.0.5 (30), 92.6 MB, сборка 11 мин 30 с.

На SM-A505FN стояла 1.0.5 (30) из Google Play (подпись Play App Signing) → `adb install -r`
отказал: `INSTALL_FAILED_UPDATE_INCOMPATIBLE`. С подтверждения владельца Play-версия удалена
(`adb uninstall`), staging-APK поставлен начисто: вход и локальные данные сброшены. Запуск:
процесс жив, FATAL / ошибок RN в `logcat` нет.

Дальше: проверка владельцем пунктов 1–6 (см. сессию), затем approved + `wts-release slave-1`.
