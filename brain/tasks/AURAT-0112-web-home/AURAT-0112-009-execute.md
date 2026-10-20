# AURAT-0112-009 — Execute: схема сессий AURAT-0110

Date: 2026-10-20

Ревью `007` пройдено (сессия штаба slave-0-2a по поручению владельца), `AURAT-0110` в develop
(`d4e6772`).

## Коммиты (ветка `feature/AURAT-0112-web-home`)

- `7dc4348` — шаг `007` (главная).
- `0b25127` — merge `origin/develop` (`d4e6772`) + переход на схему `0110`.

## Сделано (план `008`)

- Конфликты в 8 файлах (`app/config/i18n.ts`, `vitest.setup.ts`, `entities/message/index.ts`,
  `entities/session/{api/session-api.ts,index.ts}`, `shared/api/base-api.ts`,
  `shared/lib/{index.ts,__tests__/dates.test.ts}`) — в пользу `0110`; namespace обеих задач.
- `entities/session`: свой `getSessions`, тег `Sessions` и его инвалидация убраны.
  `useNextSession` — через `sessionApi.useGetSessionsQuery(undefined)`, как `useSessions` (один
  кэш; `session.updated` патчит его на месте), гостю `skipToken`.
- `lib/next-session` — поверх `splitSessions`: ACTIVE первой, иначе верх Upcoming. Тест обновлён.
- `shared/lib/dates.ts`: один `formatMonthShort` (из `0110`); `formatDaysAway` убран — карточка
  берёт `relativeDay` + `session:relative.*` («Next session · In 3 days»).
- `entities/message/index.ts`: без `useChatLive` + `saveQuestion` / `loadQuestion` /
  `forgetQuestion`.

## Проверки

- typecheck, lint (eslint + steiger), build, `prettier --check .` — чисто.
- `npm test`: 1145 / 1146 — падает только `advisors.test.tsx` «the next 4 slots» (часы в тесте;
  чинит `AURAT-0108`, придёт через develop — не трогаем).

## Дальше

- Дельту смотрит штаб (slave-0-2a); затем merge — через AskUserQuestion владельцу.
- Если `AURAT-0108` попадёт в develop раньше — влить develop в ветку ещё раз (конфликты текстовые:
  `app/config/i18n.ts`, `shared/config/index.ts`, `vitest.setup.ts`).
- «Session in progress» на главной — спека `AURAT-0114` (slave-4).
