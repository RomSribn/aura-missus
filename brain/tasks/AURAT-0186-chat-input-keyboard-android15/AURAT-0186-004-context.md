# AURAT-0186-004 — context

Код — `develop` @ `1bf1943`, RN 0.85.3 и safe-area-context 5.8.0 в `node_modules`.

## Причина (подтверждена)

1. `android/build.gradle:6` — `targetSdkVersion = 36`. На Android 15 (API 35) при таргете ≥ 35 окно
   принудительно edge-to-edge; на Android 16+ при таргете 36 отказ (`windowOptOutEdgeToEdgeEnforcement`)
   отключён совсем (Android 16 behavior changes). Pixel 10 / Android 17 — отказаться нельзя.
2. `android/gradle.properties:44` `edgeToEdgeEnabled=false` — только флаг RN: при нём RN сам не вызывает
   `enableEdgeToEdge` (`ReactActivityDelegate.java:141`), систему он не переубеждает.
3. При edge-to-edge окно под клавиатуру не сжимается: `adjustResize` (`AndroidManifest.xml:86`) лишь
   отдаёт IME-инсет, а применять его некому. safe-area-context 5.8 считает только
   statusBars | displayCutout | navigationBars | captionBar (`SafeAreaUtils.kt:16-19`), IME в нём нет.
4. `ChatThreadScreen.tsx:189-192` — `KeyboardAvoidingView behavior={ios ? 'padding' : undefined}`: на
   Android KAV ничего не делает (ветка `default` в `KeyboardAvoidingView.js`), поле остаётся под
   клавиатурой. `undefined` на Android — с первого коммита треда (`d3d4ff8`), причины в истории нет:
   расчёт был на `adjustResize`.
5. Подпись на скрине: строка состояния прозрачная, за ней бумажный фон приложения — признак edge-to-edge.

## Чем RN сообщает о клавиатуре (значит, KAV на Android работать будет)

`ReactRootView.checkForKeyboardEvents` (API 30+): `keyboardDidShow` с `screenY` = низ видимой области
окна (= верх клавиатуры) и `height = ime.bottom − systemBars.bottom`; при edge-to-edge событие приходит
так же. `duration` всегда 0 → KAV без анимации: поле встаёт на место, когда клавиатура уже выехала.

Формула KAV `padding`: `frame.y + frame.height − keyboardY`. Если окно сжато (`adjustResize` работает),
она даёт 0 — но на A50 возможна гонка: `keyboardDidShow` приходит раньше `onLayout` нового размера →
на кадр поле подскакивает на высоту клавиатуры и возвращается. Поэтому на Android < 15 менять поведение
не стоит.

## Остальные места с KAV

| Место | Android | Android 15+ |
|---|---|---|
| `screens/chat-thread` | `undefined` | **поле под клавиатурой** (скрин) |
| `shared/ui/bottom-sheet` (`BottomSheet.tsx:626`) | `undefined` | под подозрением: шторка — `Modal`, своё окно-диалог; RN зовёт `setDecorFitsSystemWindows(true)` (`ReactModalHostView.kt:393`), учтёт ли его система при принудительном edge-to-edge — не проверено. Поля: поиск в `CountryPickerSheet`, `BirthDateSheet` |
| phone-auth, verify-otp, create-account, edit-profile, write-review | `'height'` | должны работать: KAV считает по событию, сжатие окна не нужно — проверить в маноре |

## Не в этой задаче (находка)

Иконки строки состояния на скрине белые на бумаге. `StatusBar barStyle="dark-content"` есть только в
онбординге; при его размонтировании стек `StatusBar` откатывается к `default`, а
`StatusBarModule.setStyle` всё, кроме `dark-content`, делает светлыми иконками. На A50 фон полосы —
цвет темы, на Android 15+ — прозрачный. Отдельная задача, если владелец захочет.

## Альтернатива на будущее

`react-native-keyboard-controller` — KAV, который едет вместе с клавиатурой покадрово (Android 11+),
рекомендован README `react-native-edge-to-edge`. Нативная зависимость, пересборка, свой `KeyboardProvider`
(issue #1192 — конфликт с `edgeToEdgeEnabled=false`); совместимость с RN 0.85.3 / Fabric не проверял.
По заметкам мейнтейнеров, в RN 0.86 много правок edge-to-edge — после апгрейда RN имеет смысл
включить `edgeToEdgeEnabled=true` для всех версий Android разом.

---
**Поправка (2026-11-07, по ревью slave-1-ac, `006`):** «событие приходит так же» верно только для открытия.
`keyboardDidHide` шлёт `screenY = visibleViewArea.height()` (`ReactRootView.java:999`), а KAV на Android
пропускает закрытие через ту же формулу (`KeyboardAvoidingView.js:211`) → при edge-to-edge после закрытия
остаётся зазор (строка состояния; на экранах без нижнего края — плюс панель навигации). Пять экранов с
`'height'` не «должны работать» — у них этот дефект уже на develop. Иконки строки состояния: исправление
должно ставить тёмные иконки и полосу «бумага» вместе (корневой `StatusBar` в app или тема), иначе на A50
тёмные иконки окажутся на тёмной полосе.

**Поправка 2 (`010`):** координаты вида для сравнения со `screenY` — `measure().pageY` (от корня, при
edge-to-edge корень на экранном 0), не `measureInWindow` (+`viewportOffset` = −строка состояния, `ReactSurfaceView.kt:48-60`).
