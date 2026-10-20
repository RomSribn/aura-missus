# AURAT-0111-004 — Context

Дата: 2026-10-20. Сверено с `aura-bff` `develop` @ `a4b8e9e`, `aura-contracts` `v0.22.0`.

## BFF
- `sessions.controller.ts` — весь контроллер за `BillingEnabledGuard`; есть `GET sessions`,
  `PATCH sessions/:sessionId` и `POST sessions/:sessionId/{cancel,extend,finish}`; id через
  `ZodValidationPipe(sessionIdSchema)` (`[a-z0-9]{1,64}`, иначе 400).
- `sessions.service.ts` — `requireOwnedSession` (`ensureUser` → `findByIdWithContext` →
  404 «Session not found» для чужой и несуществующей); `toDto(SessionRecord)` — общий для всех
  ответов, `userId` из `SessionWithContext` в DTO не попадает.
- `src/contracts/session.ts` — переэкспорт `@aura/contracts` под `*Schema`; `openapi.ts` —
  ручные `SchemaObject` (`finishSessionResponseOpenApi` = `{session}`); `session.spec.ts` —
  паритет схем.
- HTTP-смоук `src/common/web/guest-access.smoke.spec.ts` — реальный Fastify с поддельными
  сервисами: гость на `GET /v1/sessions` → 401, `BILLING_ENABLED=false` → 404.
- `bff-dev` — Coolify выкатывает `develop` сам (`AURAT-0109-009`): merge = выкладка.

## Контракты
- `src/session.ts`: `FinishSessionResponse = {session: Session}`, `ActiveSessionResponse =
  {session: Session | null}`, `SessionsResponse`. Схемы `{session}` для чтения нет.
- `BookSessionRequest` — комментарий говорит только «replaying it must never debit twice».
- `src/chat.ts` — `EnsureConversationResponse`: «Ответ `POST /v1/advisors/:advisorId/
  conversation`»; маршрут в BFF — `@Put(':advisorId/conversation')`.
- Выпуск (по `AURAT-0098-005`, `AURAT-0094`): `src/*` + README (абзац версии, таблица модулей)
  + `package.json` version → коммит «… на проводе (v0.N.0)» в `main` → аннотированный тег →
  push `main` и тега с подтверждения владельца → BFF `package.json`/lock `#v0.N.0`.

## Правило повтора `AURAT-0109` (как в коде, `prisma-sessions.repository.ts`)
- Бронь: повтор по `(user, advisor, idempotencyKey)` ищется первым и отвечает исходной
  сессией (текущее состояние) и текущим балансом; **тело не сравнивается** — другой слот /
  блок / `startNow` → исходная сессия. Ключ у другого советника — не повтор (→ 409).
- Продление: сначала владение (404), потом повтор — **минуты сравниваются**: запись журнала
  с другой суммой → 409; ключ брони этой же сессии → 409; повтор после конца сессии → тот же
  результат.

## Расхождение
- Заглушка `001` и строка 024 говорят «тело повтора не сравнивается» и для продления. Для
  брони верно; для продления — нет (другие минуты → 409, так решено в `AURAT-0109-005` §3).
  Комментарий в контракты пишу по коду.
