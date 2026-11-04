# AURAT-0154-009 — dev-сборка на телефоне

2026-11-04, по просьбе владельца («поставь на телефон дев сборку»; при несовпадении подписи — «удаляй и ставь»).

- adb-сервер завис (400% CPU с 13:42; вероятно, после отключения `/Volumes/Work`, где лежит SDK) — убит и запущен
  заново.
- Манор `develop` @ `a2bbd5a`, `npm ci`. Metro на 8081 с `AURA_ENV=staging AURA_BILLING_ENABLED=true
  AURA_STORE_BILLING_ENABLED=true` (`AURA_I18N_ENABLED` не задан, значит `false`), `adb reverse tcp:8081`.
- `./gradlew assembleDebug` с тем же окружением: BUILD SUCCESSFUL за 7 мин 30 с, `app-debug.apk` 205 МБ.
- На A50 (`R58M37RG00M`) стояла 1.0.10 (versionCode 35) с другой подписью: `INSTALL_FAILED_UPDATE_INCOMPATIBLE`.
  Удалена, поставлена debug 1.0.11 (versionCode 36), запущена.
- Главная открылась на английском, вход был восстановлен системой («Hi, Roman tt»), данные с bff-dev пришли. В меню
  разработчика есть «i18n: next language» и «i18n: pseudo language». Ошибок JS в logcat нет.

Дальше — проверка владельцем по списку из `008`.
