# AURAT-0067-004 — контекст: что проверено в коде

Дата: 2026-09-08

Источники: бриф `AURAT-0067-001` и `AURAF-0016` / `AURAD-0014` / `AURAT-0066`
(клон brain у app-манора, по абсолютным путям), `AURAF-0014` и
`AURAT-0058` (этот клон), код `aura-bff` @ `85806af`, пакет
`@aura/contracts` @ `c19be95` (`v0.18.0`, локально).

---

## A · Что в коде уже есть и работает

| Нужно | Что берём | Файл |
|---|---|---|
| Форма отзыва на проводе | `@aura/contracts` `v0.18.0`, ре-экспорт | `src/contracts/advisor.ts` |
| Агрегаты советника | `aggregateAdvisorReviews` / `aggregateFor` — чистые | `src/modules/advisors/advisor-review-aggregate.ts` |
| Выдача `reviews[]` в каталоге | `include: { reviews: { where: { published: true } } }` | `src/modules/advisors/prisma-advisors.repository.ts` |
| Проекция строки отзыва | `AdvisorReviewRecord` — `source`/`published`/`sessionId`/`userId` **не выходят** за репозиторий | `src/modules/advisors/advisors.repository.ts` |
| Советник по слагу (для 404) | `AdvisorsRepository.findById`, `AdvisorsModule` его **экспортирует** | `advisors.module.ts:exports` |
| Наш `userId` из токена | `UsersService.ensureUser(auth)`, `AuthModule` экспортирует | `src/modules/auth/users.service.ts` |
| Имя человека | `users.displayName` — **nullable**, заполняется потом или никогда | `prisma/schema.prisma:21` |
| Валидация тела | `ZodValidationPipe` + схема из пакета | `src/common/pipes/zod-validation.pipe.ts` |
| Отказ с кодом | `throw new XException({ code, message })` — как `refused_by_agent_desk` | `src/modules/chat/chat.controller.ts:78` |
| CLI поверх Prisma | `src/seed.ts` — логика в `src/`, два входа (ts-node и `node dist/…`) | `src/seed.ts`, `prisma.config.ts` |
| Смоук по HTTP без БД | реальный контроллер + гвард + пайп через Fastify, фейки вместо Postgres | `src/modules/profile/profile.smoke.spec.ts` |

## B · Пять фактов, которые определили форму работы

### B1 · Право на отзыв стоит **одного** запроса, а не двух

`Conversation` — BFF-овская карта `(user, advisor)`, а `Message.direction`
хранит `USER | ADVISOR | SYSTEM`. Значит весь вопрос «писал ли этот человек
этому советнику» — один `findFirst` по `messages` с фильтром по связанной
переписке (`direction: USER`, `conversation.userId`, `conversation.advisorId`).
Отдельно спрашивать «есть ли тред» не нужно: нет треда → нет и сообщений,
ответ тот же **403**. Это и правило дизайна («don't rely on the client hiding
the link»), и то самое место, где `AURAT-0066-004` A3 нашёл дыру.

### B2 · Ни `ConversationsRepository`, ни `MessagesRepository` не экспортируются

`ChatwootModule` экспортирует `ProvisioningService` (`ensureConversation`
**создаёт** тред — для проверки права он не годится), `ChatModule` —
`ChatService` и `ReconciliationService`. Расширять exports репозиториями
значило бы раздать чужие таблицы; вместо этого факт отдаёт **сервис-владелец**:
`ChatService.hasWrittenTo(userId, advisorId)`, а трактовку «нет → 403» делает
уже сервис отзывов. Границы модулей остаются там, где они есть.

### B3 · Разницу `PENDING` / `DECLINED` не должен уметь выразить даже тип

§5 запрещает отличать их на проводе, и одного комментария тут мало — в проекте
уже есть прецедент, где это выражено типом (`StoredSpread`: у неоткрытого
расклада **нет свойства** `card`, поэтому ни один маппер не может опубликовать
исход раньше времени). Тем же приёмом: наружу из репозитория едет
`quotePublished: boolean`, а не `quoteStatus`. Мапперу нечего утечь.

### B4 · Пересчёт агрегатов на записи — та же арифметика, но по строкам БД

Сид считает по константе (`ADVISOR_REVIEW_SEED`), запись обязана считать по
таблице: `count` и `sum(ratingTenths)` по `published = true`, затем
`round(sum / count)`. Общей остаётся **чистая** часть — округление; она и
покрыта спекой без базы. Обе стороны обязаны давать один ответ, иначе первый
живой отзыв разъедет число со списком под ним.

### B5 · `sessionId` некому проверить, и это нормально

`SessionsModule` экспортирует только `SessionsService`, весь модуль сидит за
`BillingEnabledGuard` и в v1 отвечает 404. Тянуть его в бесплатную фичу ради
информационного поля — плохой обмен. Поле объявлено в контракте как
«informational — nothing keys on this»; на сервере оно проходит проверку
**формы** (тот же charset, что у наших id) и ложится в строку как подсказка
модератору.

## C · Противоречие источников — одно, и оно разрешено брифом

`AURAF-0014` («Чтобы фаза 2 не потребовала переписывать смысл строк») говорит:
`sessionId String? @unique` — «сама уникальность уже выражает правило "один
отзыв на оплаченную сессию"». Дизайн `AURAF-0016` требует другого правила —
«один на пару (человек, советник)». Это не спор архитектуры с дизайном:
`AURAF-0014` писался, когда приёма не было, и назвал **предполагаемую** форму.
Бриф `AURAT-0067-001` §2 разрешает прямо: `@unique` снимается, появляется
`@@unique([userId, advisorId])`, поле остаётся как «какая сессия подтолкнула».

## D · Три вопроса, которые надо решить до кода

1. **Имя автора, когда `displayName` пуст.** Отзыв не анонимный, а имени в
   профиле нет (колонка nullable, экран профиля необязателен). `authorName` в
   контракте — `min(1)`, пустым его оставить нельзя.
2. **`@aura/contracts` `v0.18.0` не в origin.** `package.json` BFF указывает на
   `#v0.17.0`; после мержа манор соберёт `develop` и не найдёт `v0.18.0`, пока
   тег не запушен.
3. **Проверять ли существование `sessionId`** (см. B5) — рекомендация: только
   форму.

Разложены с рекомендациями в `005-spec`.
