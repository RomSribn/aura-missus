# AURAT-0188-005 — spec (draft, ждёт ревью координатора и одобрения владельца)

Тип — задача (без фич-спеки). Основание — `004`. Новых зависимостей нет.

## Итог в одной фразе

Свой маленький нативный модуль `AuraKeyboardFrame` (Android 15+) следит за IME-инсетом окна и шлёт в JS верх
клавиатуры при **каждом** его изменении; `use-keyboard-inset` на Android 15+ берёт отступ только из него (события RN
`keyboardDidShow` / `keyboardDidHide` — лишь запасной путь для сборки без модуля). iOS и Android ≤ 14 не меняются.

## 1. Нативная часть — `android/app/src/main/java/cc/silvermind/aura/`

**Механизм:** `ViewTreeObserver.OnPreDrawListener` на `decorView` окна активности + `decorView.rootWindowInsets`
(платформенные `WindowInsets`, API 30+). Не `OnApplyWindowInsetsListener` и не `WindowInsetsAnimationCompat.Callback`:

- слот `setOnApplyWindowInsetsListener` у decorView уже делят RN `StatusBar.setTranslucent` (ставит **и обнуляет**) и
  react-native-screens (`InsetsObserverProxy`) — наш слушатель там затёрли бы или затёрли бы мы; у
  `setWindowInsetsAnimationCallback` тоже один слот;
- наблюдатели `ViewTreeObserver` складываются и ничего не перехватывают: инсеты по-прежнему доходят до всех, кто их
  слушает; так же устроены RN (`OnGlobalLayoutListener`, `ReactRootView.java:933`) и safe-area-context (`OnPreDraw`);
- `OnPreDraw`, а не `OnGlobalLayout`: смена инсетов всегда планирует проход `ViewRootImpl`, а pre-draw бывает на
  **каждом** проходе, даже без перекладки; проверка — чтение закэшированных `rootWindowInsets` и сравнение двух чисел;
- анимация инсетов смену высоты открытой клавиатуры не гарантирует, а езда вместе с клавиатурой — вне задачи.

**`adjustResize`** (`AndroidManifest.xml`) остаётся: на Android 15+ окно и так не сжимается, на ≤ 14 модуль ничего не
делает. `edgeToEdgeEnabled=false` не трогаем.

**Файлы:**

- `KeyboardFrameModule.kt` — legacy `ReactContextBaseJavaModule` (как `DeviceCountryModule`), имя `AuraKeyboardFrame`,
  `LifecycleEventListener`.
  - Только при `Build.VERSION.SDK_INT >= 35` (`VANILLA_ICE_CREAM`): в `initialize()` подписка на жизненный цикл и
    (на UI-потоке) подключение к `currentActivity.window.decorView`; `onHostResume` — подключить (повторно — no-op,
    к другому decor — переподключить); `onHostDestroy` и `invalidate()` (перезагрузка JS) — отключить. На ≤ 14 —
    ни одного наблюдателя.
  - `onPreDraw`: `visible = insets.isVisible(ime())`, `top = decor.height − insets.getInsets(ime()).bottom − rootTop`,
    где `rootTop` — `getLocationInWindow` у `android.R.id.content` (корень RN; при edge-to-edge 0). Ключ
    `visible ? top : −1` в px; не изменился — ничего. Изменился — запомнить кадр (`@Volatile`, неизменяемый) и, если
    `hasActiveReactInstance()`, `emitDeviceEvent("auraKeyboardFrame", { visible, keyboardTop })`. Всегда `return true`.
  - `@ReactMethod(isBlockingSynchronousMethod = true) currentFrame()` — последний кадр или `null` (ещё не видел / ≤ 14).
- `KeyboardFramePackage.kt` — `BaseReactPackage`, `needsEagerInit = true` (наблюдатель стоит с запуска, поэтому
  `currentFrame()` верен и для экрана, открытого под уже открытой клавиатурой).
- `MainApplication.kt` — `add(KeyboardFramePackage())` рядом с `DeviceCountryPackage`.
- `MainActivity.kt` — **не меняется** (отступление от формулировки «в MainActivity»: модулю нужен React-контекст для
  события и `invalidate()` на перезагрузку JS; в активности пришлось бы искать текущий контекст на каждом событии).

**Событие:** `auraKeyboardFrame`, `{ visible: boolean, keyboardTop: number }`; `keyboardTop` — dp
(`PixelUtil.toDIPFromPixel`), от верха корня RN, т. е. в пространстве `measure().pageY`. В полноэкранном окне совпадает
с `screenY` RN; в разделённом — точнее его (отсчёт от окна, не от экрана). Плавающая клавиатура: `ime.bottom` = 0 →
`keyboardTop` = низ окна → отступ 0.

## 2. JS — `src/shared/ui/keyboard-avoider/`

- `keyboard-frames.ts` (новый): `KEYBOARD_FRAMES` = `{ current(), subscribe(handler) }` при
  `ANDROID_EDGE_TO_EDGE && NativeModules.AuraKeyboardFrame`, иначе `null`. `subscribe` —
  `DeviceEventEmitter.addListener('auraKeyboardFrame', …)`. Имена модуля и события — константы здесь же.
