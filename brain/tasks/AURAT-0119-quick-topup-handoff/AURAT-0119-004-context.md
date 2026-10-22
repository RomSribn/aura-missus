# AURAT-0119-004 — Context

Date: 2026-10-22

Код (slave-1, `develop` @ `caf8736`):
- `shared/ui/bottom-sheet/BottomSheet.tsx` — `onClosed`: iOS — после нативного `onDismiss`,
  Android — по окончании slide-out (200 мс). Slide-in 320 мс, затемнение с прогрессом.
- Два перехода «шторка в треде → Top Up», оба ждут `onClosed` на всех платформах:
  - Quick book: `screens/chat-thread/model/use-quick-book.ts` — `onTopUp` →
    `setLeavingFor('topUp')` → `closed` → `navigate(PROFILE › PROFILE_ROOT { sheet })`.
  - Extend: `features/paid-session/model/use-paid-session.ts` — `goTopUp` →
    `leavingForTopUp` → `sheetClosed` → `onTopUp` (`use-chat-thread.ts` `goTopUp`).
- Review (`use-book-review.ts`) — экран стека, ждать нечего, переход плавный.

Находка против варианта (а) «переключить вкладку сразу, Top Up — после `onClosed`»:
RN 0.85 Android `ReactModalHostView.onDetachedFromWindow` → `onDropInstance` → `dismiss()` —
модалка закрывается **мгновенно**, когда её экран отцепляется от окна; react-native-screens
отцепляет неактивную вкладку. То есть при (а) quick sheet не уедет над Profile, а исчезнет, а на
iOS (а) трогает путь закрытия модалки `AURAT-0020`, который здесь не проверить. Пользы от (а)
нет ни на одной платформе.
