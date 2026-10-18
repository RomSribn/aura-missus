# Aura — Checkout redesign: pay for a session in one tap (brief for design)

You designed Aura's design system and the handoff we build from (`tokens.css`,
`ui.jsx`, `booking.jsx`, `offer.jsx`, `settings-chat.jsx`, screens `16`, `21`,
`22`, `44`–`46`, `MOTION_AND_ICONS.md`, `SESSIONS_BOOKING.md`, `OFFER.md`). This
round redesigns **how a user pays** for chat time. Work **inside that system**:
the same tokens, type classes, radii, components, icons and motion. Do not
introduce a new visual language. If you truly need a new token, name it, give
its value and say why no existing one fits.

## 1 · The problem

Today a session can only be paid from the **Aura balance** (a prepaid USD
wallet). When the balance is short, the Review button reads **"Top up to book"**
and sends the user out of booking to Profile → Top Up. After topping up, they
have to start booking again from scratch: advisor, date, time, length. In our
first ad campaign, 33 people got an invitation to a paid session and **none**
booked.

## 2 · The new behaviour (already decided — design it, don't re-decide it)

Wherever the user pays for time, they **choose a payment method**:

- **Aura balance**: as today.
- **The store**: **"Google Play"** on Android, **"App Store"** on iOS. Tapping
  pay opens the platform's own native purchase sheet, with the card the user
  already has in their Google or Apple account, Face ID or fingerprint. Our
  server credits the amount, and **the session books itself right after**. The
  user lands on the existing "Session booked" screen and never leaves the flow.

Rules the UI must express:

1. **Default selection.** The balance covers the cost → "Aura balance" is
   selected. It doesn't → the store row is selected.
2. **"Use my balance" toggle.** Show it under the store row **only when the
   balance covers part of the cost** (0 < balance < cost). On by default: the
   store charges only the shortfall. Off: the store charges the full price and
   the balance is left alone. Hide it when the balance is $0 or already covers
   everything.
3. **Store amounts are whole dollars, rounded up.** The remainder (always
   under $1) **stays on the balance** and must be shown, not hidden:
   - Session $14.50, balance $0 → the store charges $15, and **"$0.50 stays on
     your balance"**.
   - Session $33.40, balance $4 (toggle on) → the store charges $30, and
     "$0.60 stays on your balance".
   - Session $32.00, balance $4 → the store charges $28, no remainder line.
4. **The CTA shows the store's own price, in the buyer's currency.** For a
   Canadian user a $29 credit may be charged as **CA$40.49**, so the button
   reads "Pay CA$40.49 & book". The breakdown still states the USD amount that
   gets credited. Design for both cases: same currency, and a different
   currency where the two figures differ.
5. **Fallback.** If the store is unavailable, the row is simply absent and the
   screen behaves exactly as today ("Top up to book"). Design that state as
   well: it is the one users see while the products are being published.
6. **The balance is still the internal rail.** Money always passes through it.
   Cancelling a session refunds to the **balance**, never to the card. The copy
   must not promise otherwise.

Example layout (wireframe only — the visual design is yours):

```
Pay with
 ◯  Aura balance                       $4.00 · not enough
 ◉  Google Play                        Saved card · one tap
      [✓] Use my balance · $4.00

 Total                                  $33.00
 From balance                           −$4.00
 Google Play                            $29.00

 [ 🔒 Pay $29.00 & book ]
 Free cancellation up to 24 h before
```

## 3 · Hard constraints (store and brand rules — not negotiable)

- **Never label the store row "Apple Pay" or "Google Pay"**, and never use
  their marks or logos. This is an App Store or Google Play purchase, not Apple
  Pay or Google Pay. Apple's Apple Pay guidelines forbid using it for in-app
  purchases, and the user would be shown something other than what they get.
- **Never name the other platform.** An iOS screen that says "Google Play" is
  rejected at App Review (2.3.10). Every surface comes in an iOS and an Android
  variant.
