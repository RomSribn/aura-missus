# AURAT-0216-017 — BFF: execute (по спеке `014`)

Дата: 2026-11-18. Ничего не закоммичено; всё в staged для ревью владельца.

## Контракты `@aura/contracts` `v0.35.0`

Ветка `feature/v0.35.0-consents` в `aura-contracts` (вне манора), **без коммита, тега и push**:
- новый `src/consent.ts`: `BOOKING_/NOW_/EXTENSION_/TERMS_CONSENT_VERSIONS` (`booking-v1`,
  `now-v1`, `extension-v1`, `terms-v1`), `SESSION_CONSENT_TEXTS` (английский текст каждой версии),
  `SessionConsent` / `TermsConsent` `{ version, language }`, `CONSENT_REQUIRED`, `CONSENT_INVALID`;
  JSDoc с правилами для клиентов (поле — только при отмеченной галочке; своё на каждое продление;
  правка текста на любом языке — только с новой версией, 24 перевода закреплены тестами клиентов;
  версия — только из контрактов; `terms-v1` — Terms, опубликованные по `AURAT-0209`);
- `BookSessionRequest.consent?`, `ExtendSessionRequest.consent?`, `CardTopUpRequest.termsConsent?`;
- `index.ts`, `package.json` `0.35.0`, README (таблица модулей + абзац `v0.35.0`);
- `typecheck` и `build` зелёные; собранный `dist/` скопирован в `node_modules` слота.

## BFF (`aura-bff`, ветка `feature/AURAT-0216-booking-withdrawal-ack`)

- **Схема и миграция** `20261118120000_consents`: `enum ConsentKind`, `enum ConsentChannel`,
  `model Consent` (`consents`); `CHECK consents_kind_references` — ровно тот набор ссылок, что
  положен виду; частичный unique `consents_session_booking_key` (одна `BOOKING`/`NOW` на сессию);
  триггер `consents_append_only` (UPDATE / DELETE → `restrict_violation`).
- **Модуль `consents`**: `consent.ts` (типы), `ConsentPolicy` (версия ↔ действие → 400
  `consent_invalid`; веб без согласия при `WEB_CONSENT_REQUIRED` → 400 `consent_required`; приложению
  не отказывает; старт оплаты без `termsConsent` в режиме `client` → 400; `noteMissing` — `info` в
  лог «KIND without consent from CHANNEL: session …»), `ConsentsModule`.
- **Канал**: `requestChannel(origin, WEB_ALLOWED_ORIGINS)` в `common/web/web-origins.ts`.
- **Сессии**: контроллер читает `Origin`; сервис проверяет согласие сразу после ответа на повтор;
  репозиторий пишет согласие брони вложенным `create` в той же вставке сессии, согласие продления — в
  транзакции после строки `SESSION_CHARGE` (ссылки на сессию и строку журнала).
- **Оплата картой**: проверка `termsConsent` — только для новой попытки, до лимита частоты; запись
  `CARD_TERMS` вложенным `create` со строкой `stripe_top_ups`.
- **Stripe**: `STRIPE_TERMS_CONSENT = required | client | none`; `consent_collection` — только в
  `required`; с live-ключом — `required` или `client`.
- **Env**: `WEB_CONSENT_REQUIRED` (`false`); `.env.example`, `deploy/env/bff.env.example`.
- **OpenAPI**: `consent` / `termsConsent` в телах, 400 с кодами в описаниях маршрутов. **README**.

## Тесты

Новые: сервис сессий (13 — бронь / «сейчас» / продление, версии не того действия, требование для
веба, приложение без отказа и с логом, повторы), репозиторий сессий (запись с сессией и с
продлением, нет записи без согласия и при отказе), старт оплаты (6 — запись, 400 в `client` без
строки / Stripe / счёта, повтор, `required` / `none`), адаптер Stripe (`client` без
`consent_collection`), env (`client` с live-ключом, `WEB_CONSENT_REQUIRED`), `requestChannel`.
Весь набор: **197 suites, 3061 tests — зелёные**; `tsc`, `eslint` на изменённых файлах, `nest
build` — чисто. Prettier — только на файлах задачи.

## Не сделано / дальше

- Миграция на живой БД не применялась (слот без БД) — проверка в маноре по `014`.
- Контракты: коммит → merge в `main` → тег `v0.35.0` → push — **отдельное «да» владельца**; затем
  `npm install @aura/contracts@github:RomSribn/aura-contracts#v0.35.0` в BFF (перепишет lock).
- Merge в `develop` — отдельное «да».
