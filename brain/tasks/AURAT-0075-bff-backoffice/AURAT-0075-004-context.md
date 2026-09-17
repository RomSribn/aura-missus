# AURAT-0075-004 — Контекст

Дата: 2026-09-17
Код: `aura-bff` `develop` @ `abe2039`; тема: `aura-app` `master` @ `077c3c7`.

## Как сейчас открыт `/docs`

`app.setup.ts`: Swagger включается при `NODE_ENV !== 'production'`, а
runtime-образ ставит `NODE_ENV=production` **на всех** задеплоенных
окружениях (комментарий в `env.schema.ts`). То есть `/docs` в dev и проде
выключен, а локально открыт без защиты. Защищённого веб-раздела у BFF нет —
образца для входа нет, строим первый.

- Глобальный `FirebaseAuthGuard` (`APP_GUARD`) пропускает только `@Public()`
  (сейчас — health).
- helmet в `production` — CSP по умолчанию: `script-src 'self'`, стили и
  шрифты — свои или `https:`. Страница без inline-скриптов впишется без правок.
- Формы `application/x-www-form-urlencoded` Nest уже разбирает
  (`registerUrlencodedContentParser` в адаптере Fastify) — новых зависимостей
  не нужно.
- **Лог запросов пишет заголовки целиком** (`http-logger.options.ts` убирает
  только `authorization` и подпись Chatwoot). Cookie сессии попала бы в лог —
  вырезать обязательно.
- Cookie в BFF не используются нигде. Redis есть (`REDIS_CLIENT`).
- `@fastify/rate-limit` уже подключён глобально (120/мин).
- `nest-cli.json` не копирует ассеты — для CSS/шрифтов понадобится `assets`.

## Модерация отзывов

- `src/reviews-moderation.ts` — отдельный `PrismaClient` без Nest. Очередь:
  `quoteStatus = PENDING AND published = true`, по `updatedAt` по возрастанию
  (24 часа считаются от последней правки). `publish` / `decline` — `updateMany`
  с условием `quoteStatus = PENDING`: опечатка в id не переписывает чужое
  решение. Агрегаты не трогаются — они считают `published`, а не `quoteStatus`.
- Отклонение молчаливое (`AURAD-0014`, §5 дизайна): ни пуша, ни поля в API.
- `published = false` («скрыть отзыв целиком») — назван в
  `AURAT-0067-013`, не сделан; нужен пересчёт `ratingTenths`/`reviewsCount` в
  той же транзакции. Пересчёт уже написан в
  `PrismaReviewsRepository.upsertAndRecount` (SUM/COUNT по опубликованным).
- В `AURAD-0014` модерация решена как «три CLI-скрипта, модератор — владелец»,
  а шапка `reviews-moderation.ts` говорит «no interface, by the owner's
  decision». Бэкофис **дополняет** это решение — отметить в `AURAD-0014`.
- Отзывы — фичи `AURAF-0014` (показ) и `AURAF-0016` (запись); в фоне запроса
  назван `AURAF-0014`, по сути модерация — из `AURAF-0016`.

## Удалённые аккаунты

- Таблица `account_erasures`: `userId` (надгробие, `firebaseUid =
  deleted:<uuid>`), `source` (`app` / `operator` / NULL до `AURAT-0073`),
  `requestedAt`, `completedAt`, а также `firebaseUid` и `chatwootContactId` —
  хранятся до завершения, **показывать нельзя**.
- Завершение: немедленный проход + финальный через `IN_FLIGHT_GRACE_MS`
  (5 мин) + 30 с, плюс sweep. `completedAt` ставится только после записи в
  журнал R2 (`AccountErasureService.complete`: сбой журнала бросается в конце
  каждого прохода). Значит «завершено» уже означает «есть в журнале» — читать
  бакет со страницы незачем.
- Долго незавершённое удаление = сбой (Firebase, Chatwoot, аватар, журнал),
  сейчас видно только по `warn` в логе sweep.
- Id своих записей — не секрет и не PII (правило лога `AURAT-0074`).

## Дизайн-код приложения

`theme.ts`: `paper #F3EEE3`, `paper2 #ECE5D6`, `card #FFF`, `ink #221F1A`,
`ink2 #7A7264`, `ink3 #ABA191`, линии — ink 8 % / 13 %, `accent #EC5F73` (+
`accentSoft`), `teal #2BA39A` (+ `tealSoft`), `plum #34204A` → `plumDark
#1F122B` (градиент), `gold #D9B26A`. Радиусы: карточка 22, поле и кнопка 16,
pill 999. Отступ экрана 22. Шрифты (`fonts.ts`): Bricolage Grotesque
(display, 600/700/800) и Hanken Grotesk (body, 400/600/700), TTF с OFL в
`src/shared/assets/fonts/` (85–118 КБ).

## Расхождение в фоне запроса

Фон говорит «релиз в `main` ещё не сделан»; brain (`AURAT-0073-018`,
`AURAT-0074-015`, 2026-09-17) — `main` = `abe2039` уже в проде. На задачу не
влияет: ветка от того же `abe2039`.

## Пересечения

`slave-1` на `feature/AURAT-0058-advisor-reviews` (`994d328`) — старая ветка
отзывов; эта задача трогает `reviews` module и `reviews-moderation.ts`. При
мёрже той ветки — конфликт возможен, но она по сути поглощена `AURAT-0067`.
