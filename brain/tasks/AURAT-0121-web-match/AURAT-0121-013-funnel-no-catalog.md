# AURAT-0121-013 — Воронка не уходит в каталог: Show all на месте, профиль «в воронке»

Date: 2026-10-23

## Слова владельца

> проанализируй воронку. Когда на втором шаге клиент может провалиться в all advisors, там есть кнопка
> перехода в бесплатный чат, мб ее оттуда убрать? просто задача агрессивно его с воронки завлечь в
> платный чат

> давай попробуем, типо будет раскрываться просто полный список? или дубликат страницы advisors? юзеру
> нужно же прочитать про адвайзора что-то если он захотел повыбирать их

> давай, делай по рекомендациям

## Анализ утечек с `/match` (ответ владельцу)

«Browse all → `/advisors`» (Chat free на каждой плитке, профиль с Free chat) — высокий риск; ← Home /
Edit (Top advisors с Chat free) — человек сам ушёл; гость Book → вход → профиль `?book=1` с Free chat —
низкий; Booked «Say hi… free chat» — после оплаты, не утечка; таб Chats — глобальный. Free chat в
каталоге не трогаем (вход для всех остальных, `AURAD-0002`) — не пускаем воронку в каталог.

## Решения (рекомендации, одобрены)

1. «Show all N advisors» вместо «Browse all → `/advisors`»: остальные советники раскрываются на
   `/match` — те же карточки (только Book session, вся карточка — бронь), тот же порядок подбора,
   секция «More advisors», по 24 с «Show more»; Best match — только у первой карточки подбора.
   Не дубликат каталога: без фильтров и сортировки.
2. Почитать о советнике — **профиль в режиме воронки** `/advisors/:id?from=match`, а не новая шторка:
   без Free chat (ни в карточке desktop, ни в панели телефона), «← Back to your matches» → `/match`,
   Book session / слоты / All dates открывают шторку с шагами воронки и вопросом. На карточке
   `/match` — ссылка «About →» (имя для скринридера «About {name}»; в переводах — «Профиль: {name}»).
3. Гость: Book на `/match` → вход → обратно на `/match?book=<id>` → запись становится чистым
   `/match`, над ним открывается шторка этого советника (как `?book=1` у профиля).

## Сделано

- `shared/config/routes.ts`: `AdvisorSearch.from` (`?from=match`), `MatchSearch.book` +
  `parseMatchSearch` (только id советника), `paths.match({ book })`.
- `features/book-session`: `useBookSheetOnArrival` открывает шторку с `funnel` для `from=match` и
  оставляет `?from=match` на чистом профиле; `widgets/book-sheet` пишет свой URL с `from=match`.
- `pages/advisor`: `funnel`, `backHref`; Free chat скрыт; бронь — `funnel: true`, ссылки с `from`.
- `pages/match`: `rankAdvisors` (все, по правилу §5; первые `MATCH_COUNT` — подбор), «Show all» /
  «More advisors» / «Show more» (`MORE_PAGE_SIZE` 24); About на карточке (клик по ссылке не бронирует);
  возврат гостя по `?book=`.
- Строки (24 языка): `match-page` — `showAll_*` (бывш. `browse_*`), `more`, `showMore` (как в каталоге),
  `about`, `aboutLabel`; `advisor-page:backToMatches`. Страж WCAG 2.5.3 — и для About.

## Тесты

`home.test`: каталог из 3 — ни «Show all», ни ссылок в каталог; из 4 — «Show all 4 advisors» раскрывает
«More advisors» с Book session, без Best match и Chat free, остаёмся на `/match`; About →
`/advisors/mia?from=match`, шторка не открывается; гость: Book → вход → `/match` и шторка Mia, URL
чистый. `booking.test`: профиль `?from=match` — нет Free chat, «Back to your matches» → `/match`, Book →
шторка с шагами и вопросом, URL с `from=match`; перезагрузка ссылки брони с `from=match` — шторка с
шагами. `routes.test`: `from`, `?book=`. `match-advisors`: ранжирование всех.

## Проверки

`npm run lint` — без замечаний; `npm run typecheck` — чисто; `TZ=America/New_York npm test` — 81
файл, 1429 тестов, зелёные; `npm run build` — собран. Код — `aura-web` ветка, коммит после `8de93f5`.

## Проверка в маноре (дополнение)

- `/match`: «Show all» раскрывает список на месте; About → профиль без Free chat, ← к подбору; Book в
  профиле — шторка с шагами; телефон — в панели профиля только Book session.
