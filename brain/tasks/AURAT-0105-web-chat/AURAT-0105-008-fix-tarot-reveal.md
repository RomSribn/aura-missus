# AURAT-0105-008 — Fix: tarot reveal as in the app

Date: 2026-10-20

Owner, on review: the tarot spread must open as in the app — option 1 of the three offered
(web-handoff reveal kept / mixed / as the app). «Дизайн оставляй наш, только свёрнутый вариант
сделай как в приложении и открытие»:

- keep the web look of the fan (plum card 560, handoff geometry, hover lift, keyboard);
- the reveal sequence as in the app (`features/tarot-spread`: captions, timings, card name while
  turning, failure line);
- the collapsed result as in the app (`SpreadResult`: small card face, «You chose», name, keywords)
  with the thread divider «You chose {name}»;
- tapping the result opens the card full size (the app's `SpreadCardViewer`) — on the web through
  the shared `Sheet`.

Strings — English + 23 languages in the same step. Next: execute (009).
