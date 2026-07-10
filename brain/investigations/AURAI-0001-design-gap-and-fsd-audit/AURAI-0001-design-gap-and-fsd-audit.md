# AURAI-0001 — Design gap map + first FSD audit of merged code

Date: 2026-07-03
Method: two parallel agents from manor — (a) design handoff vs `src/` diff,
(b) file-by-file FSD/cleanliness audit (all 60 non-test files read).
Basis for: the 2026-07-03 "Hard rules" section added to
`.claude/aura-build-rules.md`, and the AURAT-0002 debt-cleanup task (when
opened).

## Screen map (design → implementation)

19 numbered screens in `.claude/design_handoff_aura/screens/`.

- **Implemented (12):** 01 Splash, 02–04 Onboarding (+extra onboarding-complete
  screen not in design), 05 Phone auth, 06 SMS code, 10 Chat thread, 11 Chats
  list, 14 Profile, 15–17 Profile sheets (Language / Top Up / Edit).
- **Stubs (4):** 07 Home, 08 Advisors, 12/13 Sessions — 7-line
  `TabPlaceholder` each.
- **Missing (3):** 09 Advisor profile (no dir, no route; unused
  `SCREENS.PSYCHIC_PROFILE` constant exists), 18/19 Daily-Tarot sheets.

Dangling edges: `use-chat-thread.ts` `openBooking` parks "Book now" on the
Advisors stub (comment says profile doesn't exist yet); "Start free chat"
exists only in a `features/chat` comment — the ChatProvider seed-with-greeting
function was scaffolded specifically for it.

## Recommended order (dependency-driven)

1. **09 Advisor profile + AdvisorsStackNavigator** — unblocks Book now и
   Start free chat; creates Stars/Pill/Avatar-ring components needed by 07–08.
   Full layout spec captured in the workflow output (hero, stats card 4.9/198/
   $1.99, About, Specialties pills, 2 review cards, sticky coral CTA).
   Review quotes are NOT in `entities/advisor` — screen-local `config/` or
   entity seed extension.
2. **08 Advisors list** — needs stack + Stars from (1); search, segments,
   chips, rows per README §6.
3. **07 Home** (+ 18/19 tarot sheets as sub-task) — consumes advisor rows from
   (2), Continue-chat from ChatProvider, BottomSheet exists.
4. 12/13 Sessions — lowest connectivity, last.

## FSD audit — violations (fix = AURAT-0002 candidate)

1. **[systemic] screens → app imports.** All 7 screen model hooks import
   `SCREENS`/nav types from `app/navigation/*` — layer inversion. Fix: move
   contract to `shared/config/navigation.ts`.
2. Deep imports bypassing public APIs: `shared/ui/keypad`, `resend-timer` not
   exported from `shared/ui/index.ts`; ~10 files import
   `shared/config/theme` directly. No `@/*` aliases wired (tsconfig/babel).
3. `features/chat/index.ts` exports lib-helper `formatMessageTime` (no
   external consumers) — against the doc's own DON'T.
4. Logic misplacement: splash auto-advance `setTimeout` in ui; phone
   formatting re-implemented in phone-auth model (exists in profile lib);
   OTP_LENGTH defined in 3 places (one says "4-digit", truth is 6);
   `getAdvisor` is data access sitting in entity lib.
5. Theme bypasses: `fontFamily: 'BricolageGrotesque'` hardcoded ×6 (falls
   back to System — font not bundled); raw rgba duplicating `theme.colors.line`;
   hand-rolled card shadow ×2 despite `theme.shadows.sm`; duplicated theme
   aliases invite drift.
6. Dead code: `use-onboarding-animation.ts` (never imported), unreachable
   `onboarding-complete` screen with console.log CTA, `shared/lib/styles.ts`
   (0 consumers), unused slider callbacks, 7 speculative route constants,
   `isPhoneAuthSupported` never called.
7. Perf/hygiene: chat FlatList rows not memoized (every `draft` keystroke
   re-renders all visible bubbles) while onboarding-slider shows the correct
   pattern; back-button circle duplicated byte-identical ×2 (+ '←' glyph
   variants); screen-title style ×5; pulsing orb ×2; **PII in console.log**
   (raw phone in auth.service.ts:25,29; uid in use-verify-otp.ts:43).

## Good patterns (codified, keep enforcing)

Headless `model/use-<screen>.ts` returning full view-state; pure ui;
config-driven rendering (menu rows, slides, seeds) honestly marked as
prototype stand-ins; ChatProvider hygiene (functional setState, timer cleanup,
memoized context, test injection point); two-tone coral/teal discipline with
in-code comments; a11y roles/labels on every pressable; colocated tests.

## Outcome

- `.claude/aura-build-rules.md` → new "Hard rules — enforced at review"
  section (5 rules, each traceable to a violation above).
- `.claude/skills/react-native-app/SKILL.md` → rewritten Aura-specific.
- Debt items 1–7 = scope for AURAT-0002 (single mechanical cleanup pass),
  best run before or right after screen 09 to avoid conflicts in
  `use-chat-thread.ts` / navigation.
