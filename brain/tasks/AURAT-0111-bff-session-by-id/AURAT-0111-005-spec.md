# AURAT-0111-005 — Спека: `GET /v1/sessions/:sessionId` + долг документации контрактов

Дата: 2026-10-20
Статус: done 2026-10-20 (`010`) — решения 1–3 как рекомендовано; contracts `v0.23.0`, develop @ `7625b44`
Репозитории: **aura-contracts** → `v0.23.0` (сначала), затем **aura-bff**, ветка
`feature/AURAT-0111-bff-session-by-id`
Фича: `AURAF-0020`, строки 026 и 024 (колонка BE) · найдено: `AURAT-0107-005` (пробелы №2, №4)
Схема БД, миграции, приложение — **не меняются**.

## Часть A — `aura-contracts` `v0.23.0` (только добавления)

1. `src/session.ts` — новая схема рядом с `ActiveSessionResponse`:
   ```ts
   /**
    * Response of `GET /v1/sessions/:sessionId` — one session of the signed-in
    * user, in its current state. Someone else's session and a missing one are
    * the same 404.
    */
   export const SessionResponse = z.object({ session: Session });
   ```
   Форма совпадает с `FinishSessionResponse`, но схема своя — названа по маршруту, а не
   по чужому действию; `FinishSessionResponse` не трогаю.
2. `BookSessionRequest` — вместо строки «replaying it must never debit twice» правило
   `AURAT-0109` (строка 024):
   > A repeat with the same key answers with the **original** session (current state) and
   > the current balance, *before* the request is checked — a lost response never becomes
   > a second charge, even once the slot has moved inside the lead time. The repeat's body
   > is **not** compared: another slot, block or `startNow` still returns the session that
   > was bought. Clients keep the key until a definite outcome, also across a slot change
   > (web `AURAT-0107-005` §4); turning a mismatch into a refusal is a breaking change for
   > them, made only together.
3. `ExtendSessionRequest` — правило продления **по коду** (здесь оно строже брони):
   > The same key answers with the original extension (current session, current balance)
   > before the request is checked, also after the session has ended. `minutes` **is**
   > compared: the same key with other minutes, or the booking's own key, is 409.
4. `src/chat.ts`, `EnsureConversationResponse` — «Ответ `POST …`» → «Ответ
   `PUT /v1/advisors/:advisorId/conversation`» (`AURAT-0105-006`); остальной текст тот же.
5. README — абзац `v0.23.0`, в таблице модулей `session` += `SessionResponse`, `AURAF-0020`;
   `package.json` → `0.23.0`. typecheck + build.
6. Коммит «Сессия по id на проводе (v0.23.0)» в `main`, аннотированный тег `v0.23.0`.
   **Push `main` и тега — только после AskUserQuestion.**

## Часть B — BFF

- `package.json` / lock → `@aura/contracts#v0.23.0` (после push тега).
- `src/contracts/session.ts` — `sessionResponseSchema = SessionResponse` + тип;
  `openapi.ts` — `sessionResponseOpenApi` (`{session}`, required).
- `sessions.service.ts` — `getSession(auth, sessionId)`: `requireOwnedSession` →
  `{ session: toDto(context) }`. Ничего не ставит в очередь, не трогает Chatwoot и кошелёк.
- `sessions.controller.ts` — `@Get('sessions/:sessionId')`, `sessionIdSchema` в пайпе,
  `@ApiOkResponse(sessionResponseOpenApi)`, `@ApiNotFoundResponse('No such session for
  this user')`. Guard — классовый, как у всех маршрутов; гостю — 401 (без `@OptionalAuth`).

## Тесты (чистые, в слоте)

- `sessions.service.spec.ts` — `getSession`: своя → та же DTO, что `listSessions` для этой
  записи (`userId` не утекает); чужая → `NotFoundException`; несуществующая →
  `NotFoundException`.
- `guest-access.smoke.spec.ts` (реальный HTTP, сервисы поддельные): гость на
  `GET /v1/sessions/sess1` → 401; `BILLING_ENABLED=false` → 404, сервис не вызван.
- `src/contracts/session.spec.ts` — паритет `sessionResponseSchema` (DTO проходит, без
  `session` — нет).
- `lint`, `typecheck`, `build`, весь `jest`.

## Проверка в маноре (после merge)

Живой стек, пользователь с бронью: своя сессия → 200 и те же поля, что в `GET /v1/sessions`;
сессия другого пользователя → 404; случайный id → 404; `ABC` → 400. После выкладки на
`bff-dev` (Coolify выкатывает `develop` сам — merge и есть выкладка) веб `AURAT-0110` читает
сессию по id.

## Закрытие

- `AURAF-0020`: строки 024 и 026, колонка BE ✗ → ✓.
- Сообщение для `aura-app-manor`: тег `v0.23.0` готов для `AURAT-0110` (подъём — отдельным
  коммитом в вебе); приложению подъём не обязателен.

## Решения владельцу

1. **Правило продления в контракте — по коду** (минуты сравниваются, 409). Заглушка `001` и
   формулировка задачи говорили «тело повтора не сравнивается» и для продления — для брони
   это верно, для продления нет (`AURAT-0109-005` §3 оставил 409 сознательно). Рекомендую
   писать как есть; менять поведение продления — вне задачи.
2. **Новая `SessionResponse`**, а не переиспользование `FinishSessionResponse` для
   `GET` — рекомендую новую (имя по маршруту, только добавление).
3. **Порядок и вопросы**: (а) push `main` + тега `v0.23.0` контрактов — AskUserQuestion после
   части A; (б) merge в `develop` (= выкладка на `bff-dev`) — AskUserQuestion после твоего
   ревью части B.
