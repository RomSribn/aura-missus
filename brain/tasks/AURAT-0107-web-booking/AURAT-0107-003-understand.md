# AURAT-0107-003 — Understand

Date: 2026-10-20

A signed-in person books a session with an advisor (duration, day, time) from the profile, the
chat or Quick book and pays from the wallet balance; "Booked" shows only after the BFF confirms
the session. The payment step is `features/pay` built around a payment-method port: `balance`
live, `card` / `wallet` on a fake provider behind `VITE_PSP_ENABLED` with the return route and
"Still confirming…"; with the flag off a short balance says "top up in the Aura app". BFF
unchanged.

Owner's brief for the spec (2026-10-20): the "decide in spec" items of the stub and the entry
points — inline on the profile, `/checkout`, Quick book in the chat, balance and Top up in the
top nav without a PSP — each with options and a recommendation. If the task is too large,
propose splitting rows 006 and 007 (the second ID is minted in `aura-app-manor`). BFF gaps go
to the owner for `aura-app-manor`.

Next: context (004).
