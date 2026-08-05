# AURAT-0010-008 — Device verification runbook (manor)

Date: 2026-08-04
For: `develop` @ `6199939`. Run in the **manor** — the slave may not start a
stack. Fill in the results at the bottom; a clean pass becomes `009-approved`.

## 0. Where things run (as observed 2026-08-04)

| Piece | Where |
|---|---|
| Chatwoot 4.15.1 (dev) | compose project `aura-cw-dev`, rails on `127.0.0.1:3001` |
| BFF Postgres | container `aura-bff-postgres-1`, host port **5433** |
| BFF Redis | container `aura-bff-redis-1`, host port **6380** |
| BFF | on the host (`npm run start:dev` in `aura-bff-manor/project/manor/master/aura-bff`), port 3000 |
| App | manor clone `aura-app-manor/project/manor/master/aura-app` |

The manor `.env` already has `BILLING_ENABLED=true`. The app flag ships
**off** — step 2 turns it on locally and step 6 turns it back.

## 1. Backend: fast blocks + advisor prices

**1.1 — add a one-minute block** so the meter can be watched end to end.
In the BFF `.env`:

```
SESSION_BLOCK_MINUTES=1,10,20,30
```

Restart the BFF (the value is read at boot).

**1.2 — register prices.** An advisor with no `advisors` row is *not bookable*
by design (AURAT-0008 D1: never a default price). Seed five of the six seed
advisors and **leave `iris` unregistered on purpose** — she is the
not-bookable test case. Prices mirror the app's seed catalog, in cents:

```bash
docker exec -i aura-bff-postgres-1 psql -U aura -d aura_bff <<'SQL'
INSERT INTO advisors (id, "priceMinorPerMinute", "createdAt", "updatedAt") VALUES
  ('mia',    199, now(), now()),
  ('laura',  249, now(), now()),
  ('mijina', 179, now(), now()),
  ('sol',    210, now(), now()),
  ('vera',   299, now(), now())
ON CONFLICT (id) DO UPDATE
  SET "priceMinorPerMinute" = EXCLUDED."priceMinorPerMinute", "updatedAt" = now();
SELECT id, "priceMinorPerMinute" FROM advisors ORDER BY id;
SQL
```

Keep this psql handy — later steps read `wallets`, `ledger_entries` and
`sessions` (all columns are camelCase, so they need double quotes).

## 2. App build

```bash
cd aura-app-manor/project/manor/master/aura-app
npm install "github:RomSribn/aura-contracts#v0.3.0"   # plain `npm install` keeps the cached v0.2.0
npm start -- --reset-cache                            # deps changed
```

Check `src/shared/config/env.ts`:

- `DEV_HOST_OVERRIDE` must be **this Mac's current LAN IP** (`ipconfig getifaddr en0`);
  it currently reads `192.168.31.55`. The phone must be on the same Wi-Fi.
  (Android over USB also works via `adb reverse tcp:3000 tcp:3000`.)
- Leave `BILLING_ENABLED = false` for check A, then flip it to `true` for the
  rest. **Neither the flag nor the IP gets committed.**

Then `npm run ios` / `npm run android` on the device.

## 3. Checks

Each step: do the action, then confirm all three columns where they apply.

### A — flag off: v1 is untouched *(do this first, it costs nothing)*

Open a chat thread with Mia.

- **App**: no session bar; "Book now" opens her profile exactly as before;
  chat sends and receives normally; Profile balance shows the `$0.00`
  placeholder and Top Up just closes.
- **Network**: no request to `/v1/sessions*` or `/v1/wallet` (BFF log is
  enough — the routes should never be hit).

Now set the app's `BILLING_ENABLED = true`, save, reload the app.

### B — an unregistered advisor is not bookable

Open **Iris** (deliberately unseeded) → "Book now".

- **App**: the sheet says *"This advisor isn't taking paid sessions yet."*,
  no blocks, no way to spend; Close dismisses it.
- **BFF log**: `GET /v1/advisors/iris/sessions/pricing` → 404.

### C — empty wallet → top up

Open **Mia** → "Book now".

- **App**: the sheet shows `Mia Nigoten · $1.99/min` and the blocks
  `1 min $1.99 · 10 min $19.90 · 20 min $39.80 · 30 min $59.70`. With a zero
  balance every block is dimmed and the button stays disabled.
- Tap **Top up** → it lands on Profile with the Top Up sheet open → pay $25.
- **App**: Profile balance becomes `$25.00`.
- **DB**: `SELECT type, "amountMinor", "balanceAfterMinor" FROM ledger_entries ORDER BY "createdAt";`
  → one `TOP_UP` row, `+2500`, balance after `2500`.

### D — book the 1-minute block

Back in Mia's thread → "Book now" → pick **1 min** → `Book · $1.99`.

- **App**: the sheet closes, a teal bar appears under the header —
  `Session · 0:59 left` counting down; a **red "Your session has started"**
  separator sits inline in the thread.
- **Dashboard** (`http://localhost:3001` → the conversation): the same
  activity line, and in the sidebar `aura_session_status = active`,
  `aura_session_ends_at`, `aura_paid_minutes_total = 1`.
- **DB**:
  ```sql
  SELECT status, "bookedMinutes", "costMinor", "startedAt", "endsAt" FROM sessions ORDER BY "createdAt" DESC LIMIT 1;
  SELECT w."balanceMinor", COALESCE(SUM(l."amountMinor"),0) AS ledger_sum
    FROM wallets w LEFT JOIN ledger_entries l ON l."walletId" = w.id GROUP BY w.id;
  ```
  → one `SESSION_CHARGE` of `-199`, balance `2301`, and
  **`balanceMinor` == `ledger_sum`** (the invariant that must never break).

### E — the meter runs it out

