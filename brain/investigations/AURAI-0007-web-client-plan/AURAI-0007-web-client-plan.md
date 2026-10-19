# AURAI-0007 — Веб-клиент Aura: разбор хендоффа и план шагов

Дата: 2026-10-20
Статус: **Decided** — решения Р1–Р7 одобрены владельцем 2026-10-20 (Р4 — с заготовкой под PSP), см. `AURAD-0019`
Связано: `AURAD-0006` (топология BFF-манора), `AURAD-0009` (сессии с кошелька), `AURAF-0009` (PSP), `AURAI-0006` (PSP, правила сторов), `AURAF-0020` (спека веб-клиента)

## Decision

Веб-клиент — отдельный репозиторий `aura-web` (Vite + React 19 SPA, строгий FSD)
и отдельный манор `aura-web-manor` с общим brain `aura-missus`; общий код с
приложением на старте — только `@aura/contracts`; оплата на запуске — балансом,
с заготовкой под PSP.

## Context

- Хендофф от дизайнера: `/Volumes/Work/personal/aura_web/` —
  `design_handoff_aura_web/{README,STRUCTURE,NAVIGATION}.md`, `src/` (React+TS,
  без UI-кита, стили из `src/styles/tokens.css`), прототип `Aura Web.html`,
  экраны `Aura Web - Screens Desktop|Phone.html`, план `Aura Web - Plan.html`.
- Образец структуры веб-FSD: `LogCluster-RITA-UI-manor` (Vite 7, React 19,
  RTK Query `injectEndpoints`, `createBrowserRouter`). Его `components/ui`
  (shadcn) — артефакт того проекта, не переносим.
- `AURAD-0006` прямо оставил пересмотр «if a third TS consumer appears» — веб и
  есть третий потребитель `@aura/contracts`.

## Research / Analysis

### Что уже есть и работает на веб без доработок

- **Аккаунт.** BFF узнаёт пользователя по Firebase ID token (`FirebaseAuthGuard`).
  Firebase JS SDK (`signInWithPhoneNumber` + reCAPTCHA) в том же проекте даёт
  тот же uid → общие чаты, сессии, кошелёк, оффер. Вопрос 4 из Plan.html
  («общая история чатов») закрыт сам.
- **Realtime.** BFF — сырой WebSocket `/ws?token=…` (`@nestjs/platform-ws`),
  события — `WsServerEvent` из контрактов; браузерный `WebSocket` подходит.
- **Контракты.** `@aura/contracts` v0.22.0 — Zod-схемы + типы, git-зависимость
  `github:RomSribn/aura-contracts#vX`, сборка tsup на `prepare` (ESM/CJS).

### Чего не хватает в BFF для браузера

| Пробел | Где |
|---|---|
| CORS не настроен вовсе (нет `@fastify/cors`) | `main.ts` |
| Проверка `Origin` на `/ws` | `modules/delivery/chat.gateway.ts` |
| Гость должен видеть каталог и профиль — нужны `@Public` read-эндпоинты | `modules/advisors`, `reviews` |
| Фильтры / сортировка / пагинация каталога (`?cat&online&price&rating&lang&sort`, страница 24) | `GET /v1/advisors` |
| `POST /match {question}` — воронки «Ask → match» нет и в приложении | новая фича |
| Web push (FCM web) — если нужен | `modules/devices` |
| Веб-домен в Firebase authorized domains, App Check / reCAPTCHA | Firebase console |

### Переиспользование кода aura-app

- Состояние в приложении — не Redux: `*-store.ts` на `useSyncExternalStore`,
  HTTP — `bffRequest` на `fetch`, WS — `BffSocket`.
