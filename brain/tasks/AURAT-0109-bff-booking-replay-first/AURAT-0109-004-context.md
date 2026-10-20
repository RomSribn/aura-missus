# AURAT-0109-004 — Context

Дата: 2026-10-20

## Код (ground truth, `develop` @ `4bc1504`)

**`SessionsService.book()`** (`sessions.service.ts:250`), порядок:
`requireAllowedBlock` (400) → `requireBookableSlot` (400: сетка, lead, горизонт; не для
`startNow`) → `requireAdvisor` (404) → `users.ensureUser` → `provisioning.ensureConversation`
(может создать контакт и диалог в Chatwoot) → `wallets.getOrCreateByUserId` (может создать
кошелёк) → для `startNow` `closeSpentSession` → `sessions.book()`.

**`PrismaSessionsRepository.book()`**: транзакция, замок советника, замок кошелька →
`session.findUnique({ conversationId_idempotencyKey })` → нашли — `replayed: true` с
балансом под замком. Тело повтора не сравнивается. На P2002 — `convergeBookRace`.
Уникальность сессии — `@@unique([conversationId, idempotencyKey])`; диалог уникален по
`(userId, advisorId)` — значит, ключ брони однозначно ищется по
`(userId, advisorId, idempotencyKey)` через связь `conversation`.

**`extend()`** (`sessions.service.ts:386`): `requireAllowedBlock` (400) →
`requireOwnedSession` (404 для чужой) → `getOrCreateByUserId` → `sessions.extend()`.
В репозитории (`extendLocked`) повтор уже идёт **до** проверки состояния: ключ брони
против extend → `IdempotencyKeyReusedError`; запись журнала `(walletId, key)` есть →
другой тип/сумма → 409, иначе `replayed: true`. То есть повтор продления после конца
сессии **уже** возвращает исходный результат; мешает только `requireAllowedBlock` до него
(смена `SESSION_BLOCK_MINUTES` между попытками).

Чистые чтения уже есть: `ProvisioningService.findConversation` (только `ensureUser`, без
Chatwoot), `WalletsRepository.findByUserId`, `WalletsRepository.findEntryByKey`.
`BillingEnabledGuard` висит на контроллере — повтор его не обходит.

## Клиенты (только чтение)

- Приложение, `use-booking-confirm.ts`: ключ на попытку; 400/402/404/409 — «окончательно»,
  ключ сбрасывается; сеть/5xx — ключ держится. 400 → `slotGone`. `use-paid-session.ts`
  (extend) — та же схема `DEFINITIVE_STATUSES = [400, 402, 404, 409]`.
- Веб, `AURAT-0107-005` §4: то же, плюс **смена слота или блока ключ не сбрасывает** —
  веб опирается на то, что BFF не сравнивает тело повтора (пробел №2 там же).

## Вывод для спеки

- 409 на повтор с другим телом сломал бы веб: ушедшая бронь + повтор с новым слотом →
  409 → ключ сброшен → вторая бронь. Ровно дефект этой задачи, другой дорогой.
- Существующий повтор внутри транзакции остаётся — он закрывает гонку двух одновременных
  запросов с одним ключом.

Противоречий между источниками нет.
