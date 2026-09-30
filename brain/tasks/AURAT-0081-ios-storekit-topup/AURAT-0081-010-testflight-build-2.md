# AURAT-0081-010 — Сборка 2 в TestFlight

Дата: 2026-09-30

По просьбе владельца собрана и загружена из манора (`develop` `c19ffb8`).

- Перед сборкой в маноре `npm ci` — там были контракты 0.19.0, без
  `AppleTopUpRequest` выкуп упал бы в рантайме.
- `npm run ios:archive:prod` → `ios/build/Aura.xcarchive`, `ARCHIVE SUCCEEDED`.
  `ios/.xcode.env.local` — только `NODE_BINARY`, `AURA_ENV` не перебит.
- Проверено в архиве: `CFBundleVersion 2`, `1.0.0`, `UIDeviceFamily [1]`,
  `cc.silvermind.aura`; бандл — Hermes, содержит `https://bff.aura-app.cc` и
  `/v1/wallet/top-ups/apple`; `env:show` с теми же переменными — оба флага
  биллинга `true`.
- Экспорт `app-store-connect` (автоподпись, как в `AURAT-0079-002`) →
  `altool --upload-app`: **UPLOAD SUCCEEDED**, Delivery UUID
  `152c7d3e-d437-4438-881b-55226e177257`.
- `ITSAppUsesNonExemptEncryption = false` едет в `Info.plist`, вопрос про
  шифрование не должен задерживать сборку.

Дальше: владелец проверяет в TestFlight по списку из `009`.