- Логика entities почти вся чистый TS (`session/lib/{refund,saving,session-state}`,
  `wallet/model/use-first-session-offer`, `booking/lib/slots`,
  `shared/lib/{phone,birth-date,dates,format}`), **но** 74 файла логики
  импортируют barrel `@/shared`, который тянет RN, Firebase RN и blob-util;
  `http-client` берёт токен из RN Firebase; `env.ts` зависит от `Platform`.
  Вынести общий пакет без рефакторинга приложения нельзя.
- i18n в приложении нет — тексты в `config/copy.ts`.

### Противоречия в хендоффе (сверить с дизайнером)

| Вопрос | Plan.html (этап 1) | README хендоффа | aura-app |
|---|---|---|---|
| Навигация | боковое меню | верхнее меню + нижние табы ≤760 | — |
| Стек | Next.js | Vite + React Router | — |
| Вход | страницы `/login` | модальный AuthFlow | — |
| SMS-код | — | 4 цифры | **6** (`OTP_LENGTH`, Firebase) |
| Брейкпоинты | 768 / 1200 | 760 / 900 / 1180 | — |
| Профиль | `/profile` | `/me` | — |
| Оплата | Stripe | «acquirer hosted page» | стор + баланс |

Источник истины — README/NAVIGATION хендоффа (они новее Plan.html), кроме
OTP: 6 цифр (Firebase). Код `src/` хендоффа — на inline-стилях (нарушает hard
rule 3) и не в FSD (`components/ + features/ + state/`): берём как образец
поведения, не как код.

### Оплата

В вебе нет стора → нужен PSP (`AURAF-0009`, backlog). По `AURAI-0006` Stripe не
обслуживает Украину (нужно юрлицо в US/ЕС), Adyen — restricted для ниши. Без PSP
веб может только тратить баланс, пополненный в приложении. Ограничение App Store:
iOS-приложение не может вести на веб-оплату (кроме US storefront) — веб сам по
себе это не нарушает.

## Recommendation (одобрено 2026-10-20)

| # | Вопрос | Решение |
|---|---|---|
| Р1 | Стек | Vite + React 19 SPA + react-router (data router). SEO позже — пререндер |
| Р2 | Общий код | только `@aura/contracts`; чистую логику — копией со ссылкой на источник; `@aura/domain` — отдельным решением, когда оба клиента покажут общий набор |
| Р3 | Данные | Redux Toolkit + RTK Query (`baseApi` + `injectEndpoints` в entities), Zod-разбор контрактами в `transformResponse` |
| Р4 | Оплата | запуск — балансом; **заготовка под PSP** (см. ниже) |
| Р5 | Этап 1 | Advisors (публичные) → Auth → Chat → Booking; этап 2 — Sessions, Profile, Top up, Daily card, `/match` (в v1 — `/advisors?cat=`) |
| Р6 | Стили / тексты | CSS Modules + CSS-переменные `tokens.css`, без Tailwind/shadcn; тексты в `config/copy.ts` |
| Р7 | Слой страниц | `pages` |

### Заготовка под PSP (Р4)

- `features/pay` строится вокруг порта способа оплаты: `balance` — живой;
  `card` (hosted page: redirect / iframe-sheet, `CardCheckout`) и `wallet`
  (Payment Request API / SDK провайдера) — реализованы против **фейкового
  провайдера** и выключены флагом `PSP_ENABLED`.
- Заранее готовы: маршрут возврата с hosted page, состояние «Still confirming…»
  с опросом и правило «Booked только после подтверждения сервером»
  (NAVIGATION §2.4, §4) — проверяются на фейке.
- Флаг выключен (прод до PSP) → кнопок карты и кошелька нет; PayActions =
  «Use balance» + оплата с баланса; при нехватке — «пополните баланс в
  приложении».
- BFF и контракты до выбора провайдера не трогаем: поток PSP ложится как
  «пополнение → списание сессии» (`AURAD-0009`), т.е. PSP — это новый вид
  top-up, а не новый путь брони.

## Implementation Notes

### FSD-раскладка хендоффа (черновик)

