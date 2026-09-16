# AURAT-0072-007 — Исполнено, ждёт ревью

Дата: 2026-09-16
Пишет: `aura-bff-manor` / `slave-3`
Ветка: `feature/AURAT-0072-bff-chatwoot-contact-name`. Не закоммичено,
**застейжено** (`aura-bff`: 28 файлов, +582/−36).

## Ворота в слоте

`lint` · `tsc --noEmit` · `jest` · `build` — чисто. **1004 теста**, 78
наборов (до задачи — 980 и 77). Prettier чист на новых файлах; файлы, которые
до задачи проходили prettier, проходят и после.

## Что сделано — по спеке `005`, Q1 = A

| Слой | Файлы | Что |
|---|---|---|
| Адаптер | `chatwoot.client.ts` | `updateContactName` — `PUT /contacts/{id}` JSON `{ name }`; `request` знает `PUT` |
| | `chatwoot-contact.port.ts`, `chatwoot-contact.service.ts` | `setName`; 404 — успех, остальное бросает |
| | `provisioning.service.ts`, `chatwoot.module.ts` | имя в `createContact`, если есть; после записи идентичности джоба ставится всегда (найденный контакт, гонка с переименованием); сбой очереди логируется по `userId` и глотается |
| Профиль | `profile.service.ts`, `profile.module.ts` | `updateProfile` ставит джобу, если имя изменилось и контакт есть; `pushNameToDesk` читает строку в момент выполнения; `queueNamePushForEveryContact` для дозаливки |
| | `users.repository.ts`, `prisma-users.repository.ts`, `users.service.ts` | `listIdsWithNamedContact` — id с контактом и именем |
| Джобы | `queues.ts`, `contact-name.processor.ts`, `jobs.module.ts` | очередь `contact-name`, джоба `push` `{ userId }`, 5 попыток с backoff |
| Оператор | `contact-names.ts`, `package.json` | `npm run contacts:push-names` / `node dist/contact-names.js` — только ставит джобы |
| | `operator-cli.module.ts` (было `account-cli.module.ts`) | один модуль для обеих операторских команд: добавлен `ProfileModule`, `account-erasure.ts` и тест графа переименованы следом |
| Документы | `README.md` | модуль профиля, абзац про имя на контакте, команда дозаливки |

## Решения по ходу

1. **Операторский модуль переименован**, а не продублирован: `AccountCliModule`
   → `OperatorCliModule`. Второй команде нужен тот же граф плюс
   `ProfileModule`, а «Account» в имени модуля для дозаливки имён было бы
   неправдой. Тест графа проверяет оба сервиса.
2. **Логи — структурные, по `userId`.** Соседний код провижининга пишет id
   шаблонной строкой; имя не попадает в лог нигде, и это проверено тестом на
   `PATCH`.
3. **Дозаливка не глотает отказ очереди**, в отличие от пути пользователя: это
   команда оператора, ей нужно сказать, что джобы не поставились.

## Проверить в маноре после мёржа (`bff-dev`)

1. Новый пользователь с именем пишет советнику — у контакта в Chatwoot есть
   имя.
2. `PATCH /v1/me { displayName }` — имя на контакте сменилось за секунды.
3. `node dist/contact-names.js` — старые тестовые контакты получили имена.
4. Удаление аккаунта сразу после смены имени — контакт удалён и не появился.
5. В логах нет имён.

Дальше: ревью владельцем.
