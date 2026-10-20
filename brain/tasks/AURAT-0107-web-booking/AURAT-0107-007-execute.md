# AURAT-0107-007 — Execute

Date: 2026-10-20
Slave: slave-1, branch `feature/AURAT-0107-web-booking` (aura-web from `develop` `708d7f6`).
Not committed — staged for review.

## Done (by spec `005` + approval `006`)

- **shared**: tags `Wallet`, `Pricing`, `Availability` in `baseApi`; `formatDayOfMonth`,
  `formatLongDate`, `formatTimeRange` (`Intl.formatRange`), `formatTimeZoneName`; `isPlainClick`
  promoted from `require-auth`; `Orb` extracted from `EmptyState` (Booked uses it too);
  `CouponTicket` booking variant (`savingMinor` → "Applied", "You save $X").
- **entities/wallet** (new): `GET /v1/wallet` (tag `Wallet`), `useWallet` (offer = server's
  `firstSessionOffer`), `BalanceChip`. Re-read: on opening the payment, after a booking / 402
  (tags), on the tab becoming visible (`app/session`).
- **entities/session**: `bookSession` mutation (invalidates wallet + this advisor's slots; every
  advisor's pricing when the offer was spent; slots on 400/409; wallet on 402) and seeds
  `getSession`; `getSession(id)` — found in `GET /v1/sessions`; `useAvailability` (14 days, the
  same read as the profile's "Next available" — `NEXT_SLOTS_DAYS` 7 → `BOOKING_DAYS` 14);
  `SessionSummary`. Ported with tests: the rest of `features/booking/lib/slots.ts`
  (`toBookingDays/Slots/Durations`, `slotEnd` for `slotRangeLabel`; data only, labels by `Intl`),
  `saving.ts`. Own: `ics.ts`. `SessionInviteCard` — `onBook` instead of a link.
- **features/book-session** (new): draft in `sessionStorage` (`{advisorId, minutes, startsAt}`,
  per advisor), `initialChoice` (link slot → draft → soonest from the chat → first open day; a
  taken link slot opens its day with a notice), `biggestSavingMinutes`, `useBookSession` (the app's
  `use-booking`), `useBookingOffer` (signed in — wallet pct backed by pricing; guest — pricing),
  dialog `book` open / params / deep-link arrival, `BookingForm`, `BookingTotal`.
- **features/pay** (new): payment-method port (`balance` only; `card` / `wallet` — `AURAT-0108`),
  `refusalOf` (400/409 → taken, 402, 404, else unknown), `usePay` (the app's
  `use-booking-confirm`: key per attempt kept until a definite outcome and across a change of
  slot; no double submit; "Still confirming…" after 10 s; closing the sheet waits for the answer),
  `PayActions` (balance row "left after" / "not enough"; short balance — **temporary** "top up in
  the Aura app", marked in code, owner `006` §8).
- **widgets/book-sheet** (new): the sheet = header (rating · private paid chat · rate), coupon,
  form, total, inline pay; sticky footer on phones. Success → `onLeave('/booked/:id')`.
- **pages/booked** (new, private): orb, "Session booked", saved pill, summary, "Open chat with
  {name}", Add to calendar (.ics). **pages/checkout** (new): redirect to the draft's sheet / catalog.
- **Entry points**: profile (Book, All dates, slots, phone action bar) open the sheet in place for a
  signed-in person, links stay for guests (gate) and new tabs; `?book=1&slot=` on arrival — the
  entry becomes the plain profile, then the sheet opens (Back from Booked / closing never reopens
  it). Chat: header calendar, invite, rail → the sheet over the thread, soonest slot chosen.
  Top nav: balance chip (desktop, signed in, billing on).
- **Strings**: namespaces `wallet`, `book-session`, `pay`, `book-sheet`, `booked-page` +
  `shared` (2 keys) + `session` (`summary`) — all 24 languages.

## Decisions during implementation

- `localDateKey` not ported: the day of a slot is found in the server's own day list (more exact
  than re-deriving the local day). `session-state.ts` not ported — no consumer yet (rule 5).
- Reload with the sheet open shows the profile (the deep link's entry is made plain to keep Back
  sane — the dialog host carries a dialog entry's URL down on close); the draft brings the choice
  back on the next Book.
- `useGate` exposes `blocked` (the arrival hook needs it).
- `AURAF-0020`: row 006 UI ✓; backlog rows 024–028 (BFF gaps 2–6 of `005`); gap 1 = `AURAT-0109`.

## Checks

`npm run lint` (eslint + Steiger) ✓, `npm run typecheck` ✓, `npm test` 880/880 ✓ (new:
`booking.test.tsx` 12 scenarios, `slots`, `saving`, `ics`, `draft`, `choice`, `saving`
(biggest), `outcome`, `dates`), `npm run build` ✓, prettier ✓.

## Open / for review

- Not tested by unit test: "Still confirming…" after 10 s (timer in `usePay`).
- Translations by language: native review welcome, Irish and Maltese first (translators' notes).
- Manor verification against bff-dev after merge (owner): money on a test account (app purchase,
  or the dev top-up stub — `005` gaps §8).
