# AURAT-0087-012 — iOS 1.0.1 (3) загружена в App Store Connect

Дата: 2026-10-13

Владелец: «собери iOS сборку и залей… там всё ещё ревью идёт», версия
`1.0.1 (3)` — по его выбору (не трогать заявку 1.0.0).

- Состояние до загрузки: версия `1.0.0` `WAITING_FOR_REVIEW`, заявка
  `09e11ae6-…` со сборкой `1.0.0 (2)`. Сборка `1.0.1 (3)` идёт новым поездом
  версий и заявку не меняет; после одобрения и выпуска 1.0.0 — создать версию
  1.0.1 и отправить её.
- Сборка в маноре: `npm run ios:archive:prod` (прод, оба флага биллинга),
  264 с; экспорт `app-store-connect` с `exportOptions.plist` (team
  `6D62F96H2N`, automatic) — шаблон в `AURAT-0079-002`.
- Проверка IPA: `1.0.1 (3)`, `cc.silvermind.aura`, `aps-environment:
  production`, `Apple Distribution: Silvermind OU (6D62F96H2N)`, в бандле текст
  фикса и `bff.aura-app.cc`.
- `altool --upload-app` ключом `XHRC8JZJJN`: **UPLOAD SUCCEEDED**, Delivery UUID
  `c5c3ba46-0861-46c5-9c30-477f3f470931`.
- Версия закоммичена и запушена: `aura-app` `develop` @ `7c12b02`.
- Сразу после загрузки сборка в API ещё не видна (обработка Apple); заявка 1.0.0
  не изменилась.

TECH-DEBT #12 закроется, когда 22 (1.0.1) выйдет в Play и 1.0.1 (3) — в App Store.
