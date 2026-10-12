# AURAT-0079-005 — Ключ загрузки сменён; сборка 2 загружена

Дата: 2026-09-30. Записано из `AURAT-0081` (просьба `AURAT-0082-009`).

## Ключи App Store Connect

- **Загрузка сборок:** ключ `Y597YZ5Q6C` (им загружены сборки 1 и 2) заменён
  на **`XHRC8JZJJN`**, файл `~/.appstoreconnect/private_keys/AuthKey_XHRC8JZJJN.p8`.
  Issuer тот же — `9bc0ba73-046e-410f-9499-ecfedfebab2a`. Во всех командах из
  `002` / `003` / `004` подставлять новый ID:

  ```bash
  xcrun altool --upload-app -f <ipa> -t ios \
    --apiKey XHRC8JZJJN --apiIssuer 9bc0ba73-046e-410f-9499-ecfedfebab2a
  ```

- **App Store Server API (In-App Purchase):** `CSNPA77W6Y` заменён, на диске
  теперь `SubscriptionKey_38A56B99DQ.p8` — это забота BFF (`AURAT-0082`).
  `CSNPA77W6Y` засвечен в чате — отозвать в App Store Connect, если ещё не.

## Пункт 8 из `004` — сделан

Сборка `1.0.0 (2)` собрана `npm run ios:archive:prod` и загружена 2026-09-30
(`AURAT-0081-010`, Delivery UUID `152c7d3e-d437-4438-881b-55226e177257`):
только iPhone, покупки StoreKit, прод-BFF. Покупки в песочнице проходят и
начисляются (`AURAT-0082-009`).

## Для отправки на ревью (к пунктам 9 и 12)

Все четыре продукта в App Store Connect — `MISSING_METADATA` (проверено API
2026-09-30): без локализации и скриншота для ревью их не отправить вместе с
версией.
