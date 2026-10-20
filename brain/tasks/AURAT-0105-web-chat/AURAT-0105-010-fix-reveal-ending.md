# AURAT-0105-010 — Fix: a smoother end of the tarot reveal

Date: 2026-10-20

Owner, on review of `009`: «сделай анимацию плавнее под конец, а то сразу же обрывается анимация и
показывается плашка финальная с сообщением с картой». The turned card was on screen ~60 ms (flip
ends at 1160 ms, the app's resolve at 1220 ms) and then the fan was swapped for the result at once.

Plan: hold the turned card, then fold the fan (fade + collapse) and bring the result and its
divider in softly. A web difference from the app's timeline, recorded in the port header.

Next: execute (011).