- **The app never invents a price.** Every figure comes from the server (the
  session price, the −50% offer) or from the store (the local price). Design
  around values that arrive, including a loading state for the store price.
- **No dark patterns**, consistent with `OFFER.md`: no countdowns, no "N people
  booked", no pre-ticked upsells. "Use my balance" is on by default because it
  saves the user money. No other default may cost them more.
- **Copy is English.** Sessions are chat-only: no video or call vocabulary.
- **First-session offer.** When it is active, the Review screen keeps the
  coupon ticket, the struck-through total and "You save $X · Free cancellation
  up to 24 h before" exactly as in `45-offer-review.png`. The payment section
  must sit with them cleanly.

## 4 · Surfaces to design

### 4.1 Review (`21-book-review.png`, `45-offer-review.png`) — main surface

Replace the payment section. Delete the **"Visa ···· 4242 · Default"** row: no
card is ever stored on our side, and this row is what the store row replaces.
Keep the row anatomy from `SESSIONS_BOOKING.md` §3 (radius 16, 1.5px border,
22px radio disc, accent border plus coral check disc when selected). Decide
whether the "Use my balance" toggle, the breakdown lines ("From balance",
"Google Play", the remainder note) and the CTA are styled as part of the
existing Price card or as a separate block.

Variant matrix: render each, or show the logic clearly:

| | Balance covers it | Partial balance | Balance $0 | Store unavailable |
|---|---|---|---|---|
| No offer | ✓ | ✓ | ✓ | ✓ |
| Offer −50% active | ✓ | ✓ | ✓ | — |

Show the partial-balance case with the toggle **on** and **off**. Show one
case with different currencies (CA$). Show iOS **and** Android for at least the
partial-balance case. Keep the balance-covers-it case with the store row
selected manually: decide whether the store row should be offered at all when
the balance is enough. We lean towards keeping it, as an honest choice of
method. Show us both and say which you'd ship.

### 4.2 Quick book sheet (in the chat; built in the app, not in your handoff)

What it looks like today: title **"Book a session"**; an availability card
("Available right now" / "Soonest free time", with "Starts immediately" or the
time); duration chips with prices (with offer chips when the offer is active);
a **"Balance $X"** line; the CTA **"Start now · $X"** / **"Book · $X"**; a text
link **"Another time"** that opens the full grid. Today a short balance sends
the user to Profile.

Design the **compact** version of the same choice for a bottom sheet: the
method selector, the toggle and the remainder note, without turning the sheet
into the Review screen. CTAs: "Pay $X & start now" / "Pay $X & book".

### 4.3 Extend sheet (during a live session) — time-critical

What it looks like today: title **"Add more minutes"**; block chips; a
**"Balance $X · Top up"** line (the "Top up" link leaves the chat); the CTA
**"Extend · $X"**; a link **"End session early"**; the note that a started
block is non-refundable. The user is **in a running paid session** and the
clock is ticking, so this is where one tap matters most. Replace "Top up" with
the same compact method choice. CTA: "Pay $X & extend". Keep the
non-refundable note.

### 4.4 The paying moment and its outcomes (all three surfaces)

Design each state once and say how it maps to Review, Quick book and Extend:

| State | What happens | What the user sees (your design) |
|---|---|---|
| Store sheet open | the OS shows its own sheet over the app | our CTA in a busy state behind it |
| Crediting | the store said OK, our server is crediting | e.g. "Adding $29 to your balance…" on the button |
| Booked | done | existing `22-booked.png` / `46-offer-booked.png`; add the remainder line if there is one |
| User closed the store sheet | nothing was charged | back to normal, **no** error |
| Store error | nothing was charged | inline error, as today's Review error line |
| **Slot taken while paying** | money is on the balance, the booking didn't happen | "That time was just taken. $29 is on your balance — pick another time." plus a path to the grid (Review / Quick book) |
| **Payment pending** (Android slow methods, iOS Ask to Buy) | the money will arrive later, **no booking will be made** | "Your payment is processing. We'll add it to your balance when it clears." |
| Credited, booking failed for another reason | money is on the balance | honest message plus retry, which now pays from the balance |