- **shared** — `ui`: Sheet, Field, Toggle, IconButton, EmptyState (орб), Icon
  (36 иконок из `MOTION_AND_ICONS.md`); `lib`: `useNarrow`, `usd`; `api`: base
  query (Firebase ID token, повтор на 401, `ACCOUNT_DELETED`), WS-клиент;
  `config`: env, routes.
- **entities** — `advisor` (AdvisorTile, MatchCard, действия слотами),
  `wallet`/offer (PriceTag, OffChip, CouponTicket), `session` (SessionCard),
  `user`, `message` (Bubble, SystemLine).
- **features** — `auth-by-phone`, `require-auth` (gate с resume), `ask-question`,
  `book-session` (черновик в sessionStorage), `pay`, `quick-book`, `tarot-pick`,
  `reschedule-session`, `cancel-session`, `top-up`, `edit-profile`,
  `advisor-filters`, `send-message`, `write-review`.
- **widgets** — `top-nav` / `tab-bar`, `conversation-list`, `chat-thread`,
  `advisor-rail`, `session-detail`.
- **pages** — `home`, `match`, `advisors`, `advisor`, `checkout`, `booked`,
  `chats`, `sessions`, `me`.
- **app** — провайдеры (store, router, Firebase), guards, layouts, dialog host
  («один диалог за раз»).

### Манор и brain (по образцу `aura-bff-manor`)

1. Репозиторий `RomSribn/aura-web`, ветка `develop`.
2. `backend-structure-template/manor/setup.sh <aura-web-url> <aura-missus-url>`
   → `aura-web-manor`; brain вложенно `project/manor/missus/aura-missus`
   (`MISSUS_REPO_URL`, `MISSUS_BRANCH=master`) — у слотов будут парные worktree
   brain; `PROJECT_PREFIX=AURA`, `MASTER_BRANCH=develop`.
3. `CLAUDE.md` — по `aura-bff-manor/CLAUDE.md`: «ID-minting authority is
   aura-app-manor», в `active-work.md` «Reserved IDs — DO NOT mint here»,
   merge gate, без Co-Authored-By; хук `brain-guard.py`.
4. `.claude/aura-web-build-rules.md` — пять hard rules `aura-build-rules.md`
   для веба (контракт маршрутов в `shared/config/routes.ts`; литералы только в
   `tokens.css`; `ui` — только рендер; memo строк списков; без мёртвого кода и
   PII в логах).
5. Скиллы: `fsd` (стек-агностичный) + новый `react-web-app`.
6. Дизайн: веб-хендофф → `.claude/design_handoff_aura_web/`; мобильный
   (`OFFER`, `CHECKOUT`, `REVIEWS`, `SESSIONS_BOOKING`, иконки) — симлинком.
7. Lint с первого дня: `no-restricted-imports` как в aura-app + Steiger или
   `eslint-plugin-boundaries` (направление слоёв); typecheck, Vitest;
   Playwright e2e — только в маноре.
8. В `CLAUDE.md` app- и bff-маноров: «изменение `@aura/contracts` — перечисли
   потребителей: app, web».

### Фазы

0. Решения (`AURAD-0019`) и сверка хендоффа с дизайнером.
1. Инфраструктура: репо, манор, правила, скиллы, lint, CI, деплой.
2. BFF для веба (задачи для `aura-bff-manor`, ID — здесь): CORS, Origin на WS,
   `@Public` каталог/профиль, фильтры каталога, Firebase-домен.
3. Каркас: shared (ui-кит на токенах, api, ws), app (router, guards, layouts,
   dialog host).
4. Auth → 5. Advisors → 6. Chat → 7. Бронь с баланса + заготовка PSP →
   8. Sessions, Profile, Top up → 9. a11y, аналитика (NAVIGATION §6), e2e.

Оценка дизайнера (Plan.html) — ~8–9 недель без PSP и `/match`.

## Status

`Decided`
