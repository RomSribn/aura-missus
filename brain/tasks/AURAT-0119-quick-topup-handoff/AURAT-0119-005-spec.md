# AURAT-0119-005 — Spec

Date: 2026-10-22
Тип: task (под `AURAF-0019`). Status: approved 2026-10-22 (см. 006).

## Что делаем
1. `shared` — константа `MODALS_PRESENT_ONE_AT_A_TIME` (= iOS) рядом с `isIOS`, экспорт через
   `@/shared`, с объяснением `AURAT-0020`: только там вторая модалка обязана ждать закрытия первой.
   `BottomSheet` берёт её же вместо собственной проверки `isIOS` для того же правила.
2. Quick book (`use-quick-book.ts`): на Android `onTopUp` закрывает шторку и **сразу** уводит в
   Profile с `sheet: 'topup'`; на iOS — как сейчас, через `closed`.
3. Extend (`use-paid-session.ts`): то же для `goTopUp` — на Android `onTopUp` сразу, на iOS — через
   `sheetClosed`.
4. Вариант (а) (вкладка до закрытия) **не делаем** — см. `004`: на Android модалка отцепленного
   экрана закрывается мгновенно, на iOS это путь `AURAT-0020`.

Ожидаемо на Android: тред с шторкой → сразу Profile, шторка Top Up выезжает (как с Review). Quick
sheet при смене вкладки исчезает мгновенно (так RN закрывает модалку отцепленного экрана), а не
уезжает — это и есть «одно движение».

## Тесты (unit)
- `use-quick-book` / `use-paid-session`: Android — навигация в Top Up без ожидания `closed`;
  iOS — только после `closed` (мок `Platform.OS` / константы).

## Проверка вживую
Манор после merge: staging-APK на SM-A505FN — Quick book → Top Up и Extend → Top Up.