### 4.5 Profile → Top Up sheet (`16-sheet-topup.png`) — consistency only

The four tiers ($10 / $25 / $50 / $100) **stay**. Your prototype shows a
"Visa ···· 4242 · Change" row and a "Pay $25.00" button. Production pays
through the store and shows the store's local price under each tier. Align this
sheet's payment row with the store row language from 4.1 ("Google Play" /
"App Store", no card number, no "Change"). No other changes.

## 5 · Use what exists

- **Tokens** (`tokens.css`): `--paper`, `--paper-2`, `--card`, `--card-2`,
  `--ink`, `--ink-2`, `--ink-3`, `--line`, `--line-2`, `--accent`,
  `--accent-soft`, `--accent-ink`, `--teal`, `--teal-soft`, `--plum`,
  `--plum-2`, `--gold`, `--r-card`, `--r-row`, `--font-d`, `--font-b`.
  The two-tone rule holds: **coral = paying / CTA**, **teal = good news**
  (savings, "Applied", remainder that stays yours).
- **Type**: `.title-xl / -l / -m`, `.body`, `.muted`, `.muted-3`. Use the
  sizes already used on Review (rows 14.5/700, notes 11.5 ink-3).
- **Components**: `Button` (primary, soft, ghost; `sm`), `Sheet`,
  `StickyFooter`, `Pill`, the offer set `PriceTag`, `OffChip` and
  `CouponTicket`, the payment row from `BookReview`, and the segmented control
  if you use one.
- **Icons**: only the existing 36-icon set (`icons/AuraIcon.tsx`). For payment
  these are `card` (payment), `gift` (balance), `lock` (Confirm & pay), `check`
  (selected), `shield` (refund / safety), `sale` (offer), `clock`, `x`. If you
  need a new glyph, draw it in the same stroke style, add it to the set and to
  the name → usage map. **No third-party store logos.**
- **Motion**: only tokens from `MOTION_AND_ICONS.md`: bottom sheet 320ms
  `cubic-bezier(.22,1,.36,1)`, button press 0.975, selection 150ms, CTA
  enable 150ms with a label swap. A toggle or method switch must not move the
  layout under the thumb: reserve the space for the toggle and the remainder
  line, or animate them in with `FadeInDown 250ms`.

## 6 · Deliverables

1. **Prototype**: update `booking.jsx` (Review) and `settings-chat.jsx`
   (Top Up), or add a `checkout.jsx` with the shared pieces. Add Tweaks
   toggles for **platform (iOS / Android)**, **balance ($0 / partial / enough)**,
   **offer (on / off)** and **store currency (USD / CAD)**, so every variant
   can be clicked through.
2. **Flat renders**, numbered after the last one, starting at
   `47-pay-review-partial.png`. Cover at least: Review in the partial,
   zero-balance and enough-balance cases, the fallback, CAD, and iOS vs Android;
   Quick book short of balance; Extend short of balance; crediting; slot taken
   after paying; pending.
3. **`CHECKOUT.md`**, in the same format as `OFFER.md`:
   - rules;
   - components with exact sizes and tokens (e.g. `PayMethodRow`,
     `UseBalanceToggle`, `PayBreakdown`, `RemainderNote`);
   - a "where it appears" table;
   - a state table (§4.4);
   - a copy table with every string, iOS and Android columns;
   - motion.
   Name it plainly. **Do not call any handoff file `CLAUDE.md`.**
4. If you build RN references (as in `rn/`), keep them reference-only, using
   the same atoms as `rn/AuraOffer.tsx`.

## 7 · Answer in the handoff

- Should the store row be offered when the balance already covers the cost?
  Show both and recommend one.
- The store row subtitle: we proposed "Saved card · one tap" (Android) and
  "Apple Account · Face ID" (iOS). Improve it if you can, within the
  constraints above.
- Is "Use my balance" a toggle, a checkbox or a split row? Pick one and justify
  it in one line.
