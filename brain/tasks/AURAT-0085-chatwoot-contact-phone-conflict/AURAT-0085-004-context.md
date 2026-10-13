# AURAT-0085-004 — context

## Код (ground truth, `develop` @ 6c4fec0)

- `src/modules/chatwoot/provisioning.service.ts` — `ensureChatwootIdentity`:
  сохранённая пара в `users` → иначе `findContactByIdentifier(uid) ?? createContact(...)`
  → `createContactInbox` при отсутствии source id → `rememberChatwootIdentity`. Никакой
  обработки ошибки `createContact`.
- `chatwoot.client.ts` — `findContactByIdentifier` = `POST /contacts/filter`
  (`identifier equal_to`); `createContact` шлёт `phone_number` только если валидный E.164
  (`validE164` в сервисе); ошибки → `ChatwootApiError(status, path)` без тела (PII).
  Метода «найти по номеру» и «изменить номер» нет; `updateContactName` = `PUT /contacts/:id`.
- `ChatwootContactService.deleteContactsOf(uid)` (AURAT-0042) ищет контакт **по identifier**
  — опирается на инвариант «identifier контакта = Firebase UID его владельца».
- `AccountErasureService` удаляет контакт по `users.chatwootContactId` и по identifier.
  Операторская команда находит аккаунты по номеру (`findByPhone`) — **старую и новую**
  строку сразу, номер в `users` не уникален.
- `users.phoneE164` не уникален; новая строка `users` для нового UID создаётся без
  проблем — падает только Chatwoot.

## Chatwoot v4.15.1 (`chatwoot-manor`, исходники)

- `contact.rb`: `identifier` — уникальный **индекс** в БД (`uniq_identifier_per_account_contact`);
  `phone_number` — уникальность **только Rails-валидацией** (`allow_blank`), индекс не
  уникальный. Формат `\+[1-9]\d{1,14}`.
- `RecordInvalid` → 422 (`request_exception_handler.rb`); `RecordNotUnique` **не
  перехвачен** → 500. То есть при точно одновременной вставке одного identifier
  проигравший получит 500, а не 422.
- `POST /contacts/filter` поддерживает `phone_number equal_to` (значение нормализуется
  к `+цифры`).
- `PUT /contacts/:id` принимает `phone_number` и `identifier` (`permitted_params`);
  пустой номер проходит (`allow_blank`).

## Выводы

- 422 при создании — это либо номер (наш случай), либо identifier (проигранная гонка
  двух первых запросов — **сегодня тоже даёт 500**). Тело ответа мы не читаем (PII),
  различаем повторными поисками.
- Перепривязка контакта к новому UID (вариант из брифа) делает контакт общим для двух
  строк `users` и переносит старые диалоги на новую личность — это по сути слияние
  аккаунтов, т.е. территория нератифицированного **O5**. Альтернатива — «освободить
  номер» у старого контакта (ровно то, что владелец сделал руками на dev) — слияния
  не требует. Выбор — в спеке.
