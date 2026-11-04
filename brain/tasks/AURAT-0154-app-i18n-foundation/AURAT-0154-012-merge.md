# AURAT-0154-012 — merge (fix 010)

2026-11-04, с одобрения владельца («Да, коммит и мёрж»).

- Коммит `7154504`, `wts-finish slave-1`: aura-app `develop` `a2bbd5a` → `40d0ee7`, запушен в origin. slave-0
  обновлён.
- Манор: watchman перезапущен (`watchman shutdown-server`), Metro поднят заново на 8081 (`--reset-cache`, то же
  окружение staging), `adb reverse`, приложение на A50 перезапущено.
- На телефоне: «i18n: next language» показывает тост «i18n → bg» (скриншот в сессии). Главная остаётся английской,
  её строки ещё не перенесены.
