# AURAT-0193-004 — approved

Дата: 2026-11-07 · Status: `done`

Владелец: «Закрываем обе» (0188 и 0193).

- `develop`: коммит `ccdc04f`, мёрж `65352c4`. `MainActivity` ставит `RNScreensFragmentFactory` до `super.onCreate`;
  охранный тест `src/app/navigation/__tests__/main-activity-fragments.test.ts`.
- Проверено (`003`): AVD API 36 — смена шрифта (в том числе с открытой клавиатурой), убийство процесса в фоне — без падения;
  A50 Android 11 — шрифт 1.1 → 1.15 → 1.1 и убийство процесса — без падения (исходный шрифт возвращён).
- Pixel 10 — со сборкой релиза.
