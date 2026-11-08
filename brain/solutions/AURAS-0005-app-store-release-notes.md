# AURAS-0005 — Release notes for every store build

Date: 2026-11-08
Status: active

## Problem
Builds went to Play Console without one place recording what is in each one, what users read in "What's new", and
in which languages. The owner asked for this on 2026-11-08: «нужны релиз notes с каждой такой сборкой, сохрани это в
скиллах, пусть где-то в misuse пишется».

## Solution
- **Every store build gets release notes.** A store build is an AAB/APK for Play Console in any track, or an iOS build
  for TestFlight / App Store. A staging APK for testers gets only a short "what to check".
- **Each build is its own release task.** The folder is `tasks/AURAT-NNNN-<platform>-release-<x-y-z>/`.
  - Step `001-release-notes` holds the notes.
  - Later steps hold the internal-testing check and the production rollout.
  - The task ends with `approved` once production is confirmed.
- **This file keeps the index below.** Add one row per build, newest first.
- **What the notes contain.** Write them in this order:
  - version and track;
  - commit, build command, artifact and its SHA-256;
  - server dependency and order;
  - what is in the build (tasks);
  - "What's new" in en-US and in all 21 Play listing languages, as one block to paste;
  - what to check before production.
- **Rules for "What's new":**
  - at most 500 characters per language;
  - the app's exact UI labels and the glossary;
  - register and typography per `aura-build-rules.md` → «Translations»;
  - promise only what the server will have switched on by the time users get the build.
- **The procedure is the `aura-release` skill** in `<workspace>/.claude/skills/`: version, build, artifact, notes.

## Current Behavior

| Build | Track | Notes | Status |
|---|---|---|---|
| Android 1.2.0 (38) | internal → production | `AURAT-0201-001-release-notes` | built 2026-11-08, waiting for the prod BFF (PR #10) and the policy |

Earlier builds (up to 1.1.0, 37) had notes in their own task steps, en-US only: for example `AURAT-0152-009`, `0182`.

## Next
- iOS: when iOS releases start (`AURAT-0190`), add the App Store "What's New" and the TestFlight "What to Test" in
  the same way.
