# AURAT-0108-003 — Understand

Date: 2026-10-20

The owner wants the web's payment path ready for a PSP before one is chosen: two more methods of
the `features/pay` port — `card` (provider's hosted page, 3-D Secure) and `wallet` (Apple /
Google Pay) — running against a fake provider and switched off by `VITE_PSP_ENABLED` (off → the
`AURAT-0107` behaviour, byte for byte). The PSP is a **top-up of the shortfall** (whole dollars,
the rest stays on the balance), then the same `POST …/sessions` booking with its key; `/checkout`
becomes the return route from the hosted page; "Still confirming…" polls; every outcome has copy
in 24 languages and a test on the fake. No BFF / contracts change.

The spec must also decide: what the fake does against the real bff-dev (no PSP top-up endpoint
there), and how the flag is turned on for the manor check. BFF / contract gaps go to the owner for
`aura-app-manor`.

Next: context (004).
