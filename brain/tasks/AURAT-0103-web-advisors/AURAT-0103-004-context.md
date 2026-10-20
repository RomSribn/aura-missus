# AURAT-0103-004 — Context

Date: 2026-10-20

## Sources

- `AURAF-0020` rows 001–002; `AURAD-0019`; `AURAI-0007` (FSD map: `entities/advisor`,
  `entities/wallet` offer, `features/advisor-filters`, `pages/advisors`, `pages/advisor`).
- `AURAT-0102-005/006/007` (aura-bff-manor slave-2, read-only, not merged yet).
- Web handoff: NAVIGATION §0, §1.2, §2.3, §2.6, §2.7, §4, §5; README §3, §5, §6, §9;
  prototype `web/web-advisors.jsx`, `web/web-kit.jsx` (AdvisorTile/Row), `offer.jsx`.
- Mobile handoff `OFFER.md` §0, §2, §4.
- `@aura/contracts` v0.22.0: `Advisor`, `AdvisorReview`, `AdvisorCategory`, `SessionPricing`,
  `AvailabilityQuery/Response`, `FirstSessionOffer`.
- aura-app: `entities/advisor/lib/rating.ts`, `features/booking/lib/slots.ts`,
  `shared/lib/{format,dates,time-zone,monogram-tint}.ts`, `entities/wallet/model/use-first-session-offer.ts`,
  `features/booking/model/use-booking.ts` (offer only when pricing carries a credit).
- aura-web `develop` @ `9d2aa22`: routes contract (`?cat=` only, `?book=1&slot=` already parsed),
  dialog slice (`filters` kind exists), DialogHost closes on pathname change only, `useModal`,
  Sheet, EmptyState, Button, route handle `pushed` on `/advisors/:id`.

## Findings

1. **Data.** `Advisor` carries everything the profile needs (bio, specialties, rating, reviews).
   No `online`, `verified`, readings, years, reading style, language. Categories: 3
   (`LOVE`, `TAROT`, `PSYCHIC`) vs 6 chips in the handoff.
2. **Guest offer has no wire source.** The app takes `pct` from the wallet
   (`firstSessionOffer`) and shows it only when pricing carries `creditMinor > 0`. A guest has
   no wallet; the guest pricing answer (`AURAT-0102`) carries the credit but no `pct`. Catalog
   tiles and the catalog coupon need the offer without a per-advisor pricing call.
   Build rule 7 says «offer comes from the wallet's `firstSessionOffer`».
3. **Formatters conflict.** The app hand-builds English strings (`$1.99`, `Today`, `Jan`,
   `in 12 min`); web rules require `Intl` in the current language and every string translated.
   Arithmetic ports as-is; labels go through `Intl` / i18n.
4. **Availability depends on pricing**: `minutes` should be sent (shortest block from pricing);
   pricing 404 = billing off → no blocks, no slots, no offer.
5. **Review date** is not on the wire on purpose (contract note) — the handoff's «2 days ago ·
   30 min session» is dropped.
6. **Back closes dialog**: DialogHost has no history integration — to be added for every dialog.
7. **No CTA targets yet**: gate (auth task), Book sheet (booking task), chat (chat task). The
   route contract already has `?book=1&slot=` and `/chats/:advisorId` (GuestGate for guests).

Next: spec (005).
