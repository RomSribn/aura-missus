# AURAT-0105-009 — Execute (fix `008`: tarot reveal as in the app)

Date: 2026-10-20
Replaces §7 «Итог» of the spec `005` (the web handoff's big turned card); the fan's look stays.

## Done

- `features/tarot-pick/model/use-tarot-pick.ts` — port of the app's
  `features/tarot-spread/model/use-spread.ts` (AURAF-0012, AURAT-0051): `open{retry}` / `chosen` /
  `turning` / `done`; the card steps out at once, turns at 560 ms (or when a late answer comes),
  resolves at 1220 ms; the pick is recorded in the thread cache as soon as the server answers; the
  running reveal outranks the record; failure → the fan comes back. Web differences in the header:
  thread cache instead of `spreadStore`, pointer / keyboard instead of a drag, reduced motion →
  closed at once, the `tarot-card` dialog instead of the app's modal.
- `config/spread.ts` — the app's `FLIP_AT_MS` / `RESOLVE_AT_MS`; tokens `--dur-settle` (520),
  `--dur-fade` (380), `--ease-settle`, `--dur-flip` (600) — the app's move / fade / flip
  (`--dur-fan` removed). The other cards now recede (`scale(.9)`) and fade, as in the app.
- Copy as the app: title «Turning it over…» while chosen / turning, line «I chose this card.», then
  the card's name in gold while it turns.
- Closed result as the app's `SpreadResult`: plum card with a 44 px card face, «You chose», name,
  keywords; the divider «You chose {card}» under it (`ThreadLine`, new in `entities/message` — the
  pill `SystemLine` and `DayDivider` now share).
- Tap on the result → dialog `tarot-card` (new `DialogKind`, registered in `app/config/dialogs.ts`):
  `Sheet` with the card's name, keywords and the card image full size (the app's
  `SpreadCardViewer`).
- Strings `tarot-pick`: + `turning`, `chosen`, `resultEyebrow`, `open`; − `revealing`, `yourCard`,
  `willRead` — English + 23 languages.

## Checks

typecheck ✓ · lint (eslint + steiger) ✓ · tests 48 files / 719 ✓ (tarot picker: 7 — closed card +
divider, opening full size, the 560 / 1220 timeline, failure and retry, reduced motion, arrows, the
dialog) · build ✓ · prettier ✓.

Next: owner review in the IDE.
