# AURAT-0083-024 — execute: карточки броней по дням (2026-10-12)

По спеке `022` (одобрена в `023`). Ветка подтянула `develop` (`f130686`, с
AURAT-0085) merge-коммитом в feature-ветку. Изменения **не закоммичены**,
застейджены (вместе с правкой README из `018`).

## aura-bff

- `sessions.repository.ts` / `prisma-sessions.repository.ts` —
  `AdvisorBooking`: `status`, `firstSessionCredit`, `client {conversationId,
  chatwootConversationId, displayName, avatarId} | null` (джойн conversation →
  user в том же запросе).
- `profile/avatar.service.ts` — `openForDesk(userId, avatarId)`: текущее фото
  по пользователю, устаревший id → 404; общая проверка вынесена в
  `openCurrent` (поведение `open` не изменилось).
- `agent-desk.dto.ts` — `DeskAdvisor.avatarUrl`; `DeskBooking`; в календаре
  `busy[]` → `bookings[]`.
- `agent-desk.service.ts` — маппинг броней (trial, thisClient, клиент), URL
  аватара адвайзора (`assetUrl` + `ADVISOR_ASSETS_BASE_URL`),
  `openClientAvatar` (без хранилища → 404).
- `agent-desk-api.controller.ts` — `GET /agent-desk/api/conversations/:cwId/
  client-avatar/:avatarId` под сессией виджета, `cache-control: private,
  max-age=86400, immutable`.
- `agent-desk-page.ts` / `-page.controller.ts` — CSP
  `img-src 'self' blob: <origin ADVISOR_ASSETS_BASE_URL>`.
- `agent-desk.module.ts` — импорт `ProfileModule`.
- `client/desk.ts` → `assets/desk.js` (`desk:build`): карточки по локальным
  дням (только дни с бронями; пусто — «Броней на N дн. нет»), инициалы,
  фото клиента `fetch` + `blob:` (кэш на жизнь страницы), аватар адвайзора из
  каталога, Trial, статус, ссылка `<a target="_top">` на
  `/app/accounts/:account/conversations/:id` (аккаунт из `appContext`; нет
  аккаунта — карточка без ссылки). `desk.css` — стили полос заменены
  карточками.
- Тесты: сервис (+3), `AvatarService.openForDesk` (+3), smoke (CSP img-src,
  маршрут фото: 401 / 200 / устаревший id 404 / чужой диалог 404), jsdom (+5:
  карточки по дням, инициалы и аватар адвайзора, ссылки, без аккаунта, фото
  через blob, пустой горизонт).
- README — описание календаря.

## Отступление от спеки

Маршрут фото — `…/conversations/:cwId/client-avatar/:avatarId`, а не
`/agent-desk/api/avatars/:avatarId`: у `users.avatarId` нет индекса, а номер
диалога проиндексирован и уже резолвится; миграция не нужна. Фото отдаётся
только для клиента этого диалога и только текущее.

Попутно prettier переформатировал одну давнюю строку в `avatar.service.spec.ts`.

## Проверки (slave)

typecheck (сервер + клиент), eslint, prettier (изменённые файлы), jest 111 /
1419 — зелёные; `nest build` — ассеты в `dist`.

## Для манор

После мержа и деплоя dev: вкладка «Aura» → карточки броней адвайзора, фото у
клиентов с фото профиля, клик по карточке открывает диалог клиента.
