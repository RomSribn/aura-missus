# AURAT-0067-005 — спека: приём отзывов, серверная половина

Дата: 2026-09-08 · slave-2 · `feature/AURAT-0067-bff-write-review`
Статус: **на утверждение** · Фича `AURAF-0016` · Решение `AURAD-0014` (вариант 2)

---

## 1 · Схема и миграция

Одна миграция — `prisma/migrations/20260908180000_review_writing/`.

```prisma
enum ReviewQuoteStatus { PENDING PUBLISHED DECLINED }

model AdvisorReview {
  …
  quote        String              // '' — обычный ответ: оценка без текста
  anonymous    Boolean           @default(false)
  quoteStatus  ReviewQuoteStatus @default(PUBLISHED)   // засеянные — PUBLISHED
  sessionId    String?            // @unique СНЯТ: «какая сессия подтолкнула»
  userId       String?
  @@unique([userId, advisorId])   // живой ключ: один отзыв на пару
  @@index([quoteStatus])          // очередь модерации
}
```

`published` **остаётся** флагом строки целиком: он гасит отзыв (модерация может
убрать его совсем), `quoteStatus` — только текст. Оценка входит в агрегат при
`published = true` независимо от `quoteStatus` — это и есть «две скорости».

Почему миграция безопасна: у 42 засеянных строк `sessionId` и `userId` — NULL,
снятие уникального индекса ничего не ломает, а `@@unique` с NULL в Postgres не
конфликтует (NULL не равен NULL), поэтому шесть отзывов у одного советника
уживаются. `DEFAULT 'PUBLISHED'` красит существующие строки в один `ALTER`.

**FK на `users` не добавляем.** Отзыв — публичный текст; что происходит с ним и
с рейтингом советника при удалении аккаунта — продуктовое решение, которого нет,
а `onDelete` его молча примет. Оставляем как в заготовке.

## 2 · Контракты — потребляем, не пишем

`v0.18.0` готов (`aura-contracts` @ `c19be95`). Здесь только:

- `src/contracts/review.ts` — ре-экспорт `SubmitReviewRequest`, `MyReview`,
  `MyReviewsResponse`, `SubmitReviewResponse`, `ReviewRefusalCode`,
  `REVIEW_MAX_TEXT_LENGTH` (правило 7: формы не переобъявляются, `AURAT-0034`);
- `src/contracts/index.ts` — строка экспорта;
- `src/contracts/openapi.ts` — фрагменты запроса/ответа, `anonymous` в
  `advisorReviewOpenApi` и честное описание пустой `quote`;
- `package.json` — `@aura/contracts` на `#v0.18.0` (**см. вопрос Q2**).

## 3 · Новый модуль `src/modules/reviews/`

```
reviews.controller.ts        PUT advisors/:advisorId/review · GET reviews/me
reviews.service.ts           право → upsert → пересчёт → ответ
reviews.repository.ts        абстракция (домен, без Prisma-типов)
prisma-reviews.repository.ts транзакция upsert + пересчёт агрегатов
review-author-name.ts        чистая: первое слово имени / 'Anonymous'
reviews.module.ts            imports: AuthModule, AdvisorsModule, ChatModule
```

### `PUT /v1/advisors/:advisorId/review`

1. `advisorId` через `ZodValidationPipe(advisorIdSchema)`, тело — через
   `SubmitReviewRequest`.
2. Советник неизвестен или `active = false` → **404**.
   *(`AdvisorsRepository.findById` намеренно отдаёт и неактивных, поэтому
   `active` проверяет сервис — оценивать снятого с витрины советника незачем.)*
3. Право: `ChatService.hasWrittenTo(userId, advisorId)` — хотя бы одно
   сообщение `direction: USER` в переписке этой пары. Нет →
   **403 `{ code: 'review_not_eligible' }`**.
4. Upsert по `(userId, advisorId)` в **одной транзакции** с пересчётом:
   - `authorName` = первое слово `displayName`, снимок на момент записи
     (переименование не переписывает историю); при `anonymous: true` —
     `'Anonymous'`, имя не хранится вовсе (**Q1** — что при пустом имени);
   - `source = USER`, `published = true`;
   - `quote` = текст; `quoteStatus = PENDING` при непустом тексте, иначе
     `PUBLISHED` (публиковать нечего);
   - при правке: оценка применяется сразу, изменённый непустой текст снова
     уходит в `PENDING`; **неизменённый текст статус не сбрасывает** — иначе
     правка одной звезды отправляет опубликованную цитату на второй круг;
   - `sessionId` — сохраняется, если прошёл проверку формы (**Q3**);
   - `advisors.ratingTenths` / `reviewsCount` пересчитываются по строкам
     `published = true`: `count` и `round(sum / count)`.
5. Ответ — `SubmitReviewResponse` (`MyReview`: `hasText = quote !== ''`).

### `GET /v1/reviews/me`

`MyReviewsResponse` — мои отзывы по всем советникам, порядок по `updatedAt`.
Объём ограничен числом советников; пустой список — обычное состояние.

### Что меняется в `GET /v1/advisors`

