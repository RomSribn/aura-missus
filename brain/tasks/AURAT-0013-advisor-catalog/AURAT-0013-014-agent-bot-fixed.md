# AURAT-0013-014 — The agent-bot leg, actually fixed

Date: 2026-08-13
Ran from: manor. Supersedes the "not fixed here" note at the end of step 013.

Step 013 found the agent bot pointing at port 8080 and stopped there. The owner
asked for it to be fixed. **The port was only half of it** — and the half that was
visible.

## Correction to step 013

Step 013 implied the wrong port was *the* cause. It was not. After PATCHing
`outgoing_url` from `:8080` to `:3000/webhooks/chatwoot`, a freshly created
conversation **still** got Chatwoot's *"Диалог был открыт системой из-за ошибки
бота агента"*. The fix was necessary and insufficient.

## The second cause: the bot signs with its own secret

Pairing each `/webhooks/chatwoot` request with its response showed the traffic was
**mixed**: `204`s and `401`s interleaved. Two legs, one accepted, one rejected.

Comparing what Chatwoot holds against what the service is configured with:

| | |
|---|---|
| `CHATWOOT_WEBHOOK_SECRET` == inbox `secret` | **true** — the inbox leg verifies, hence the 204s |
| `CHATWOOT_WEBHOOK_SECRET` == bot `secret` | **false** |
| inbox `secret` == bot `secret` | **false** — they are genuinely different values |

The agent bot carries its own `secret`, and `CHATWOOT_WEBHOOK_SECRET_SECONDARY`
was **not set** in the manor `.env`. Every bot delivery failed signature
verification with 401, and Chatwoot reads a non-2xx from a bot as a bot error and
opens the conversation itself.

This is the same variable the step-011 env diff listed as missing and I classified
as merely optional. It **is** `.optional()` in `env.schema.ts` — correctly, since
an inbox may have no bot — but **the moment a bot is attached it becomes
mandatory**, and nothing at boot says so. The failure surfaces only as 401s in a
log nobody reads and a Russian activity line inside Chatwoot. Worth considering a
boot-time warning, or at least a line in the setup doc.

## After both fixes

Set `CHATWOOT_WEBHOOK_SECRET_SECONDARY` to the bot's secret, restarted, created a
fresh conversation:

- **No bot-error activity line.** The handoff succeeded.
- **7 of 7 webhook hits returned 204.** No 401 remains.
- **Each Chatwoot message id has exactly one row in our store.** The inbox webhook
  and the bot webhook both delivered the same messages, and ingestion deduped
  them.

That last point matters beyond this fix: hard rule 6 ("idempotency at the seams —
repeat webhook / retry ⇒ no duplicate") had never been exercised against *real*
double delivery, because the bot leg was dead for as long as it has existed here.
It holds.

## What this says about the environment

`AURAS-0001-dev-chatwoot-setup.md` is stale in two ways, not one: it records
`:8080` for both the inbox and the bot (the inbox half was already caught and
fixed in AURAT-0005-014), and it never mentions that attaching a bot requires
putting the bot's own secret into `CHATWOOT_WEBHOOK_SECRET_SECONDARY`. Anyone
following that document builds the same half-dead delivery path. It should be
corrected — a separate, small piece of work.

## Still open from step 013

The retired-advisor conversations still exist **inside Chatwoot** (the step-011
cleanup was BFF-side only). Untouched — that remains a deliberate decision for the
owner.
