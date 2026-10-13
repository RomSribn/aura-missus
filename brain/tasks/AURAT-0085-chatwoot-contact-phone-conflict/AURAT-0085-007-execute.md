# AURAT-0085-007 — execute

Дата: 2026-10-12. Вариант B («освободить номер»), по спеке `005`.

## Изменено (`aura-bff`)

- `src/modules/chatwoot/chatwoot.client.ts` — `findContactByPhone` (тот же
  `/contacts/filter`, общий приватный `findContactBy`), `clearContactPhone`
  (`PUT /contacts/:id {phone_number: null}`).
- `src/modules/chatwoot/provisioning.service.ts` — приватный `createContact(user)`:
  на `ChatwootApiError` → перечитать по UID (гонка: 422 или 500); иначе только на 422 и
  при отправленном номере → найти держателя, если его identifier ≠ наш UID — стереть
  номер, `warn {contactId}`, один повтор (на ошибке — снова по UID). Сетевые ошибки
  пробрасываются как раньше.
- `provisioning.service.spec.ts` — 9 новых тестов; на старом сервисе падают 5
  (главный сценарий #34, гонка 422/500, ограничение повтора, гонка на повторе).
- `chatwoot.client.spec.ts` — тело фильтра по номеру, `PUT` без лишних полей.
- `TECH-DEBT.md` #34 — зачёркнуто, «оплачено в AURAT-0085».

## Проверки (слот, чисто)

`tsc --noEmit`, `eslint src/**/*.ts`, `jest` (106 сьютов / 1369 тестов), `nest build` —
зелёные. Попутно в слоте был устаревший `node_modules` и Prisma-клиент (нет
`@apple/...` и `applePurchase` из AURAT-0082) — `npm ci` + `prisma generate`; в git
ничего не добавили.

## Открыто

- Живая проверка — только в маноре после мержа (`bff-dev`, сценарий из `005`).
- Старые строки `users`/контакты после удаления Firebase мимо BFF остаются сиротами —
  вне задачи.
