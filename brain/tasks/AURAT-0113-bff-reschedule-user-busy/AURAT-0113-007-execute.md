# AURAT-0113-007 — Execute

Дата: 2026-10-20
Ветка `feature/AURAT-0113-bff-reschedule-user-busy` (slave-3), изменения **не закоммичены** —
в staged, на ревью владельцу.

## Код (`aura-bff`)

- `src/modules/sessions/prisma-sessions.repository.ts`
  - `userOverlapping()` рядом с `overlapping()`: `conversation.userId`, `SCHEDULED`/`ACTIVE`,
    полуинтервал. Одно правило для `book` (inline-`where` заменён, поведение то же),
    `reschedule` и `extendLocked`.
  - `reschedule`: вход `+ walletId, userId`; замки «советник → кошелёк»; после проверки
    советника — проверка человека с `id: { not: sessionId }` → `UserBusyError`; возвращает
    `{ session, balanceMinor }`, баланс — из `lockWallet` (поправка владельца).
  - `extend`/`extendLocked`: вход `+ userId`; после проверки советника и до денег —
    `userOverlapping` на `[session.startsAt, новый endsAt)` без самой сессии →
    `UserBusyError`. Повтор (`replaysExtend`) — по-прежнему первым; перехват
    `isOverlapViolation → ExtendOverlapsNextBookingError` не тронут.
- `src/modules/sessions/sessions.repository.ts` — `RescheduleResult`, новые сигнатуры
  `reschedule`/`extend`, комментарии (`UserBusyError` — бронь, перенос, продление).
- `src/modules/sessions/sessions.service.ts` — `reschedule`: кошелёк до репозитория (только
  `walletId`), баланс ответа — из репозитория; `extend`: передаёт `userId`. 409 —
  существующий `toHttpError`, та же фраза, что у брони.

## Тесты

- `prisma-sessions.repository.spec.ts` — новый `describe`: `findFirst` отвечает из маленького
  календаря по фактическому `where`, поэтому тесты закрепляют само правило. Перенос: чужая
  живая сессия с другим советником → `UserBusyError`, `updateMany` не вызван; пересечение
  только со своим старым окном — можно; встык — можно; отменённые/завершённые/чужие — не
  мешают; замки советник → кошелёк, баланс из замка. Продление: следующая сессия с другим
  советником раньше нового конца → `UserBusyError`, ledger/кошелёк/сессия не тронуты; встык —
  можно (списание −1000); отменённые/завершённые не мешают. Бронь — тот же отказ.
- `sessions.service.spec.ts` — перенос передаёт `walletId`/`userId`, баланс из репозитория,
  `UserBusyError` → 409 «You already have a session covering that time» без очереди/
  уведомлений/push; продление передаёт `userId`, `UserBusyError` → тот же 409 без
  `scheduleFinish`/sync/push.
- Мутационная проверка: убрать проверку человека в `reschedule` → падает «refuses a window…»;
  убрать `id: { not }` → падает «overlaps only its own old one».
- `lint`, `typecheck`, `build`, prettier — чисто; `jest` — 121 наборов, 1613 тестов, всё
  зелёное.

## Brain

- `AURAF-0008` — абзац под таблицей о едином правиле занятости человека (`AURAT-0113`).
- Спека `005` обновлена по `006`.

## Пересечения с AURAT-0111 (slave-2)

Там `getSession` в `sessions.service.ts` и `describe('getSession')` в его spec — другие
места файлов; методы `reschedule`/`extend` и репозиторий не тронуты. Ожидается чистый
автомерж; проверить при merge второго из двух.

Дальше — ревью владельца в IDE, затем коммит и merge (только с подтверждения).
