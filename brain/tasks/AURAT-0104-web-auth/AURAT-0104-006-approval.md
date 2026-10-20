# AURAT-0104-006 — Approval

Date: 2026-10-20
Owner answered the four decisions of spec `005` (no edits to the rest). Answers:
1. «Skip for now» — none, as the app (`AURAT-0062`): a name is required; × / Esc / Back close the
   dialog (the person is signed in) without resuming; the next gate reopens the name step.
   `AURAF-0020-003` loses «или пропускает».
2. Get started — not rendered until the Home task; a guest sees only Log in.
3. Resume intent — **sessionStorage** (not the recommended dialog params): the intent and the code
   step (`verificationId`, E.164, sent-at) survive a reload for 15 min; confirmed with
   `PhoneAuthProvider.credential` + `signInWithCredential`. Spec §4 updated.
4. Sign-out — temporary `/me`: name or «Add your name» → name step, phone read-only, Log out.
   Spec §5а added.

Execution.
