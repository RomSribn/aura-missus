# AURAT-0089-003 — Что хочет владелец

Дата: 2026-10-21

Владелец: «нужно так же разобраться уже с этой проблемой» + скриншоты Play Console
по бандлу `28 (1.0.3)`:

1. **Issue** «DEX code optimization is below our threshold», fix by Feb 2027.
   `28.aab`: DEX optimization Low, Optimization —, Obfuscation 2%, Shrinking —,
   R8 configuration — («Upgrade to AGP version 9.0 and use R8»), DEX 41.1 MB
   (у `22` было 38.7 MB), target 36, minSdk 24, 4 ABI, 16 KB — да.
2. **Recommended** «deprecated APIs or parameters for edge-to-edge»:
   `Window.getStatusBarColor/setStatusBarColor/setNavigationBarColor`,
   `LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES/DEFAULT`. Источники:
   RN `StatusBarModule` (`setColor`, `getTypedExportedConstants`),
   RN `WindowUtilKt` (`enableEdgeToEdge`, `statusBarHide`, `statusBarShow`),
   Material `BottomSheetDialog.onCreate`, `EdgeToEdgeUtils.applyEdgeToEdge`,
   `sidesheet.SheetDialog.onCreate`.

Суть: включить R8 в release так, чтобы issue Play снялся и приложение не сломалось;
по edge-to-edge — убрать то, что наше, и зафиксировать, что остальное в RN/Material.
