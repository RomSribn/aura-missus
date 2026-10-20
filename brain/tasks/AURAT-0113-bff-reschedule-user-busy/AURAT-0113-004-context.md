# AURAT-0113-004 — Context

Дата: 2026-10-20

## Код (ground truth, `develop` @ `a4b8e9e`)

**`PrismaSessionsRepository.book()`**: транзакция → `lockAdvisor` → `lockWallet` → повтор →
`overlapping(input)` (слот советника, `SlotTakenError`) → занятость человека: inline
`where { conversation: { userId }, status in LIVE, startsAt < endsAt, endsAt > startsAt }`
→ `UserBusyError`. Комментарий: занятость человека сериализуется **замком его кошелька**.

**`reschedule()`**: транзакция → только `lockAdvisor` → сессия `SCHEDULED` →
`overlapping(...)` с `id: { not: sessionId }` → `SlotTakenError` → `updateMany` по
`SCHEDULED`. Ни проверки человека, ни замка кошелька. На вход — только `sessionId`,
`startsAt`, `endsAt`.

**`SessionsService.reschedule()`**: `requireOwnedSession` (есть `context.userId`) → статус и
4 ч → `requireBookableSlot` → `sessions.reschedule` → активация/напоминание/уведомление/
sync/push → **после** `wallets.getOrCreateByUserId` ради `balanceMinor` в ответе.
`toHttpError` уже переводит `UserBusyError` в 409 «You already have a session covering
that time» — тот же, что у брони.

Порядок замков везде: советник → кошелёк (`book`, `extendLocked`); `cancel` — только
кошелёк. Перенос с замком кошелька после замка советника порядок не нарушает.

## Выводы

- Без замка кошелька проверка в `reschedule` гоночная: бронь у советника B (замки B +
  кошелёк) и перенос у советника A (замок A) не видят друг друга. Значит, переносу нужен
  `walletId` и `lockWallet` — как в `book`.
- Пример общего правила — `overlapping()` для советника и `replaysExtend` (`AURAT-0109`).
  Для человека — такой же построитель `where`, используемый обоими путями.
- Пересечение с **другой своей** сессией у **того же** советника ловит проверка советника
  раньше (`SlotTakenError`) — как и в `book`. Не меняется.

## Соседние пробелы (вне задачи)

- `extendLocked` проверяет только советника: продление может наехать на следующую сессию
  человека с другим советником. Тот же класс дефекта.
- `activate` пересчитывает `endsAt` от позднего старта (с потолком по советнику, не по
  человеку) — сдвиг на величину опоздания свипа, мелочь.
- availability помечает занятым слот самой переносимой сессии — строка бэклога
  `AURAF-0020` (из заглушки).
