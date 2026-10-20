# AURAT-0105-003 — Understand

Date: 2026-10-20

A signed-in person opens `/chats` and sees the same conversations as in the app, opens a thread
`/chats/:advisorId` and writes to the advisor in real time: history with paging back, optimistic
send with retry, incoming messages / deletions / presence over the one WebSocket, catch-up over
REST (the web has no FCM). Inside the thread the tarot picker (a message with `spread`) and the
session invite card (a message with `sessionInvite`) work as in the app; the booking CTAs lead
to the profile deep link `?book=1` until the booking task (row 006). BFF unchanged; the
handoff's extras that the data does not support (unread badge, typing, search, …) are decided
in the spec, with options and a recommendation.

Next: context (004).
