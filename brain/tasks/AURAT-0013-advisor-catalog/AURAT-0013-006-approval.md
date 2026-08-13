# AURAT-0013-006 — Approval

Date: 2026-08-13
Status: **approved**

## What the user changed during review

**One remark, and it was an unblock rather than an objection:** the owner opened
the bucket for public read and supplied a live example URL. Folded into the spec:

```
ADVISOR_ASSETS_BASE_URL=https://amzn-s3-aura.s3.eu-north-1.amazonaws.com
avatarKey = "avatar/<slug>.<ext>"    ← the real S3 key
```

Split at the bucket boundary rather than after `/avatar` so later asset kinds get
their own prefix without a second env var. Verified live before writing it down:
all eight objects return 206 with correct `image/png` / `image/jpeg`, and
`alisher.jpeg` / `labsang.jpeg` byte-match the local files — the bucket carries
the **swapped** portraits, so Alisher has the river/chapan photo as intended.
`eu-north-1` is Stockholm, consistent with `AURAD-0005`'s EU rule.

Noted for the record: the bucket is world-readable. Correct for avatars (no
signing needed app-side), but it constrains what may be stored there later.

## D5 resolved — rating/reviews ARE modelled

The one decision left open. I had told the user these would stay out of the
schema, then found `Stars` rendering them on three screens (`StatsCard`,
`AdvisorRow`, `TopAdvisorRow`) and asked to reverse myself.

> **User: "храним"**

So `ratingTenths` (integer tenths, 49 = 4.9) and `reviewsCount` are columns.
Values seeded by me at 4.6–4.9, owner-editable via the seed. A real reviews
system remains out of scope — this is a display figure, not an aggregate.

All other decisions (D1–D4, D6, D7) stand as written in 005.

## Next

Step 007 — execute.
