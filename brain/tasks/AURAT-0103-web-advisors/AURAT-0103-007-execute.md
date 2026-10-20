# AURAT-0103-007 — Execute

Date: 2026-10-20
Slave: slave-1, `feature/AURAT-0103-web-advisors`. Not committed — staged for review.

## Code (`aura-web`)

- **shared**
  - `config/routes.ts` — catalog URL contract: `?cat&sort&pmin&pmax&rating` (`ADVISOR_SORTS`,
    `ADVISOR_RATING_FILTERS`, `advisorsSearchParams`); bad values are dropped.
  - `config/breakpoints.ts` — `NAV_SEARCH_MAX = 1180` (the catalog grid drops to 3 columns).
  - `config/tokens.css` — `--mono-1…6` (monogram tints), `--shadow-coupon`, `--sheen`.
  - `lib/` — ports `format.ts` (`discountedMinor`), `dates.ts` (`daysUntil`), `time-zone.ts`,
    `monogram-tint.ts` (returns `var(--mono-N)`); the web's own `formatUsdMinor`, `formatTime`,
    `formatWeekday` (`Intl`), `localSlotKey` (for `?slot=`), `cssVars`.
  - `ui/` — `PriceTag`, `OffChip`, `CouponTicket` (teaser), `Avatar` (photo over monogram),
    `Stars`, `ButtonLink` + `size="sm"` on `Button`.
  - `i18n/namespace.ts` — `Translation` accepts i18next plurals (`_one/_few/_many/…`);
    `i18n.test.ts` checks each plural key's forms against `Intl.PluralRules` per language.
- **entities/advisor** — `getAdvisors` (`@Public`, `AdvisorsResponse.parse`), `useAdvisors`,
  `useAdvisor(id)` (same cache via `selectFromResult`), port `lib/rating.ts` (+ `formatRating`,
  `starsFromTenths`), ui `AdvisorTile`, `AdvisorRow`, `ReviewCard` (memo, the whole card links
  to the profile, the buttons sit on top of it).
- **entities/session** — `getSessionPricing`, `getAvailability` (`parse`, public, optional
  token), `offerPctFromPricing` / `shortestBlockMinutes`, port `nextFreeSlot` →
  `nextFreeSlots`, hooks `useSessionPricing` (`billing: loading|on|off|unknown`, 404 = off),
  `useNextSlots` (7 days, the shortest block, browser tz, server clock).
- **features/advisor-filters** — `filterAdvisors` / `priceBounds`, `useCatalogResults` (URL,
  `replace`, keeps the history entry's state), `CategoryChips`, `FiltersBody` (two-thumb price
  slider + rating radios + Reset), `SortSelect`, `FiltersButton`, `FiltersSheet` (dialog
  `filters`).
- **pages/advisors** — catalog: title + count + coupon, chips, rail (desktop), results bar
  (Filters on phones, Sort, grid ⇄ list in localStorage), 24 per page + Show more, empty /
  error / skeleton states. Chat free → `/chats/:id`, Book → `/advisors/:id?book=1`.
- **pages/advisor** — profile: back link, photo, role, name, tagline, stats (rating · reviews, price
  per minute), specialties, About, reviews 3 → all, 24 at a time; sticky card (OffChip,
  PriceTag, 4 slots → `?book=1&slot=`, All dates, Book session, Free chat, note) + coupon; phone
  action bar. Billing off → no slots, Book or offer.
- **app** — routes `/advisors`, `/advisors/:id` → pages; `filters` in `DIALOGS`; `DialogHost`:
  each dialog pushes its own history entry, Back closes the dialog, × steps back, and a URL
  changed inside the dialog carries over onto the entry below (filters are not lost);
  namespaces in `I18N_NAMESPACES` and `vitest.setup.ts`; `matchMedia` stub in the test
  setup (jsdom has none).
- **Strings** — namespaces `advisor`, `advisor-filters`, `advisors`, `advisor-page` + additions
  to `shared`; en + 23 EU languages, plurals per language.

## Checks

`npm run lint` (eslint + steiger), `tsc -b`, `vitest` — 22 files / 268 tests, `vite build`,
`prettier --check` — all green. New tests: ports, routes, `filterAdvisors`,
`offerPctFromPricing`, `nextFreeSlots`, `app/__tests__/advisors.test.tsx` (catalog, chips → URL,
sort/rating from the URL, empty state, pages of 24, billing off, catalog error, Filters sheet,
Back closes the dialog and keeps the filters, ×, profile: slots/offer/deep links, reviews,
billing off, not found).

## Decisions during implementation

- Category labels live in `advisor-filters` (the only consumer), not in the entity.
- The phone bar has a stacked PriceTag; while pricing is loading the phone CTA is
  not drawn (no flicker between Book and Free chat).
- `Write a review`, Online/Verified, readings/years, Reading style, Language — not drawn
  (spec §3–5).

## Brain

- `AURAF-0020`: UI ✗ → ✓ in rows 001 and 002, a context line. On the closing missus commit,
  expect a line conflict with `AURAT-0102` (BE ✓ on the same rows) if it has been merged
  into `aura-missus` by then.

## Open

- Live check in the manor after the `AURAT-0102` merge (guest with no token, CORS, prices and
  slots from bff-dev, a phone at 390 px).
- Native speakers did not review the translations; the agents flagged the places worth a
  look: Czech/Croatian/Finnish/Hungarian/Polish wording around `{{name}}`, inflection of
  "Aura" (et/fi/hu), Maltese/Latvian.
- `npm audit` — as in `AURAT-0101`, no new dependencies.
