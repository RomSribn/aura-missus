# AURAT-0148-010 — правки по ревью `-009`

Дата: 2026-11-01. Слот `slave-1`, не закоммичено (в индексе).

- **C8 (владелец):** `entities/season` → **`entities/campaign`** (`git mv`, импорты `@/entities/campaign`).
- **B1:** пуш `promo` ведёт на Home с параметром `promoSheet { code, at }` (`MainTabParamList`), шторку
  открывает фокус Home и тратит параметр. Глобальная шторка открывается через `whenNoSheetShown`:
  `shared/ui/bottom-sheet/presence.ts` считает показанные `BottomSheet` от показа до `onClosed`
  (нативная отставка); снятая вместе с экраном шторка перестаёт считаться через 600 мс.
- **B4:** `openPromoCodeSheet` при открытой шторке подставляет новый код (`request` в сторе;
  `usePromoCode(visible, onRedeemed, { code, request })`).
- **B2:** `useLive` сдвигает `now` при каждом новом конфиге; тест «смонтировать → время идёт → конфиг с
  уже прошедшим `endsAt`».
- **B3:** `normalizePromoCode` — один в один с сервером: NFKC + `NOISE` (`\s`, U+00AD, U+200B–200D,
  U+2060, U+FEFF, `-`, U+2010–2015, U+2212); тесты на U+2011, U+2013, U+2212, полноширинные, NBSP.
- **B6:** глиф билета при `onError` → иконка `percent` / `tag`; арт hero с `key={uri}`.
- **B7:** кэш пишется в `….writing` и переносится (`moveFile`); отсутствие файла не удаляет ничего,
  удаляется только не-JSON.
- **B8:** `bffPublicRequest` не трогает `serverNow` (ответ из HTTP-кэша / CDN несёт старый `Date`).
- **C2:** `OfferTicketState` — union по `kind`; `onPressCode` отдельным пропом `CampaignTicket` /
  `OfferTicket`; без него билет кода — не кнопка и без «Tap to apply». Экраны отдают `applyCode`.
- **C3:** из публичных API убраны `LaunchOrb`, `AppConfig`, `SeasonPalette`, `SeasonHeroContent`,
  `heroContentOf`, `useCampaign`, `DEFAULT_TICKET_SKIN`.
- **C4:** `useSeasonHero` / `useSeasonBanner` / `useSeasonTabAccent` в `model/use-season-places.ts`; Home и
  таб-бар больше не раскладывают палитру.
- **C5:** `useReducedMotion` и `useReplayOnFocus` — `shared/lib/motion.ts`; на них `TicketShell`,
  `SeasonParticles`, `SeasonHero`. Остальные 7 вызовов `isReduceMotionEnabled` — позже (`-009`).
- **C6:** у hero нет `onLayout`-ширины (колонка — `marginRight: heroCopyInset`); `SeasonHero`,
  `SeasonParticles`, `FallingShape` — `React.memo`, интерполяции — `useMemo`.
- **C7:** в `use-quick-book` комментарий снова над своим выражением.
- Из «позже» сделано попутно: non-null assertions в `active-parts` / `pick-ticket`; тест частиц — эталон
  из прототипа (первые три снежинки и вторая «сердечка» числами); `copy-and-parts.test.ts` разбит;
  тесты `ticketSkinOf`, кэша, стора шторки, счётчика шторок.

Проверки: `tsc` ✓, `eslint` ✓, jest 150 / 1123 ✓.
