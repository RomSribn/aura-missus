# AURAT-0113-005 — Спека: перенос и продление проверяют занятость человека

Дата: 2026-10-20
Статус: done 2026-10-20 — с поправкой (баланс из `lockWallet`) и расширением (продление), см. `006`; develop @ 4277664, проверено в маноре
Репозиторий: **aura-bff**, ветка `feature/AURAT-0113-bff-reschedule-user-busy`
Фича: `AURAF-0008` (строка 009) · решение: `AURAD-0009` · найдено: `AURAT-0110-005`, пробел №1
Контракты, клиенты, схема БД, миграции — **не меняются**.

## Проблема (из 004)

`book()` отказывает 409 (`UserBusyError`), если у человека уже есть живая сессия с любым
советником на этом интервале. `reschedule()` проверяет только слот советника — через перенос
можно наложить две свои сессии с разными советниками. Замка кошелька, которым `book`
сериализует брони одного человека, у переноса тоже нет.

## Решение

### 1. Одно правило — один построитель `where`

В `prisma-sessions.repository.ts` рядом с `overlapping()` (советник) — `userOverlapping()`:

```ts
const userOverlapping = (input: { userId; startsAt; endsAt }): Prisma.SessionWhereInput => ({
  conversation: { userId: input.userId },
  status: { in: [...LIVE_STATUSES] },
  startsAt: { lt: input.endsAt },
  endsAt: { gt: input.startsAt },
});
```

`book()` заменяет свой inline-`where` на него (поведение то же). `reschedule()` берёт его с
`id: { not: sessionId }` — так же, как сейчас исключает себя из проверки советника. Живые
статусы и полуинтервалы — одни на оба пути: отменённые и завершённые не мешают, встык — можно.

### 2. `reschedule()` — замок кошелька и проверка

Новый вход репозитория: `{ sessionId, userId, walletId, startsAt, endsAt }`; выход —
`{ session, balanceMinor }`, баланс из `lockWallet` внутри транзакции (как `book`/`extend`/
`cancel`).

В транзакции: `lockAdvisor` → **`lockWallet`** (тот же порядок, что в `book`/`extend`, без
дедлоков) → сессия `SCHEDULED` → проверка советника (`SlotTakenError`, как сейчас) →
**проверка человека** (`UserBusyError`) → `updateMany`. Порядок проверок — как в `book`:
сначала советник, потом человек. Пересечение с другой своей сессией у того же советника
по-прежнему отвечает «слот занят» — как в брони.

Ловушка `isOverlapViolation || isUniqueViolation` → `SlotTakenError` — без изменений.

### 3. Сервис

`SessionsService.reschedule()` берёт кошелёк (`getOrCreateByUserId(context.userId)`)
**до** вызова репозитория — только ради `walletId` — и передаёт `userId` + `walletId`.
Баланс в ответе — из репозитория (под замком), не из этого чтения: приложение кладёт его в
общий стор (`use-reschedule.ts:142`), и бронь или пополнение между чтением и транзакцией
дали бы устаревшее значение (поправка владельца). `UserBusyError` → 409 через существующий
`toHttpError`: «You already have a session covering that time» — та же фраза, что у брони.
При 409 ничего не планируется, не уведомляется, не пушится — как при `SlotTakenError`.

### 4. Продление (расширение владельца)

`extendLocked`: после проверки советника и **до** проверки денег —
`userOverlapping({ userId, startsAt: session.startsAt, endsAt: новый endsAt })` с
`id: { not: session.id }` → `UserBusyError` (тот же 409, что у брони). Повтор
(`replaysExtend`) по-прежнему раньше всех проверок; замки уже «советник → кошелёк»; `userId`
приходит в `extend()` из сервиса (`context.userId`). Перехват `isOverlapViolation →
ExtendOverlapsNextBookingError` не трогается. Клиенты не меняются: на 409 продления
приложение закрывает окно и перечитывает сессию.

Абстрактный `SessionsRepository.reschedule` — новый вход и `UserBusyError` в списке
исключений комментария; комментарий `UserBusyError` — «бронь и перенос».

## Файлы

- `src/modules/sessions/prisma-sessions.repository.ts` — `userOverlapping`, `book`, `reschedule`, `extendLocked`.
- `src/modules/sessions/sessions.repository.ts` — сигнатура и комментарии.
- `src/modules/sessions/sessions.service.ts` — `reschedule`, `extend`.
- Тесты: `prisma-sessions.repository.spec.ts`, `sessions.service.spec.ts`.
- Brain: заметка в `AURAF-0008` к строке 009 (BE остаётся ✗ — строка про UI-превью), закрытие задачи.

## Тесты (чистые, в слоте; Prisma на моках)

`prisma-sessions.repository.spec.ts`, новый `describe` на `reschedule`:
- у человека живая сессия с другим советником на новом интервале → `UserBusyError`,
  `updateMany` не вызван;
- `where` проверки человека: `conversation.userId`, только `SCHEDULED`/`ACTIVE`,
  полуинтервал, `id: { not: sessionId }` (пересечение только с собой — разрешено; отменённые
  и завершённые не попадают в запрос);
- свободно → сессия перенесена; замки — советник, потом кошелёк;
- `book` использует тот же `where` (закрепляет общее правило);
- `extend`: следующая сессия человека с другим советником начинается раньше нового конца →
  `UserBusyError`, ledger и кошелёк не тронуты, сессия не изменилась; `where` — расширенное
  окно `[startsAt, новый endsAt)`, без самой сессии, живые статусы (встык — можно,
  отменённые/завершённые не мешают).

`sessions.service.spec.ts`, `describe('reschedule')`:
- передаёт `userId` и `walletId`; баланс в ответе;
- `UserBusyError` → `ConflictException`, без очереди/уведомлений/push;
- баланс в ответе — из репозитория, не из `getOrCreateByUserId`.

`sessions.service.spec.ts`, `describe('extend')`:
- передаёт `userId`; `UserBusyError` → 409 без `scheduleFinish`, sync и push.

Плюс `lint`, `typecheck`, `build`, весь `jest`.

## Проверка в маноре (после merge)

Живой стек, пользователь с деньгами:
1. Бронь у советника A на 10:00, бронь у советника B на 12:00.
2. Перенос сессии B на 10:00 → 409 «You already have a session covering that time»; сессия B
   осталась на 12:00.
3. Перенос B на соседний слот, пересекающий только своё же старое окно (например, на
   шаг сетки позже 12:00) → 200.
4. Отменить A, перенести B на 10:00 → 200.
5. Продление: живая сессия у A, следующая бронь у B начинается сразу после её конца →
   продление A → 409 «You already have a session covering that time»; в `ledger_entries`
   нового `SESSION_CHARGE` нет, баланс и `endsAt` A не изменились.
Выкладка на `bff-dev` — сама, после merge в `develop`.

## Вне задачи

- Пересчёт `endsAt` в `activate` при позднем старте (потолок только по советнику) —
  отдельный долг, записан владельцем в `aura-app-manor`.
- availability и слот самой переносимой сессии — строка бэклога `AURAF-0020` (031–035).

## Решения владельца (2026-10-20)

1. `userOverlapping()` + замок кошелька в переносе — да; баланс ответа — из `lockWallet`.
2. Продление — в этой задаче.
