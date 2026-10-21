# AURAT-0089-007 — Выполнено в слоте

Дата: 2026-10-21 · `slave-0`, `feature/AURAT-0089-android-r8-release` @ `892caa7`

## Изменения (`aura-app`)
- `android/app/build.gradle`: `enableProguardInReleaseBuilds = true`;
  `proguard-android.txt` → `proguard-android-optimize.txt`.
- `android/app/proguard-rules.pro`: `-keepattributes SourceFile,LineNumberTable`,
  `-renamesourcefileattribute SourceFile`, `-keep class com.margelo.nitro.** { *; }`.
  Других правил R8 не потребовал (`missing_rules.txt` не возник).
- `OnboardingSliderScreen.tsx`: у `StatusBar` убран `backgroundColor`.

## Проверки в слоте
- `tsc` ✓, `eslint .` ✓, `jest` ✓ 127 suites / 925 tests.
- `AURA_ENV=prod ./gradlew :app:minifyReleaseWithR8 -PreactNativeArchitectures=arm64-v8a`
  — BUILD SUCCESSFUL (6 мин 54 с). Без `AURA_ENV` падает на JS-бандле, не на R8.
  Предупреждения только «Invalid stack map table» в `play-services-auth 21.5.0`
  (байткод самой библиотеки; R8 сохраняет методы, сборку не валит). Следить при
  обновлении AGP/R8: «в следующих версиях метод может считаться недостижимым».
- DEX: **41.1 MB → 8.2 MB** (release, после R8).
- `mapping.txt` создаётся (69 MB) — в AAB пойдёт как `proguard.map`, проверить в маноре.
- По `mapping.txt`/`usage.txt`: все 19 пакетов из `PackageList` на месте;
  RN-модули с `@ReactModule` (Notifee, Firebase auth/messaging, FBSDK AppEvents,
  GestureHandler, ScreenStack) — с исходными именами; Nitro core и `HybridRnIap` —
  исходные имена. `ReactVideoPackage` слит R8 в другой класс — создаётся в коде,
  не по имени, это нормально.

## Edge-to-edge после R8
- **Ушли** из DEX: Material `BottomSheetDialog`, `sidesheet.SheetDialog`,
  `EdgeToEdgeUtils` (formSheet `react-native-screens` в новой архитектуре
  до `BottomSheetDialogScreen` не доходит — R8 вырезал).
- **Остались**: RN `StatusBarModule`, `WindowUtilKt` (`react-android`, модуль
  регистрируется всегда). Вне нашего контроля; рекомендация Play, не issue.

## Дальше — манор после мёржа
1. `npm run aab:prod`-сборка (все 4 ABI), в AAB есть
   `BUNDLE-METADATA/com.android.tools.build.obfuscation/proguard.map`.
2. Release на устройстве по полному кругу (`005`, «В маноре после мёржа»).
3. versionCode 30, загрузка в Play; App bundle explorer: DEX optimization не Low.