`AdvisorReviewRecord` получает два поля: `anonymous: boolean` и
`quotePublished: boolean`. **Именно boolean, а не `quoteStatus`** — тип, которым
нельзя выразить разницу `PENDING`/`DECLINED`, надёжнее комментария о том, что
её нельзя показывать (прецедент — `StoredSpread`, где у неоткрытого расклада
нет свойства `card`). Сервис отдаёт `quote: quotePublished ? quote : ''`.
`reviewsCount` остаётся длиной `reviews[]` — инвариант `AURAF-0014` не трогаем.

## 4 · Право на отзыв — один метод в чужом модуле

`MessagesRepository.hasUserMessageTo(userId, advisorId)` — один `findFirst`
(`direction: USER` + связанная переписка пары), и `ChatService.hasWrittenTo`
поверх него. Сервис отзывов трактует `false` как 403; `ChatModule` уже
экспортирует `ChatService`, так что чужие репозитории наружу не выходят.

## 5 · Модерация — три скрипта

`src/reviews-moderation.ts` + `npm run reviews:pending|publish|decline`
(ts-node в разработке, `node dist/reviews-moderation.js` в проде — ровно как
сид: логика в `src/`, два входа, никакого ts-node в рантайм-образе).

- `reviews:pending` — id, советник, оценка, возраст строки, текст;
- `reviews:publish <id>` — `quoteStatus = PUBLISHED`;
- `reviews:decline <id>` — `quoteStatus = DECLINED`, **и больше ничего**: ни
  письма, ни пуша, ни поля в API. Оценка остаётся засчитанной.

Агрегаты скрипты не трогают: `published` они не меняют, а `quoteStatus` в счёт
не входит.

## 6 · Тесты (правило слота: чистые, без БД / Redis / Chatwoot)

Девять из брифа плюс то, что вскрылось по дороге:

| # | Что проверяем | Где |
|---|---|---|
| 1 | Нет переписки → 403, строка не создана, агрегаты не тронуты | `reviews.service.spec` |
| 2 | Переписка есть, своих сообщений нет → 403 | `reviews.service.spec` |
| 3 | Первый отзыв: строка создана, агрегаты пересчитаны, среднее сходится | `reviews.service.spec` |
| 4 | Повтор: строка одна, оценка новая, `quoteStatus` снова `PENDING`, счётчик не вырос | `reviews.service.spec` |
| 5 | Только звёзды: `quote = ''`, `quoteStatus = PUBLISHED`, карточка в списке | `reviews.service.spec` |
| 6 | `PENDING` не виден в каталоге (пустая `quote`), но строка и счётчик на месте | `advisors.service.spec` |
| 7 | `DECLINED` на проводе неотличим от `PENDING` | `advisors.service.spec` |
| 8 | Аноним: `authorName = 'Anonymous'`, имени нет ни в ответе, ни в строке | `reviews.service.spec` |
| 9 | Сид дважды не удваивает 42 строки после смены уникальности | `advisor-review-aggregate.spec` |
| + | Правка одной звезды не сбрасывает уже опубликованный текст | `reviews.service.spec` |
| + | Имя = первое слово; пустое имя по решению **Q1** | `review-author-name.spec` |
| + | Маршруты, гвард, 403-код по HTTP | `reviews.smoke.spec` |

Ворота слота: `npm run lint`, `npm run typecheck`, `npx jest`.
Живая проверка (миграция на настоящем Postgres, реальный upsert, скрипты
модерации) — **только в маноре после мержа**.

## 7 · Порядок работ

1. Схема + миграция (SQL пишется руками, `prisma migrate diff` — без БД).
2. `prisma generate`, ре-экспорт контрактов, `package.json`.
3. Модуль `reviews` + метод права в чате + правка каталога.
4. Скрипты модерации.
5. Тесты, ворота, `007-execute`, ревью в IDE.

---

## Вопросы к владельцу

**Q1 · Имя автора, когда в профиле его нет.** Отзыв не анонимный, но
`displayName` пуст (колонка nullable, профиль заполнять необязательно), а
`authorName` в контракте — `min(1)`.
**Рекомендую:** записывать `'Anonymous'`, флаг `anonymous` оставлять тем, что
прислал человек. Тогда байлайн — «Anonymous», без «Verified client», и это
правда: человек не просил анонимности, но и имени не дал. Альтернатива —
отказывать 4xx — наказывает за незаполненный профиль на последнем шаге формы,
которую приложение уже показало.

**Q2 · Тег `v0.18.0` в origin.** Пакет собран локально, тег в `origin` не
отправлен, `package.json` BFF смотрит на `#v0.17.0`. Работать я буду против
локальной сборки, но **мерж в `develop` без пуша тега даст манору несобираемую
ветку**. Нужно ваше решение: пуш тега контрактов — перед мержем (пушить будете
вы или я, но только с явного разрешения).

**Q3 · Проверять ли `sessionId`.** Поле информационное, ничего на нём не
ключуется; `SessionsModule` за `billing_enabled` и репозиторий не экспортирует.
**Рекомендую:** проверять только форму (`^[A-Za-z0-9_-]{1,64}$`), не
существование; не прошло — писать NULL, не отказывать. Тащить билинговый модуль
в бесплатную фичу ради подсказки модератору — плохой обмен.