- `use-keyboard-inset.ts`:
  - **есть `KEYBOARD_FRAMES`** — единственный источник: кадр `visible` → `measure` (`pageY + height − keyboardTop`,
    тот же `keyboardOverlap`), не `visible` → 0. На `keyboardDidShow` / `keyboardDidHide` **не подписываемся** — нет
    двух событий на один показ, нет гонки «чьё позже». При монтировании — `current()`: `visible` → `measure`;
    `null` (модуль ещё не видел окно) → как сейчас, `Keyboard.metrics()`.
  - **нет** (iOS не доходит сюда; Android 15+ со старым APK, т. е. новый JS из Metro на старой debug-сборке) — код
    `AURAT-0186` без изменений.
  - Поворот (`Dimensions` `change` при открытой клавиатуре → `Keyboard.dismiss()`) — в обоих путях: модуль пришлёт
    новый кадр сразу, но рамка Fabric после поворота пересчитывается позже — `measure` прочёл бы старую.
  - Повторные одинаковые кадры: модуль отсекает по px, `setInset` того же числа не перерисовывает.
- `KeyboardAvoider.tsx` — без изменений (только комментарий). `edge-to-edge.ts`, `keyboard-overlap.ts` — без изменений.
- Комментарий хука — переписать: откуда берётся верх клавиатуры и почему RN-события только запасной путь.

## 3. iOS и Android ≤ 14

Без изменений: `KeyboardAvoider` там — RN `KeyboardAvoidingView` (ветка `ANDROID_EDGE_TO_EDGE` = false), модуль на ≤ 14
создаётся, но наблюдатель не ставит и `currentFrame()` = `null`; на iOS модуля нет. Высоту панели на ≤ 14 отслеживает
само сжатие окна (`adjustResize`).

## 4. Тесты

- `KeyboardAvoider.test.tsx` — новый `describe` «native frames» (мок `NativeModules.AuraKeyboardFrame` +
  `DeviceEventEmitter`): рамка внизу на 800, кадр `keyboardTop` 500 → отступ 300; кадр с меньшим `keyboardTop` (панель эмодзи: верх выше) → отступ больше,
  повторный `measure`; кадр обратно → прежний; `visible: false` → 0; `keyboardDidShow` RN при модуле — отступ не
  меняет; монтирование с `current()` = visible → отступ сразу; `current()` = null + `Keyboard.isVisible` →
  `Keyboard.metrics()`; размонтирование — отписка; поворот — `Keyboard.dismiss`. Существующие тесты (без модуля) —
  как есть, это запасной путь.
- Охрана моста (по образцу охраны gradle в `edge-to-edge.test.ts`): читает `KeyboardFrameModule.kt` и
  `MainApplication.kt` — имя модуля и события совпадают с JS-константами, пакет добавлен в `MainApplication`.
- Нативное без устройства: в слоте `cd android && ./gradlew :app:compileDebugKotlin` (сборка, не стек — если SDK в
  слоте доступен; иначе — первым шагом в маноре). Unit-тестов JVM в проекте нет; добавлять JUnit ради одной строки
  арифметики — новая зависимость, не предлагаю.
- `tsc --noEmit`, eslint по затронутым путям, `jest --no-watchman` — всё зелёное.

## 5. TECH-DEBT 17 — новая формулировка (смысл)

- Заголовок: «On Android 15+ the field jumps above the keyboard instead of riding it» (часть про высоту уходит).
- Тело: `KeyboardAvoider` на Android 15+ берёт верх клавиатуры из своего модуля `AuraKeyboardFrame` (каждое изменение
  IME-инсета, панели Gboard и стилуса — `AURAT-0188`); RN `keyboardDidShow` / `Hide` — запасной путь сборки без модуля.
  Остаётся: отступ прыгает, а не едет (кадр приходит, когда инсет уже сменился, без анимации); окно, изменённое без
  поворота (разделённый экран), — рамка Fabric может отстать от кадра до следующего.
- Критичность: Low — только движение, поле всегда видно (вместо «нижний край поля», что было неверно — `0186-011` п. 2).
- Когда платить: после RN 0.86 — `react-native-keyboard-controller` за `KeyboardAvoider`, вместе с
  `edgeToEdgeEnabled=true`; `AuraKeyboardFrame` тогда удалить.

## 6. Проверка в маноре (координатор; нативная правка → новая debug-сборка)

AVD `Galaxy_A16_API36` (Android 16, 1080×2340) — сначала с жестами, потом с тремя кнопками; Gboard (память «AVD API 36
Gboard»). Замеры — `uiautomator dump` + `dumpsys window`, как в `0186-011`.

1. Тред → тап в поле → панель ввода встык над клавиатурой (как `0186-011`: низ 1457 = верх IME).
2. Панель эмодзи → низ панели ввода = верх панели (≈ 1132), эмодзи видны при вводе; «ABC» → снова 1457. Буфер Gboard — то же.
3. phone-auth: панель стилуса → полная клавиатура без закрытия → «Send code» на 16 dp выше верха клавиатуры; обратно — то же.
4. Скрыть клавиатуру (назад / стрелка) → без зазора, как в `0186-011`.
5. Поворот при открытой клавиатуре → клавиатура закрывается, отступ 0.
6. Монтирование под открытой клавиатурой: phone-auth с открытой клавиатурой (в т. ч. после смены панели) → verify-otp
   (`autoFocus`) — содержимое над клавиатурой.
7. Показ клавиатуры: один прыжок или два (записать) — если модуль шлёт промежуточный кадр.
8. Перезагрузка JS (`r` в Metro) при открытой клавиатуре — без падения, после неё п. 2 работает (переподключение).
9. Необязательно: плавающая клавиатура Gboard → отступа нет.
10. A50 (Android 11) на той же debug-сборке — всё как до задачи (KAV; модуль без наблюдателя).
11. Pixel 10 владельца — со сборкой релиза.

## Решения владельца (нужны)

1. Модуль `AuraKeyboardFrame` в пакете приложения вместо кода в `MainActivity` (причина — §1). Да / нет.
2. Запасной путь на RN-событиях для сборки без модуля оставить (нужен только для нового JS на старой debug-сборке;
   стоит ~10 строк, тесты уже есть) — предлагаю оставить.
