# AURAT-0085-001 — initial

Дата: 2026-10-12. Слот `slave-3`, ветка `feature/AURAT-0085-chatwoot-contact-phone-conflict`.
ID выдан в `aura-app-manor` 2026-10-12 (здесь не минтим).

Запрос владельца: закрыть **TECH-DEBT #34** в `aura-bff` (полный разбор — в строке #34
`TECH-DEBT.md`).

Суть: `ProvisioningService.ensureChatwootIdentity` ищет контакт Chatwoot только по
`identifier = Firebase UID` (`findContactByIdentifier`), а при отсутствии создаёт новый
с тем же `phone_number`. Если Firebase UID сменился (пользователь удалён в Firebase
мимо BFF — консоль или соседнее окружение с общим Firebase-проектом), Chatwoot отвечает
422 «Phone number has already been taken», и навсегда падают
`PUT /v1/advisors/:id/conversation` (500) и отправка (422 → «The advisor’s desk wouldn’t
take it»). Воспроизведено вживую на bff-dev 2026-10-12 (аккаунт 2, контакт #6;
разблокировано вручную стиранием номера).

Ожидаемый фикс (обсудить в спеке): на 422 при создании (или заранее) найти контакт по
`phone_number` тем же `/contacts/filter`, перепривязать к новому UID (обновить
`identifier`); если другая строка `users` ещё держит этот
`chatwootContactId`/`chatwootSourceId` — отвязать её. Продумать: гонки (параллельные
первые запросы), `null`/невалидный номер, существующие диалоги контакта у старого
пользователя, удаление аккаунта (`AURAT-0042`). Обязательно тест, падающий на старом
коде. По закрытии — отметить #34 оплаченным в `TECH-DEBT.md`.

Спека — на одобрение владельца до кода. Merge gate — только с явного подтверждения.
