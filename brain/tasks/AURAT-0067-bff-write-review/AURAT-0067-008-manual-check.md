# AURAT-0067-008 — ручной прогон эндпоинтов

Дата: 2026-09-08 · по просьбе владельца, после пуша тега `v0.18.0`

## 1 · Пакет ставится из origin

`node_modules/@aura/contracts` снесён и поставлен заново обычным `npm install`:
версия **0.18.0**, `package-lock` резолвится на `c19be95` — ровно то, что я
прописал руками, npm ничего не переписал. Ворота прогнаны **против настоящего
пакета**, а не подложенной сборки: `tsc --noEmit` чисто, **865 тестов** зелёные.

## 2 · Прогон маршрутов

Живьём против Postgres нельзя — правило слота. Прогнал шестнадцать запросов
через **настоящее приложение**: реальные `ReviewsController` и
`AdvisorsController`, реальные `ZodValidationPipe` и `FirebaseAuthGuard`,
версионирование URI как в `app.setup.ts`. Подменены только Postgres (стол
в памяти с той же семантикой upsert по паре и пересчёта по `published`) и
проверка токена. Скрипт — в scratchpad сессии, в репозиторий не попал.

| # | Запрос | Ответ |
|---|---|---|
| 1 | `GET /v1/reviews/me` без токена | `401 Missing bearer token` |
| 2 | то же с чужим токеном | `401 Invalid or expired token` |
| 3 | `GET /v1/reviews/me`, отзывов нет | `200 {"reviews":[]}` |
| 4 | `PUT …/ivan/review` — переписки нет | `403 {"code":"review_not_eligible"}` |
| 5 | `PUT …/nobody/review` | `404 Unknown advisor: nobody` |
| 6 | `PUT …/retired/review` (снят с витрины) | `404` |
| 7 | `ratingTenths: 45` | `400 …must be a whole number of stars` |
| 8 | текст 401 знак | `400 String must contain at most 400 character(s)` |
| 9 | только звёзды (4.0) | `200`, `hasText: false`, строка `quote: ''`, `PUBLISHED`; olivia **4.8 (4) → 4.6 (5)** |
| 10 | дописан текст + валидный `sessionId` | `200`, та же строка, `PENDING`, `sessionId` сохранён; **4.8 (5)** — счётчик не вырос |
| 11 | `GET /v1/advisors` | цитата на модерации приходит пустой строкой |
| 12 | правка одной звезды, текст тот же | `200`, `quoteStatus` **остался** `PENDING`, оценка 4.0 |
| 13 | новый текст + `anonymous: true` | `200`, в строке `authorName: 'Anonymous'`, имени человека нет |
| 14 | `GET /v1/reviews/me` | одна запись, `hasText: true`, ничего про модерацию |
| 15 | `GET /v1/advisors` | живой отзыв стоит **перед** засеянными |
| 16 | битый `sessionId` (`../../etc/passwd`) | `200`, поле записано `NULL` — отказа нет |

## 3 · Что показал итоговый каталог

```
olivia: 4.8 (5) · карточек 5 · без цитаты 1 · reviewsCount === reviews.length: true
   Anonymous 5.0★ anonymous=true  quote=""        ← мой отзыв, текст на модерации
   Daniela 5.0★ · Marcus 5.0★ · Ana 5.0★ · Tom 4.0★  ← засеянные
ivan:   5.0 (1) · карточек 1 · без цитаты 1 · reviewsCount === reviews.length: true
   Sofia 5.0★ anonymous=false quote=""            ← текст ОТКЛОНЁН модератором
```

Две строки — `PENDING` у olivia и `DECLINED` у ivan — на проводе выглядят
**одинаково**: карточка с именем и звёздами, пустая цитата. Это и есть §5.

В теле ответа нет: `quoteStatus`, слова `PENDING`, слова `DECLINED`,
отклонённого текста, имени человека, оставившего анонимный отзыв. Проверено
поиском по сырому JSON, а не глазами.

Инвариант `AURAF-0014` (`reviewsCount === reviews.length`) держится у обоих
советников — включая того, у кого единственный отзыв без видимого текста.

## 4 · Что этим НЕ проверено

Всё, что живёт в Postgres: сама миграция на 42 засеянных строках, снятие
уникального индекса, `@@unique([userId, advisorId])` с NULL, транзакция вокруг
upsert + пересчёта, `DEFAULT 'PUBLISHED'`, двойной прогон сида и три скрипта
модерации. Это манорная проверка после мержа.
