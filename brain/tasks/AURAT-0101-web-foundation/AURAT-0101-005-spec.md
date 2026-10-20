# AURAT-0101-005 — Spec: каркас aura-web

Date: 2026-10-20
Type: task (no feature file — prepares `AURAF-0020` row 008, owns no scope row of its own)
Status: draft — на одобрение владельцу

## Цель

Пустой, но настоящий `aura-web`: собирается, линтится (направление слоёв FSD — с
первого коммита), тестируется; в нём есть всё, на что опираются экраны этапа 1, и
нет ни одного экрана или бизнес-слайса.

## Что делаем

### 1. Проект и tooling

- Vite 7 + React 19 + TypeScript strict (`noUncheckedIndexedAccess`,
  `exactOptionalPropertyTypes`), `index.html` с шрифтами Bricolage Grotesque
  600–800 и Hanken Grotesk 400–700 (Google Fonts).
- Зависимости: `react-router` 7 (`createBrowserRouter`), `@reduxjs/toolkit` 2 +
  `react-redux` 9, `firebase` 12 (только `app` + `auth`), `zod` 3 (peer контрактов),
  `@aura/contracts` = `github:RomSribn/aura-contracts#v0.22.0`.
  React Hook Form не ставим — у него нет потребителя до экрана входа.
- `@/` alias — tsconfig `paths` + Vite + Vitest.
- ESLint 9 flat: typescript-eslint, react-hooks, jsx-a11y,
  `no-restricted-imports` (паттерны aura-app, переложенные на слои веба: ничего из
  `app`, глубокие импорты в slice/shared, `../../../`), запрет `console`,
  `dangerouslySetInnerHTML`, `style` с литералами (через `no-restricted-syntax`).
  Steiger + `@feature-sliced/steiger-plugin` — в `npm run lint`.
- Prettier 3; Vitest 3 + Testing Library + jsdom.
- Скрипты: `lint` (eslint + steiger), `typecheck`, `test`, `build`, `format`; `dev`/`preview`
  есть, но запускаются только в маноре.
- `.env.example` с `VITE_*`; `.nvmrc` = 22.

### 2. `shared`

