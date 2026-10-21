# AURAT-0089-005 — Спека

Дата: 2026-10-21 · Тип: задача (без фичи) · Статус: **draft, ждёт одобрения**

## Что делаем (slave-0)

1. **R8 в release** (`android/app/build.gradle`):
   - `enableProguardInReleaseBuilds = true`;
   - `proguard-android.txt` → `proguard-android-optimize.txt` (старый файл
     несёт `-dontoptimize` — колонка Optimization у Play осталась бы пустой);
   - `shrinkResources` **не включаем** (см. решение Б).
2. **`proguard-rules.pro`** — только то, чего нет в consumer-правилах библиотек:
   - ядро Nitro: `-keep class com.margelo.nitro.** { *; }` (C++ находит классы через
     JNI по имени; ядро своих правил не несёт);
   - то, что потребует сам R8: прогон `minifyReleaseWithR8` в слоте, недостающее
     из `missing_rules.txt` (`-dontwarn` на необязательные зависимости) — каждое
     правило с комментарием, зачем;
   - `-keepattributes SourceFile,LineNumberTable` + `-renamesourcefileattribute SourceFile`
     — читаемые номера строк в стеках Play.
3. **Edge-to-edge, наша часть**: убрать `backgroundColor` у `StatusBar` в
   `OnboardingSliderScreen` (на Android 15+ он и так игнорируется; фон там paper
   на весь экран). Это наш единственный вызов `setStatusBarColor`.
4. **Проверки в слоте**: `tsc`, `eslint`, `jest`; `./gradlew :app:minifyReleaseWithR8`
   (без подписи и без стека) — R8 проходит без ошибок; по `usage.txt`/`seeds.txt`
   убедиться, что классы RN-модулей, Nitro/IAP, Firebase, Notifee, Meta на месте.

## В маноре после мёржа (не в слоте)
- `bundleRelease` → в AAB есть `BUNDLE-METADATA/.../proguard.map` (mapping уходит в Play сам).
- Release на устройстве по полному кругу из `001`: вход по телефону, чат и вложения
  (картинка/файл/голос/видео), пуши (Notifee/FCM), бронирование, покупка через Play,
  события Meta в Test events, удаление аккаунта, formSheet-шиты (`react-native-screens`).
- versionCode → 30 и загрузка; в App bundle explorer: DEX optimization не Low.

## Edge-to-edge — честный ожидаемый итог
Рекомендация Play **полностью не уйдёт**: `StatusBarModule` и `WindowUtilKt` живут в
`react-android` и регистрируются всегда; Material `BottomSheetDialog`/`EdgeToEdgeUtils`
нужны `react-native-screens` для formSheet. Ожидаемо уйдёт `sidesheet.SheetDialog`
(R8 вырежет неиспользуемое). Это «Recommended», не issue, срока нет. Записываем как
«источник вне нашего контроля», следим за обновлениями RN / screens.

## Решения владельца
- **А. edgeToEdgeEnabled.** Рекомендую **оставить false** в этой задаче: на пометку Play
  не влияет, на Android 15+ edge-to-edge уже принудительный, а включение меняет вид
  на Android ≤14 — отдельная задача с проверкой экранов.
- **Б. shrinkResources.** Рекомендую **не включать**: метрики Play про DEX, а шринкер
  ресурсов может выкинуть картинки из JS (RN ищет их по имени через `getIdentifier`).
  Выигрыш — сотни КБ; можно отдельной задачей с `keep.xml`.
- **В. AGP 9** — не трогаем (RN 0.85 сидит на AGP 8.12; R8 работает и так).

## Риск
R8 ломает только то, что ищется по имени в рантайме — проявится лишь на устройстве.
Поэтому проверка release-сборки в маноре обязательна до загрузки в Play.
