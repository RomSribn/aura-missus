# AURAT-0067-007 — сделано на сервере

Дата: 2026-09-08
Ветка: `feature/AURAT-0067-bff-write-review` (не коммичена, стек не поднимался)

## Схема — одна миграция

`prisma/migrations/20260908180000_review_writing/`:

- `CREATE TYPE "ReviewQuoteStatus" AS ENUM ('PENDING','PUBLISHED','DECLINED')`;
- `advisor_reviews`: `+ quoteStatus DEFAULT 'PUBLISHED'`, `+ anonymous DEFAULT false`;
- `DROP INDEX advisor_reviews_sessionId_key` → `CREATE UNIQUE INDEX (userId, advisorId)`;
- `+ INDEX (quoteStatus)` — очередь модерации;
- `AdvisorReview.id` получил `@default(cuid())`: сид по-прежнему задаёт свои
  `olivia-01`, живым строкам id брать неоткуда. SQL это не меняет (cuid
  генерируется Prisma, не базой).

FK на `users` **не** добавлен: что делать с опубликованным отзывом и с рейтингом
советника при удалении аккаунта — продуктовый вопрос, а `ON DELETE` ответил бы
на него молча.

## Роуты

**`PUT /v1/advisors/:advisorId/review`** — 404 на неизвестного или снятого с
витрины советника; **403 `review_not_eligible`**, если человек не написал этому
советнику ни одного своего сообщения; иначе upsert по паре и пересчёт агрегатов
**в одной транзакции**.

**`GET /v1/reviews/me`** — `MyReviewsResponse`, по одному отзыву на советника.

**`GET /v1/advisors`** — `reviews[]` теперь везёт `anonymous`, а `quote` уходит
пустой строкой, пока текст не опубликован.

## Восемь файлов нового модуля и три чужих правки

```
src/modules/reviews/review-quote.ts            имя автора · статус текста · sessionId (чистое)
src/modules/reviews/reviews.repository.ts      абстракция: findMine · upsertAndRecount · listByUser
src/modules/reviews/prisma-reviews.repository.ts  транзакция upsert + SUM/COUNT + update advisors
src/modules/reviews/reviews.service.ts         право → upsert → ответ
src/modules/reviews/reviews.controller.ts      два роута, тонкий
src/modules/reviews/reviews.module.ts          AuthModule · AdvisorsModule · ChatModule
src/contracts/review.ts                        ре-экспорт v0.18.0
src/reviews-moderation.ts                      три команды модерации
```

Чужого тронуто ровно столько, сколько нужно: `MessagesRepository`
(+`hasUserMessageTo`), `ChatService` (+`hasWrittenTo`), каталог советников
(+`anonymous`/`quotePublished` в записи, `active` в `AdvisorRecord`).

## Пять решений, принятых по дороге

1. **Право спрашивается у чата, а не у чужой таблицы.** Ни
   `ConversationsRepository`, ни `MessagesRepository` наружу не экспортируются,
   а `ProvisioningService.ensureConversation` **создаёт** тред — то есть открыл
   бы ровно ту переписку, отсутствие которой и есть ответ. Поэтому факт отдаёт
   `ChatService.hasWrittenTo` (один `findFirst` по `direction: USER` через
   связанную переписку), а трактовку «нет → 403» делает сервис отзывов.

2. **Наружу из хранилища едет `quotePublished: boolean`, а не `quoteStatus`.**
   §5 запрещает приложению отличать `PENDING` от `DECLINED`; тип, которым эту
   разницу нельзя выразить, надёжнее комментария о том, что её нельзя
   показывать. Тот же приём, что у `StoredSpread`, где у неоткрытого расклада
   нет свойства `card`.

3. **Неизменённый текст статус не сбрасывает.** Правка одной звезды не должна
   отправлять уже опубликованную цитату на второй круг — и не должна тихо
   воскрешать отклонённую. `nextQuoteStatus` сравнивает текст с прежним; чистая
   функция, четыре теста.

4. **Пересчёт — `SUM/COUNT` по таблице, а не арифметика над прежними числами.**
   Прибавление оценки к хранимому среднему разъезжается с рядом при первом же
   постороннем изменении (модератор снял строку, два запроса пересеклись).
   Восемь советников по 4–7 отзывов делают честный запрос бесплатным.
   Округление — общая с сидом `ratingTenthsFromTotals`.

5. **Живые отзывы сортируются перед засеянными** (`sortOrder = -1`). Засеянные
   существуют потому, что пустой профиль читается как закрытая лавка
   (`AURAF-0014`); как только настоящему человеку есть что сказать, читатель
   должен встретить это первым.

## Модерация

`npm run reviews:pending` (id · советник · звёзды · возраст · текст, старшие
сверху), `reviews:publish -- <id>`, `reviews:decline -- <id>`. Возраст считается
от `updatedAt`: правка ставит текст в очередь заново, и сутки начинаются от тех
слов, что реально ждут. `publish`/`decline` бьют только по `PENDING`-строкам —
опечатка в id падает вслух, а не переворачивает чужое решение. Агрегаты
скрипты не трогают: они считают `published`, а `quoteStatus` — не `published`.

В проде — `node dist/reviews-moderation.js pending`, как сид: логика в `src/`,
два входа, ts-node в рантайм-образе нет.

## Контракты

`package.json` и `package-lock.json` переведены на `#v0.18.0` (`c19be95`).
Локально подложена сборка из `ai-manors/aura-contracts`. **Тег в origin ещё не
отправлен** — по решению владельца (Q2) пушится перед мержем; до этого
`npm ci` в маноре поставит 0.17.0 и ветка не соберётся.

## Ворота

`npm run lint` · `npx tsc --noEmit` · `npx jest` · `npm run build` — чисто.
**865 тестов** (было 828), 63 набора. Новых 37:

- `review-quote.spec` (12) — имя, статус текста, `sessionId`;
- `reviews.service.spec` (14) — оба отказа, первый отзыв, правка, только
  звёзды, аноним, «правка звезды не сбрасывает текст», `sessionId`, `listMine`;
- `reviews.smoke.spec` (9) — оба маршрута по HTTP, гвард, половинки звёзд,
  401 знак, `review_not_eligible`, «в ответе нет ни PENDING, ни DECLINED»;
- `advisors.service.spec` (+3) — `PENDING` и `DECLINED` неотличимы на проводе,
  `anonymous` доезжает;
- `advisor-review-aggregate.spec` (+3) — сид под новой уникальностью;
- `reviews-moderation.spec` (4) — возраст в очереди, отказ неизвестной команде.

Девять тестов из брифа покрыты все.

## Документы

- `README.md` — модуль в дереве, три роута и правило права в разделе API,
  команды модерации в `Develop`.
- `AURAF-0014` — приписка: какая из трёх заготовленных колонок выражала не то
  правило и что с ней стало; строки 006/007 в таблице помечены.
- `AURAF-0016` лежит в клоне app-манора и здесь не редактируется — колонку `BE`
  переводит он, когда сервер будет проверен в маноре.

## Чего нет и почему

- **Живой проверки миграции, транзакции и скриптов** — правило слота: ни
  Postgres, ни Redis, ни Chatwoot. `@@unique` с NULL, `DEFAULT 'PUBLISHED'` на
  42 строках и двойной прогон сида проверяются в маноре после мержа.
- **Интерфейса модерации** — решение владельца: три команды, модератор он сам.
- **Уведомлений автору о судьбе текста** — §5 запрещает прямо.
- **Проверки существования `sessionId`** — Q3: только форма.