- `config/tokens.css` — токены хендоффа 1:1 вместе с телефонной шкалой отступов;
  литералы, которые в хендоффе живут в базовых классах (тени, длительности,
  easing'и, белый/чёрный, scrim), поднимаются в именованные токены
  (`--shadow-*`, `--dur-*`, `--ease-out`, `--on-accent`, `--scrim`, …). Глобально
  остаются база (`body`, `a`, заголовки), `.wrap`, `.only-phone` / `.only-desktop`,
  keyframes и `prefers-reduced-motion`. Кнопки, чипы и пикеры — не здесь: они
  войдут CSS-модулями вместе с первым потребителем.
- `config/breakpoints.ts` — `PHONE_MAX = 760`, `NAV_ICONS_MAX = 900`,
  `NAV_SEARCH_MAX = 1180` и media-строки; совпадают с CSS (тест сверяет с
  `tokens.css`).
- `config/routes.ts` — контракт маршрутов: пути всех экранов (`/`, `/match`,
  `/advisors`, `/advisors/:id`, `/checkout`, `/booked/:id`, `/chats`,
  `/chats/:advisorId`, `/sessions`, `/me`), билдеры путей, приватные маршруты, и
  типизированные search params из NAVIGATION §5 (`?q=`, `?cat=`, `?book=1&slot=`,
  `?id=`) — парсеры и билдеры с тестами.
- `config/env.ts` — единственное место чтения `VITE_*`, проверка Zod при старте:
  `VITE_BFF_ORIGIN`, `VITE_BFF_WS_PATH` (по умолчанию `/ws`), `VITE_FIREBASE_*`
  (apiKey, authDomain, projectId, appId), `VITE_PSP_ENABLED` (по умолчанию `false`).
- `api/firebase.ts` — инициализация Firebase JS SDK; `getIdToken(force?)`,
  `signOut()`, статус входа как внешний store (`loading | guest | signed-in`) +
  хук `useAuthStatus()`. Токен не уходит ни в Redux, ни в `localStorage`, ни в логи;
  персистентность — у SDK.
- `api/` — порт из aura-app `src/shared/api/bff/` с тестами (Jest → Vitest),
  поведение не меняется, шапка `// Ported from aura-app …`:
  - `server-clock.ts`, `refusal-code.ts`, `account-deleted.ts` — как есть;
  - `base-query.ts` — `BaseQueryFn` для RTK Query по логике `bffRequest`:
    `Bearer` токен, один повтор на 401 с принудительно обновлённым токеном,
    `ACCOUNT_DELETED` → сообщить и не повторять, ошибка несёт только статус и
    refusal-код (тело не логируется), часы из `Date` на каждом ответе,
    `BILLING_DISABLED_STATUS = 404`.
    **Расхождение с приложением:** у гостя запрос уходит без `Authorization`
    (публичные маршруты `AURAT-0102`), а не падает 401 до сети;
  - `base-api.ts` — один `createApi` без эндпоинтов, `tagTypes` объявлены здесь;
  - `ws-client.ts` — `BffSocket` как в приложении (свежий токен на попытку,
    backoff 1 → 30 с + 25 % jitter, причина `ACCOUNT_DELETED` при закрытии) плюс
    `WsServerEvent.safeParse` для каждого кадра. Подключение к кэшу RTK Query —
    с первым потребителем (чат).
- `model/dialog.ts` — Redux-slice «один диалог за раз»: `openDialog({kind, props})`,
  `closeDialog()`; `DialogKind` = список хендоффа (`auth`, `book`, `reschedule`,
  `cancel`, `topup`, `edit`, `filters`). В `shared`, потому что открывать диалоги
  будут features, а `app` импортировать нельзя.
- `lib/use-narrow.ts` — `useNarrow()` на `matchMedia` из `breakpoints.ts`.
- `ui/` (CSS Modules, только токены, всё через `shared/ui/index.ts`):
  - `Icon` — 40 глифов хендоффа (36 приложения + `percent`, `sale`, `briefcase`, `coin`);
  - `IconButton` — обязательный `aria-label`, цель ≥ 44 px на телефоне;
  - `Sheet` — модалка на desktop / bottom sheet на телефоне (одна разметка, CSS),
    `role="dialog"`, `aria-modal`, `aria-labelledby`, focus trap, Esc и scrim
    закрывают, фокус возвращается на триггер, `prefers-reduced-motion`;
  - `EmptyState` — пульсирующий teal-орб 3.4 с, title / text / CTA;
  - `Field` — подпись внутри поля, акцентная рамка на фокусе, `locked`, `format`;
  - `Toggle` — `role="switch"` + `aria-checked`;
  - `Button` — primary / teal / ghost / soft (нужен EmptyState и GuestGate).

### 3. `app`

- `providers/` — Redux store (`baseApi` reducer + middleware, `dialog`), Firebase
  (подписка на статус входа; `onAccountDeleted` → `signOut()` + сброс кэша API),
  `RouterProvider`. Глобальный импорт `tokens.css`.
- `router.tsx` — `createBrowserRouter` из путей `shared/config/routes.ts`. Экранов
  нет: маршруты этапа 1 объявлены в layout и пока отдают пустой `<main>`; неизвестный
  путь — `NotFound` (EmptyState «Page not found · Go home»). Каждый экран
  подключится своей задачей одной строкой.
- `layouts/app-layout` — оболочка: шапка (логотип → `/`, ссылки Home / Advisors /
  Chats / Sessions с активной вкладкой), на телефоне ссылки — нижний таб-бар
  (CSS, без `backdrop-filter` у шапки), `<main>`; флаг маршрута `handle.pushed`
  прячет таб-бар и включает `.has-actionbar`. Правая часть шапки (Log in /
  Get started, баланс, аватар) — со своими задачами (auth, wallet): ей нужны
  бизнес-данные.
- `dialog-host` — рендерит текущий диалог из реестра `app/config/dialogs.ts`
  (пока пустого — `auth` зарегистрирует задача входа), закрывает диалог при смене
  маршрута (NAVIGATION §1.2).
- `guards/private-route` — `/chats`, `/sessions`, `/me`: пока статус `loading` —
  ничего личного не рисуется; гость видит `GuestGate` (EmptyState, текст из
  `app/config/copy.ts`, CTA **Log in** → `openDialog({kind: 'auth'})`), без имён,
  балансов и бейджей; вошедший — `<Outlet/>`.

### 4. Проверки

Тесты: порт `http-client` (→ base-query), `server-clock`, `ws-client`
(+ отбрасывание кадров, не прошедших `WsServerEvent`); `routes` (билдеры и
парсеры); `env`; `breakpoints` ↔ CSS; `Sheet` (роль, Esc, scrim, focus trap, возврат
фокуса); `Toggle`, `Field`, `EmptyState`; `dialog` slice; `private-route` (гость
→ GuestGate без личных данных, вошедший → outlet, `loading` → пусто).
Зелёные `npm run lint && npm run typecheck && npm test && npm run build`.

## Вне задачи

Экраны и бизнес-слайсы (entities, features, widgets с данными), TopNav справа,
AuthFlow, деплой и CI, Playwright, PWA, аналитика. Dev-сервер — только в маноре
после merge.

## Решения для владельца

1. **Гость и BFF.** Base query у гостя шлёт запрос без `Authorization` (под
   `@Public`-маршруты `AURAT-0102`) — расхождение с `bffRequest` приложения, который
   без токена падает 401 до сети. Предлагаю так.
2. **Атомы без потребителя.** `Field` и `Toggle` в этой задаче не используются
   никем, кроме тестов, — это против правила 5 («экспорт без потребителя не
   мёржится»), но они в списке заглушки. Предлагаю: оставить (как в заглушке),
   разовое исключение для каркаса. Альтернатива — перенести их в задачу входа.
3. **Firebase web-приложение.** Нужна регистрация Web App в проекте `aura-2781b`
   (консоль Firebase → Project settings → Add app → Web) и значения
   `VITE_FIREBASE_*` в `.env.local` манора. Для lint / typecheck / test / build в
   слоте они не нужны; для `npm run dev` в маноре — нужны. Это действие владельца.
