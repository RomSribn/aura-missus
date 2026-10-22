# AURAT-0121-001 — Initial (исполняется в `aura-web-manor`)

Date: 2026-10-22
Фича: `AURAF-0020` (веб-клиент), строки плана `AURAF-0020-012` (UI, `/match`),
`004` (вход с причиной `ask`), `028` (вопрос в брони). ID выдан в
`aura-app-manor/active-work.md` (новых не минтить). Парная задача BFF — `AURAT-0122`
(`aura-bff-manor`).

## Слова владельца

> воронка когда юзер после get started зарегался и перешел на выбор адвайзора выглядит по
> другому, у нас нет такой навигации, кажется нет best match и я явно просил именно на этом
> шаге воронки убрать кнопку free chat [Image #14]

> Выбор владельца в aura-app-manor: «Да + строка 028 в BFF».

## Контекст из `aura-app-manor` (не слова владельца)

- [Image #14] — экран «1 · Matched advisors» из `aura_web/Aura Web - Booking Funnel.html`
  (`web/web-funnel.jsx` → `FunnelMatched`; хендофф `src/components/advisors/AdvisorCard.tsx`
  → `MatchCard`): ← Home; шаги «Your question → Choose advisor → Book → Pay»; карточка вопроса
  с Edit + CouponTicket; «3 advisors for your question»; три карточки, первая — BEST MATCH,
  teal-причина подбора, цена с зачёркнутой; одна кнопка Book session; внизу «Not quite right?
  Browse all N advisors →».
- Хендофф: NAVIGATION §2.1 (Ask → gate('ask') → `/match`), §2.2 («**No free-chat button on this
  step**»), §2.3 (вопрос в Book «will be shared with the advisor»), Booked; AuthFlow `ask`;
  README §3, §4.1; AskHero lead / «Finding advisors…»; How Aura works — «Get matched».
- Как есть (develop `e20b3f0`): `/match` — `element: null`; Ask без входа → `/advisors?cat=`;
  вопрос во вкладке → плашка каталога и composer первого бесплатного чата.
- Расхождение — от `AURAT-0112-005` решений 2–3; в спеке перечислить, что из них отменяется.
  Free chat остаётся там, где он есть в хендоффе.
- `POST /match` в BFF нет — подбор на клиенте из `GET /v1/advisors`; причину «под текст
  вопроса» не выдумывать; онлайна в каталоге нет (`AURAT-0102-006`).
- Вопрос в брони (028) — `AURAT-0122` в BFF (`BookSessionRequest`, контракты сейчас v0.23.0,
  доставка в Chatwoot). Пока контракт не опубликован, веб не обещает, что вопрос у советника.
- Вопрос в URL vs во вкладке; аналитика вне задачи. Строки — 24 языка. Спека — владельцу до кода.

## Слот

`slave-1`, ветка `feature/AURAT-0121-web-match` (master и missus);
master от `develop` `e20b3f0`, missus от `master` `01e99f9`.