Wait out the minute without touching anything.

- **App**: the bar turns coral near the end (`Ends in 0:59` — with a 1-minute
  block the prompt window covers the whole run), then at zero the bar
  disappears and a **red "Your session has finished"** separator lands.
- **Dashboard**: the finished activity line; attributes back to
  `aura_session_status = none`.
- **DB**: `status = FINISHED`, `finishReason = EXHAUSTED`, `finishedAt` equal
  to `endsAt` (the block's logical end, not the job's firing time).

### F — restart mid-block

Book **10 min**, then kill the app and reopen it.

- **App**: the thread comes back with the bar running and the countdown
  showing the *correct* remaining time (it is recomputed from `endsAt`, not
  restarted). Background the app for a minute and return — the countdown
  reflects real elapsed time.

### G — extend, then end early

With that block running, tap **Extend** → pick 1 min → `Extend · $1.99`.

- **App**: `endsAt` moves out (the countdown jumps up), and **no new marker
  appears** — markers bracket the session, not each block (AURAD-0002).
- **DB**: a second `SESSION_CHARGE`, the same session row with
  `bookedMinutes` 11 and `costMinor` grown; still one row in `sessions`.

Now tap **End**.

- **App**: the confirm names the forfeit — *"The remaining N min are
  non-refundable and will not return to your balance"*. Confirm.
- **App**: the bar disappears, the red "finished" separator lands.
- **DB**: `finishReason = ENDED_EARLY`, **no refund entry**, the invariant
  still holds. Tap through a second finish if you can reproduce it — it must
  be a no-op, never an error.

### H — no double charges

- Book, and while the request is in flight tap the button again (or turn on
  airplane mode mid-book, then retry the same booking).
- **DB**: exactly **one** `SESSION_CHARGE` per intended booking. The client
  reuses its idempotency key for anything whose outcome it could not read,
  so the BFF replays instead of charging twice.
- Try booking a second block while one is running (e.g. from a cold start of
  the picker) → the app quietly switches the sheet to **extend** mode rather
  than erroring.

## 4. Roll back after the run

- App `src/shared/config/env.ts`: `BILLING_ENABLED` → `false` (never commit
  `true`, never commit the LAN IP).
- BFF `.env`: drop `1` from `SESSION_BLOCK_MINUTES` if you don't want a
  one-minute product visible.
- Advisor rows may stay — they are dev data and harmless with the flag off.

## 5. Record the result

Note per check: pass / fail + anything surprising, especially
(a) whether markers rendered red and inline in the thread,
(b) whether any session UI appeared while the flag was off,
(c) the wallet invariant after every money step.
A clean run → write `009-approved` and close the task; a failure → fix on a
branch in the slave (the code is in `develop`, so a follow-up branch off it).

## Results — run 2026-08-04, Android device, all green

| Check | Result | Notes |
|---|---|---|
| A — flag off, v1 untouched | ✓ | No session bar; Book now → advisor profile; thread and send/receive normal |
| B — unregistered advisor | ✓ | Iris: "This advisor isn't taking paid sessions yet", no blocks, no rate line (pricing 404) |
| C — empty wallet → top up | ✓ | Profile showed the real `$25.00`; `TOPUP +2500`; invariant held |
| D — booking + markers + debit | ✓ | `−1990` for 10 min; red marker stored as SYSTEM at 13:22:18, ordered between two live chatter replies |
| E — meter exhausts the block | ✓ | `EXHAUSTED`, `finishedAt == endsAt` exactly (13:32:18) — and it survived a BFF restart mid-block |
| F — restart mid-block | ✓ | App killed and reopened: countdown resumed at the correct remaining time (owner-confirmed) |
| G — extend | ✓ | One session row, `bookedMinutes` 2 / `costMinor` 398 from two separate charges, **no second marker** |
| G — early end forfeit | ✓ | Dialog stated the non-refundable remainder (owner-confirmed); `ENDED_EARLY`, `finishedAt` ≠ `endsAt`, **no refund entry** |
| H — no double charges | ✓ | Double-tap → one charge; airplane-mode failure + retry → one charge; 5 charges / 5 distinct keys |

Ledger at the end of the run — every row accounted for, invariant intact:

```
TOPUP          +2500 → 2500
SESSION_CHARGE  −1990 →  510   10-min block
SESSION_CHARGE   −199 →  311   1-min block
SESSION_CHARGE   −199 →  112   extend of that block
TOPUP          +1000 → 1112
SESSION_CHARGE   −199 →  913   H1 double-tap
SESSION_CHARGE   −199 →  714   H2 retry after airplane mode
balanceMinor 714 == Σ ledger 714
```

### Deviations from the plan (and what they bought)

- The first block was **10 minutes, not 1**: the BFF had been restarted
  *before* `SESSION_BLOCK_MINUTES=1,10,20,30` was written, so it still served
  the default set. Restarting it mid-session fixed the list — **and proved
  the meter survives a BFF restart**: the running block still finished exactly
  at its `endsAt` (delayed job in Redis plus the 60s sweep).
- The early end was triggered ~2 s before the block's natural expiry, so the
  forfeited remainder was trivial. The path is still fully exercised
  (`ENDED_EARLY`, no refund row, finished marker) — only the amount was small.

### Not covered on device (deliberately)

- **"Server accepted, response lost"** — cannot be staged reliably by hand.
  Covered by the hook's unit tests (the key is kept across a network failure)
  and already verified server-side in AURAT-0008's manor run (item 6: the same
  key twice → one ledger row).
- **Chatter-side dashboard** (activity lines, `aura_session_*` custom
  attributes) — verified and approved in AURAT-0008; unchanged by this task.
- **iOS / APNs** — this run was Android, as for AURAT-0006. The iOS leg
  remains the standing deferral.
