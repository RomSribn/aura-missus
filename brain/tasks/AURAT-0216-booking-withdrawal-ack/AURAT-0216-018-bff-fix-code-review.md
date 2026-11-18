# AURAT-0216-018 — BFF: ревью кода манора, правки

Дата: 2026-11-18. Манор `aura-app-manor` (по слову владельца «передай»): блокирующих ошибок нет, код
совпадает со спекой `014`; lint, typecheck, jest (197 / 3061) и typecheck контрактов — зелёные.

## Внесено

- **Миграция:** в `CHECK consents_kind_references` — `ELSE FALSE` (новый вид без строки в `CASE`
  дал бы `NULL`, а `NULL` CHECK пропускает).
- **Тест env:** заголовок «refuses anything but required, client or none».
- **Один тип канала:** `RequestChannel` в `common/web/web-origins.ts`, `ConsentChannel` — его алиас.
- **Один перенос в колонки:** `consentRow()` в `consents/consent.ts`, используют оба репозитория.
- **Контракты:** `ExtensionConsent` (только `extension-v1`) в `ExtendSessionRequest.consent` — чужую
  версию не пропускает уже схема; 400 `consent_invalid` в сервисе остаётся страховкой (тест на неё
  — с приведением типа). Тест схемы в `src/contracts/session.spec.ts`. README контрактов. У брони —
  без сужения (нужен refine по `startNow`).

Проверки после правок: `tsc`, `eslint`, весь jest — **197 наборов, 3062 теста**, контракты —
`typecheck` и `build`; новый `dist/` снова скопирован в `node_modules` слота.

## Остаётся перед merge (п. 1 манора)

`package.json` BFF закреплён на `#v0.34.0`. После тега `v0.35.0` (с «да» владельца):
`npm install @aura/contracts@github:RomSribn/aura-contracts#v0.35.0` (перепишет lock), `npm ci`,
все проверки заново — иначе чистая установка BFF не соберётся.
