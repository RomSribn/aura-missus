# AURAT-0004-001 — Check

Date: 2026-07-10

Implements the backend foundation of `AURAF-0007` (item 001, BE half). Obeys
`AURAD-0004` (stack: Node+TS / NestJS, Postgres, Redis/BullMQ), `AURAD-0005`
(self-host EU, one Chatwoot account, one `Channel::Api` inbox per env,
service-User token), `AURAD-0003` (one conversation per (user, advisor); dedupe
is BFF-side).

Already in place: nothing — greenfield BFF repo. App side has Firebase phone-OTP
auth (verifiable ID token) and no REST client (`shared/api` is Firebase-only).

## Scope

- New **NestJS** (TS) service on the ratified stack; Postgres + Redis/BullMQ
  wired.
- **Firebase Admin** ID-token auth guard — verify on every request; map token →
  our user (Firebase UID).
- **Chatwoot Application-API client** using a dedicated **service-User** token +
  per-env `Channel::Api` inbox config (identifier / secret / hmac from env
  secrets, never on device).
- **Contact upsert** (`identifier = Firebase UID`, `phone_number = E.164`) and
  **conversation get-or-create** per (user, advisor), tagged
  `custom_attributes.advisor_id`; BFF owns the `(user,advisor) → conversation`
  map (inbox `lock_to_single_conversation` OFF).
- Health / readiness; all Chatwoot secrets server-side only.

## Acceptance

An authenticated app request ensures a Chatwoot contact + a conversation for a
given advisor and returns our conversation id; **idempotent** (repeat calls
reuse the same contact/conversation).

## Dependencies

Needs a dev Chatwoot instance + `Channel::Api` inbox + service User (the
`AURAD-0005` ops setup). Blocks AURAT-0005 / 0006 / 0007.

Next: AURAT-0005 (messaging + delivery).
