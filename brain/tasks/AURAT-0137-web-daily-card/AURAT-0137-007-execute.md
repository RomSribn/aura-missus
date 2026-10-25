# AURAT-0137-007 — Execute

Date: 2026-10-23

Ветка `feature/AURAT-0137-web-daily-card` перемотана на develop `d934d3c` (там уже `AURAT-0123`,
контраст) до первой правки — карта дня сразу на её токенах. Не закоммичено, всё в stage.

## Что сделано (по спеке `005`, решения 1–7 = А)

- **`entities/tarot`** (новая): `api/daily-card-api.ts` — `GET /v1/tarot/daily?tz=` (зона
  устройства, без даты; `DailyCardResponse.parse`), `POST …/drawn` (сначала `drawn: true` в кэше,
  запись следом); `model/use-daily-card.ts` — гостю не ходит, смена дня: дата в зоне по часам
  сервера ≠ `localDate` → перечитка (при монтировании и возврате во вкладку); `lib/local-date.ts`
  + тест; `ui/tarot-card-back.tsx`, `ui/tarot-card-face.tsx` — общие рубашка и лицо (лицо — арт
  `cover`, имя своим шрифтом, если арт не загрузился).
- **Пикер в чате** (`features/tarot-pick`) — на общих карточках, вид тот же.
- **`pages/daily`**: порт приложения с тестами — `config/ritual.ts`, `lib/deck-layout.ts`,
  `lib/tarot-advisor.ts`, `lib/phase-copy.ts`, `model/use-ritual.ts` (reduced motion и повторный
  вход — сразу карта); `model/use-daily-page.ts`; UI — `ritual-stage` (числа конфига → CSS-переменные,
  `transform`/`opacity`-переходы, задержка 28 мс на карту, переворот `rotateY`), `card-reveal`
  (float-in), `daily-page` (радиальный плюм, колонка 440 px, «← Home», ожидание, ошибка + Try again,
  «Ask an advisor» + «Chat is free to start»; на телефоне CTA прибит внизу).
- **Маршрут** `/daily` (`shared/config/routes.ts`), в роутере — под `PrivateRoute`, `gate('daily')`,
  `pushed`. GuestGate `daily`.
- **Вход с причиной `daily`**: `AUTH_REASONS` в `shared/model/dialog.ts` — один источник и для
  `pending-sign-in` (zod). Тексты: «Log in to draw your card», «One free card a day — the same one
  in the Aura app.», «Draw my card».
- **Черновик в чат**: `ChatEntryState` / `parseChatEntryState` в `routes.ts`; `ButtonLink` несёт
  `state`; `useComposer` берёт черновик из history state и сразу снимает его (`replace`, тот же
  путь — скролл не трогается). `entities/message` — `useAdvisorsOnline` (карта присутствия).
- **Баннер на Home** (`pages/home/ui/daily-banner.tsx`) — между Ask-блоком и «Top advisors»; веер из
  трёх рубашек, «Draw your card of the day» / «One free pull every day», FREE, «Draw today’s card»;
  вытянута — имя карты, «Drawn today», «See your card». Ссылка растянута на всю полосу; гостю —
  `gateLink` с причиной `daily`.
- **Токены**: `--plum-hi`, `--on-plum-glass`, `--gold-line`, `--glow-tarot`, `--on-plum-teal`,
  `--r-tarot`, `--r-tarot-hero`, `--r-tarot-sm`. Тест контраста: золото и `--on-plum-teal` на
  `--plum` / `--plum-2` ≥ 4.5:1 (teal на plum — 4.69 / 5.49). Дата — `--on-plum-3`.
- **Тексты** — 24 языка: новый неймспейс `daily-page`, `home-page.daily`, `auth-by-phone`
  (`title/sub/name.continue.daily`), `app.gate.pages.daily`. Падежи: имя карты (англ.) не
  склоняется — «karta {{card}}», в славянских/балтийских черновик без рода говорящего.

## Проверки

`npm run lint` (eslint + steiger), `npm run typecheck`, `npm test` — 87 файлов, 1529 тестов,
`npm run build` — зелёные. Новые тесты: `app/__tests__/daily.test.tsx` (баннер гостю/вошедшему/
вытянута, `tz` без даты, GuestGate, ритуал → раскрытие → один POST, повторный вход без ритуала и
POST, reduced motion, ошибка → Try again, Ask → `/chats/sol` с черновиком и снятым state),
`use-ritual`, `deck-layout`, `tarot-advisor`, `local-date`, composer (черновик), routes.

## Отступления от спеки

- Тег `DailyCard` в `shared/api` не заведён: инвалидировать нечего — `drawn` правится в кэше,
  перечитка — `refetch`.
- Длительности ритуала — не токены `tokens.css`, а `config/ritual.ts` → CSS-переменные на сцене
  (одна правда для таймлайна и переходов, как `--flip-ms` пикера).
- Спиннера ожидания нет (в вебе его нет) — строка «Reaching for your card…» пульсирует.

## Brain

`AURAF-0020`: строка 013 UI ✓, бэклог 053 (колода на языке человека), абзац «UI 013 — AURAT-0137».
Номер 053 может совпасть с параллельной `AURAT-0136` — манор перенумерует при мёрже.

## Открыто

Живая проверка — в маноре на web-dev после мёржа (анимация, телефон, гость → вход → `/daily`,
«Drawn today» общий с приложением).
