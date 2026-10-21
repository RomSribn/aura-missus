# AURAT-0089-004 — Контекст

Дата: 2026-10-21

## Сборка
- AGP **8.12.0** (задаёт RN 0.85.3, `libs.versions.toml`), Gradle 9.3.1, Kotlin 2.1.20.
  AGP 9 — вне досягаемости без подъёма RN; R8 есть и в AGP 8 (full mode по умолчанию).
- `release`: `minifyEnabled enableProguardInReleaseBuilds` (= false) и
  `getDefaultProguardFile("proguard-android.txt")` — **этот файл содержит
  `-dontoptimize`**: даже с включённым R8 колонка Optimization осталась бы пустой.
  Нужен `proguard-android-optimize.txt` (AGP 9 старый файл вообще запрещает).
- `mapping.txt`: AGP кладёт его в AAB (`BUNDLE-METADATA/com.android.tools.build.obfuscation/proguard.map`),
  Play подхватывает сам — отдельной загрузки не нужно. Проверить по AAB в маноре.

## Keep-правила библиотек (consumerProguardFiles)
- Есть: `react-android` (RN: `@DoNotStrip`, `@ReactModule`, `@ReactProp`…),
  `@notifee/react-native`, `react-native-iap` (`com.margelo.nitro.iap.**`), `react-native-svg`.
  Firebase, Meta SDK, media3 (video), AndroidX — правила в своих AAR.
- Нет своих: `react-native-nitro-modules` (ядро; классы помечены `@Keep`/`@DoNotStrip`,
  но вызываются из C++ через JNI по имени — iap сам предлагает
  `-keep class com.margelo.nitro.modules.**`), `react-native-screens`,
  `gesture-handler`, `safe-area-context`, `fbsdk-next`, `@react-native-firebase/*`,
  `image-picker`, `documents/picker`, `fs`, `blob-util`, `paste-input`,
  `inappbrowser-reborn`, `haptic-feedback`, `video`. Большинство — обычные RN-модули
  (покрыты правилами RN); риск — JNI/рефлексия: nitro, screens (Fabric-компоненты),
  gesture-handler (рефлексия по RN-вью).
- Ресурсы (`shrinkResources`): картинки из JS RN упаковывает в `drawable-*` и ищет
  через `getIdentifier` по имени, которое живёт только в JS-бандле — шринкер ресурсов
  может их выкинуть. Метрики Play касаются только DEX.

## Edge-to-edge
- Наш единственный вызов: `OnboardingSliderScreen.tsx:44`
  `<StatusBar barStyle="dark-content" backgroundColor={theme.colors.paper} />` →
  `StatusBarModule.setColor` → `setStatusBarColor` (на Android 15+ игнорируется).
- Остальное — внутри `react-android` (`StatusBarModule`, `WindowUtilKt` — модуль
  регистрируется всегда, R8 его не уберёт) и Material 1.13.0, который тянет
  `react-native-screens` для formSheet (`BottomSheetDialogScreen` → `BottomSheetDialog`
  → `EdgeToEdgeUtils`). `sidesheet.SheetDialog` никто не использует — R8 должен его вырезать.
- `edgeToEdgeEnabled=false`: на Android 15+ (target 36) edge-to-edge всё равно
  принудительный; флаг влияет только на ≤14 и на пометку Play не влияет
  (`WindowUtilKt.enableEdgeToEdge` в DEX есть в любом случае).
