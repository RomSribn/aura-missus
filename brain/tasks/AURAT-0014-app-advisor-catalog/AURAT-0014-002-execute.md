# AURAT-0014 — 002 execute

**Date:** 2026-08-13 · 55 files, `@aura/contracts` v0.3.0 → **v0.4.0**

## What the entity became

`entities/advisor` stopped being a data file and became a slice with an API:

```
advisor/
  api/advisors-api.ts            fetchAdvisors() → GET /v1/advisors
  model/catalog-store.ts         module-level store (subscribe/load/reset/…)
  model/use-advisor-catalog.ts   useAdvisorCatalog() / useAdvisor(id)
  model/use-advisor-catalog-sync.ts   binds the store to the signed-in user
  model/types.ts                 re-exports the contract shape
  lib/rating.ts                  ratingFromTenths (49 → 4.9)
```

Deleted: `config/advisors.ts` (six retired personas) and `model/get-advisor.ts`.

### Why a module store and not a provider

Two consumers cannot be inside a React tree. The FCM **background handler**
resolves a persona name with no tree around it, and `ChatProvider`'s
`syncAllThreads` has to stay a stable callback or the socket effect tears the
connection down every time the catalog changes. A module-level store with
`useSyncExternalStore` on top serves both; `useAdvisorCatalogSync()` is called
once in `app/index.tsx` (loads on sign-in, `reset()` on sign-out).

### Three decisions worth keeping

1. **`parse`, not `safeParse`** in `advisors-api`. BFF TECH-DEBT #11 is exactly
   the trap where a stricter server-side `AdvisorId` meets the package's looser
   one and a `safeParse` turns it into an empty catalog nobody can diagnose. A
   drifted response now fails loudly into a retryable error state.
2. **`load()` resolves, never rejects.** Every caller fires and forgets, so a
   rejection would be nobody's to handle; `status` carries the failure.
3. **A `generation` counter.** A fetch started before sign-out cannot land after
   it — otherwise the previous identity's catalog reappears post-`reset`.

`isKnown(id)` answers `true` while the catalog is unloaded: an unloaded catalog
cannot disprove an id, and rejecting there would silently swallow a message sent
in the seconds before it lands (`sendMessage` / `startThread` guards).

## Presence is no longer an advisor field

The contract has no `online` — liveness only ever arrives over the WS
`presence.update` event (AURAT-0009), and a flag baked into a catalog response
is stale the moment it is sent. So it is no longer smuggled into the object;
six components (`AdvisorRow`, `ChatListRow`, `ChatThreadHeader`, `AdvisorHero`,
`TopAdvisorRow`, `ContinueChatCard`) take an explicit `online` prop, and the
screen hooks read `presence[advisorId] === true`.

**Consequence to expect on device:** presence is still inbox-wide in v1, so all
personas share one state, and nothing is online until the socket says so — the
"Online" segment is empty on a cold start. That is honest, not a bug.

## Field migration

| was | now |
|---|---|
| `price` (float USD) | `priceMinorPerMinute` (int cents, via `formatUsdMinor`) |
| `rating` (float) | `ratingTenths` (int tenths, via `ratingFromTenths`) |
| `reviews` | `reviewsCount` |
| `cat: 'Love'…` | `category: 'LOVE' \| 'TAROT' \| 'PSYCHIC'` |
| `tint` | `avatarUrl` |
| `online` | — (socket only) |

`shared/ui/Avatar` learned a `uri` prop: the monogram disc stays underneath and
shows through while the image loads or if it never arrives. No `overflow:
hidden` on the disc — the portrait rounds itself, and clipping would eat the
presence dot that sits on the circle's edge by design.

`Dreams` is gone from `CATEGORY_FILTERS`; a `CATEGORY_LABELS` map keeps the
design's casing over the uppercase wire values.

## Fallout fixed on the way

- **`entities/session` seed bookings** named four retired advisors, so the
  Sessions tab would have rendered empty. Re-pointed at real ids.
- **Push notifications** used to drop a ping for an unresolvable persona. A
  background ping now arrives in a fresh JS context with an empty catalog, so
  it `ensureLoaded()`s first; if that fetch fails the notification still goes
  out under a neutral `"Your advisor"` title. A missed notification is worse
  than an unnamed one, and the tap still lands in the right thread.
- **Blank-screen trap.** `AdvisorProfileScreen` and `ChatThreadScreen` render
  nothing when the persona is unresolved — previously only a stale deep link,
  now also the normal cold-start state. Both keep a back button in that branch;
  a notification tap opens the thread before the catalog has arrived.

## Tests — 34 suites / 142 tests (was 33 / 140)

New: `catalog-store` (dedupe, error status, reset-mid-flight, `isKnown`),
`advisors-api` (contract drift rejected), `AdvisorHero` (both presence pills —
the only remaining cover for the online branch, since screens can no longer
seed presence).

Screen tests seed the catalog through the real path — mocked `bffRequest` plus
the actual zod parse — via `src/test-support/` (`makeAdvisor`,
`seedAdvisorCatalog`). That folder is deliberately not an FSD layer: nothing in
the app imports it, so it never reaches a bundle.

`AdvisorsScreen` gained coverage for the failed-load + retry path and for the
category set (asserting `Dreams` is absent).

## Verified in slave

tsc ✓ · eslint ✓ · jest 34 suites / 142 tests ✓

## Not done here

Device pass (manor): photos actually resolving from S3, presence over a live
socket, a push tap on a cold start. Merge gate not crossed — awaiting owner.
