# AURAT-0006-007 — Merge

Date: 2026-07-11

- Merge gate passed (owner: «Да — wts-finish + push»).
- `wts-finish slave-1` → develop merge commit `413787d`
  (`Merge feature/AURAT-0006-app-real-chat-client`); slave-0 refreshed.
- The script's backup push failed (aura-app origin is HTTPS, no stored
  creds); pushed explicitly over ssh: `635fda6..413787d develop→develop` —
  **origin/develop is now fully up to date**, including the previously
  stranded AURAF-0001..0006 / AURAT-0002 / AURAT-0003 merges. (Consider
  re-pointing the aura-app origin to the ssh URL like the other repos.)
- Brain docs (002–006 + AURAT-0009 mint) committed and pushed to
  `aura-missus` `master` (`80c2c0a`).
- `wts-release slave-1` returns the slot to idle after this doc.

## Open before "approved"

Manor-side device e2e (the 001-check acceptance): run the stack + app
(`pod install` first; Metro `--reset-cache` not needed — no babel change),
send → chatter reply live (WS) and as push (background; iOS needs the APNs
key in the Firebase console + push entitlement in Xcode), history across
kill/reinstall. Presence/typing stay seed/silent until AURAT-0009.
