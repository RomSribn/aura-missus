# AURAT-0148-008 — execute (этап 1: §1–§5 на локальном типе)

Дата: 2026-10-31 · Слот `slave-1`, ветка `feature/AURAT-0148-app-seasonal-slots`. **Не закоммичено** — всё
в индексе (`git add -A`, 81 файл) для ревью владельца.

## Что сделано

**`entities/season` (новый)**
- `model/app-config.ts` — локальная zod-схема ответа по `AURAT-0147-007` + `-010` (9 ключей `copy`,
  `promo.amountMinor`); не strict; части разбираются по отдельности; палитра без токена / с плохим hex /
  с проваленной парой → `season: null`, `promo` и `discount` остаются (A4).
- `lib/season-contrast.ts` — P1–P20 (WCAG 2.x, альфа-композит для P13–P14), `checkSeasonPalette`;
  числа сверены с `SEASONAL.md` §9 (P19/P20: winter 13.44 / 4.68, valentine 13.52 / 4.71).
- `model/season-store.ts` — модульный стор: кэш читается раз за процесс (`launch` — для сплэша),
  запрос не чаще раза в 60 с, ошибка сети оставляет сезон, 404 — «ничего» и удаляет кэш.
- `lib/config-cache.ts` — сырой ответ в `CachesDirectoryPath/aura-app-config.json` (B2); битый файл удаляется.
- `model/use-campaign.ts` — гашение каждой части по своему `endsAt` (`serverNow`, таймер на ближайший
  конец); `promo`/`discount` выключены при `BILLING_ENABLED=false`.
- `model/use-app-config-sync.ts` — на старте и при возврате на передний план (`AppState`).
- `lib/pick-ticket.ts` — правило «один билет»; **ничья 50 = 50 → discount** (A1), в шторке кода — без code-билета.
- `lib/fill-copy.ts`, `lib/hero-content.ts`, `lib/ticket-content.ts` (без сезона — встроенные слова),
  `lib/ticket-skin.ts`, `lib/prefetch-art.ts` (`Image.prefetch`), `lib/particles.ts` (порт `seasonParticles`
  прототипа, зерно 11, 14 частиц, ≤ 12 с), `config/effect-shapes.ts` (пути из `season-shapes.js`).
- `ui/SeasonHero.tsx` (164, градиент 120°, свечение, арт с проявлением 400 мс, вход 320 мс, кнопка 0.975),
  `ui/SeasonParticles.tsx` (`Animated` + native driver, повтор на фокусе, без петли), `ui/OfferTicket.tsx`,
  `model/use-offer-ticket.ts` (`useOfferTicket`, `useTicketSkin`), `model/use-launch-orb.ts`, `model/use-reduced-motion.ts`.

**shared**
- `ui/offer/TicketShell.tsx` — геометрия, тень, блик, кожа билета вынесены из `CouponTicket`;
  `CouponTicket` получил `skin`; новый `CampaignTicket` (discount / code, code — кнопка с чипом).
- «Applied» / «Auto-applied» / «You save» — новый токен **`tealInk` `#1E726B`** (P20, сообщение манора
  после одобрения, решение владельца `AURAT-0149-006`); переподтверждение спеки не требовалось.
- `Orb` / `PulsingOrb` принимают `{ base, soft }`; `theme.season` (геометрия мест), `theme.offer.couponGlyph`,
  `seasonShadowAlpha`; `bffPublicRequest` (GET без токена); `lib/promo-code.ts` `normalizePromoCode`
  (верхний регистр, без пробелов и дефисов, `A–Z0–9`, 4–20; A5 с уточнением манора).

**Места**
- Home: hero между шапкой и баннером (16 / 12), шторка кода из кнопки; `DailyCardBanner` — `bannerFrom/To/Accent`
  (искра центральной карты — gold).
- Advisors, AdvisorProfile, PromoCodeSheet — `OfferTicket` по правилу; бронь (Book / Review / Quick book) —
  welcome в коже сезона.
- Сплэш — орб из кэша прошлого запуска; до чтения кэша место орба пустое (не мигает).
- Таб-бар — `tabActive` только у активной иконки и точки.
- Пуш `action: promo` + `code` → Home + шторка с нормализованным кодом (неверный — пустое поле).

## Решение по ходу (отличие от спеки)
- **Шторку кода хостит не Home, а одна глобальная шторка** (`features/promo-code`: `openPromoCodeSheet`,
  `PromoCodeSheetHost` в `app/index.tsx`): code-билет есть ещё на Advisors и экране советника, без общей
  шторки её пришлось бы держать в трёх экранах. Пуш по-прежнему ведёт на Home. Шторка Profile осталась своя
  (у неё передачи между шторками Profile).

## Проверки (слот)
`tsc` ✓, `eslint src jest.setup.js` ✓, jest — 146 наборов / 1111 тестов ✓. Новые тесты: разбор конфига,
контраст P1–P20, правило билета (ничья), стор + кэш, гашение по `endsAt`, частицы, `fill-copy` / hero /
тексты билетов, prefetch, `SeasonHero` (с кодом / без / без арта / Reduce Motion), `CampaignTicket`
(discount, code-кнопка, кожа, `tealInk`, глиф), `usePromoCode` с `initialCode`, пуш `promo`.
`jest.setup.js`: мок `react-native-fs` получил текстовый диск (`readFile` / `writeFile` / `unlink`).
Живую проверку (экраны 67–80, холодный старт, выключение кампании) — в маноре после мёржа.

## Вне ветки (workspace, не в индексе слота)
- `.claude/design_handoff_aura/SEASONAL.md`: строка 98 `50 ≥` → `50 >` + пометка о ничьей; §2 «teal» → teal-ink;
  §9 — P19–P20 в обе таблицы + абзац о решении владельца.
- `active-work.md`: строка slave-1 и запись о запуске.
- Прототип (`prototype/seasonal.jsx` `ticketKind`) ещё с `50 >=` — не правил, источник истины — `SEASONAL.md`.

## Этап 2 (после тега `v0.27.0`) — не начат
Переход на `@aura/contracts` (`AppConfigResponse`, `fillSeasonCopy`, `formatSeasonAmount`, `checkSeasonPalette`),
§6: подписи по `blocks[].discount.kind` (строка; неизвестное → «−$X») и `expectedCostMinor` + 409
**`session_price_changed`** (константа `SESSION_PRICE_CHANGED`, переименование по ревью 0147, сообщение манора).
