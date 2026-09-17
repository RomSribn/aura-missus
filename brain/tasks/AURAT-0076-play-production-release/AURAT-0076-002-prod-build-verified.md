# AURAT-0076-002 — Шаги A1–A2: прод-сборка 21 проверена против прода

Дата: 2026-09-17
Статус: **сделано** (A1, A2). A3 (payments profile) — ответа владельца ещё нет

## A1. Сборка

- `aura-app` `develop` = `077c3c7` (одобрено владельцем):
  - `aab:prod`/`apk:prod` с `AURA_ENV=prod` и обоими флагами биллинга — явно в
    команде, без опоры на `.local`;
  - `versionCode 21`;
  - `env/README.md`: internal несёт прод-сборки, `prod` — живой бэкенд.
- `npm run aab:prod` в маноре. AAB SHA-256
  `dd3debbb25184a5bdd231966cdae26f9d6532279bb16d7a3dfc4d0ec9e0ca2f2`.
- Проверено до загрузки:
  - `versionCode 21`, `versionName 1.0.0`;
  - подпись — upload-ключ `CN=Aura, O=Silvermind, C=ES`, SHA-256
    `61:C3:F5:87…`, тот, что в Firebase;
  - в JS-бандле `https://bff.aura-app.cc`; `bff-dev`, LAN-IP, туннеля и
    `.invalid` нет. `10.0.2.2` в бандле — строка эмулятора
    `@react-native-firebase/auth`.
- Предупреждение Play «no deobfuscation file» — не проблема: R8 выключен
  (`enableProguardInReleaseBuilds = false`).
- После публикации владельцем API показал: internal — `21 (1.0.0)`,
  `completed`, SHA-256 бандла совпал.

## A2. Проверка на телефоне против прода

Телефон владельца, установка из Play. Манор — по базе (без PII), логам,
очередям, Play API, R2.

| Шаг | Время UTC | Итог |
|---|---|---|
| Вход по номеру `+34` | 12:13:53 | пользователь с uid Firebase и контактом Chatwoot «Aura», имя заполнено. Android-токен пуша зарегистрирован |
| Сообщение ↔ чаттер | 12:14:33 / 12:14:56 | сообщение ушло в Chatwoot, ответ пришёл вебхуком и сохранён. Пуш: `fcm-fanout` выполнен, упавших 0 |
| Покупки $10 и $25 | 12:19:54 / 12:20:25 | `POST /v1/wallet/top-ups/google` → 200. `ledger` TOPUP 1000 и 2500 |
| Состояние у Google | — | `purchaseState 0`, `purchaseType 0` (тестовая, лицензионный тестировщик), потреблены и подтверждены, `regionCode UA` |
| **`obfuscatedExternalAccountId`** | — | **пришёл у обеих и совпадает с `purchaseAccountId` кошелька.** Защита «A не погасит чек B» подтверждена на настоящем чеке (`AURAS-0002`, `TECH-DEBT #17`) |
| Сессия 10 мин, Olivia | 12:20:31–12:30:31 | $3.20/мин = $32.00, кредит первой сессии −$5.00, списано 2700. `FINISHED`/`EXHAUSTED`, возврата нет. Баланс 800 = сумма ledger |
| Удаление аккаунта | 12:31:20 → 12:36:50 | `source APP`. Второй проход через ~5,5 мин поставил `completedAt`, uid и контакт очищены. Firebase: `auth/user-not-found`. Chatwoot: контактов, диалогов и сообщений за день — 0 |
| Остаток после удаления | — | удалены сообщения, диалог, токены, карта дня. Надгробие пользователя: профиль пуст, `firebaseUid` — заглушка `deleted…`. Остались кошелёк, 3 записи ledger, 2 покупки, сессия |
| Журнал удалений | 12:31:19 | `aura-erasure-journal-prod`: 1 объект, `userId`/`requestedAt`/`source: app`, правило `expire-45d` (до 2026-11-01) |
| Логи BFF | всё окно | предупреждений и ошибок 0. Путь `/devices/[redacted]`, заголовков ответа в логе нет |
| Логи Chatwoot | всё окно | `Parameters:`, `with arguments`, `Started`, `INFO`, телефонов — 0. FATAL — только `RoutingError` на шрифты панели (браузер оператора) и предупреждения redis-namespace. **Закрывает последнюю проверку `AURAT-0074`** |

Временный файл с токенами покупок в прод-контейнере удалён сразу после
проверки.

## Дальше

- A3: payments profile — ответ владельца.
- B: App content, Store settings, карточка.
