# AURAT-0188-007 — spec v2 (draft, ждёт одобрения владельца)

Заменяет `005`. Основание — `004`; замечания координатора и решения владельца — `006`. Новых зависимостей нет.

Решения владельца (`006`): **1** — модуль `AuraKeyboardFrame` в пакете приложения, `MainActivity` не меняется;
**2** — запасной путь на событиях RN для сборки без модуля остаётся.

## Итог

Свой маленький нативный модуль `AuraKeyboardFrame` (Android 15+) следит за IME-инсетом окна активности и шлёт в JS
верх клавиатуры при **каждом** его изменении. `use-keyboard-inset` на Android 15+ берёт отступ только из него; события
RN `keyboardDidShow` / `keyboardDidHide` — лишь запасной путь для сборки без модуля. iOS и Android ≤ 14 не меняются.

## 1. Нативная часть — `android/app/src/main/java/cc/silvermind/aura/`

**Механизм:** `ViewTreeObserver.OnPreDrawListener` на `decorView` окна активности + `decorView.rootWindowInsets`
(платформенные `WindowInsets`, API 30+). Не `OnApplyWindowInsetsListener` и не `WindowInsetsAnimationCompat.Callback`:

- слот `setOnApplyWindowInsetsListener` у decorView уже делят RN `StatusBar.setTranslucent` (ставит **и обнуляет**,
  `WindowUtil.kt:41-57`) и react-native-screens (`InsetsObserverProxy`, `SheetDelegate.kt:91`); у
  `setWindowInsetsAnimationCallback` тоже один слот;
- наблюдатели `ViewTreeObserver` складываются и ничего не перехватывают — инсеты по-прежнему доходят до всех; так же
  устроены RN (`OnGlobalLayoutListener`, `ReactRootView.java:933`) и safe-area-context (`OnPreDraw`);
- `OnPreDraw`, а не `OnGlobalLayout`: смена инсетов всегда планирует проход `ViewRootImpl`, а pre-draw бывает на
  каждом проходе, даже без перекладки; проверка — чтение закэшированных `rootWindowInsets` и сравнение чисел;
- анимация инсетов смену высоты открытой клавиатуры не гарантирует, а езда вместе с клавиатурой — вне задачи.

`adjustResize` (`AndroidManifest.xml`) и `edgeToEdgeEnabled=false` не трогаем.

### `KeyboardFrameModule.kt`

Legacy `ReactContextBaseJavaModule` (как `DeviceCountryModule`), имя `AuraKeyboardFrame`, `LifecycleEventListener`.
Всё ниже — только при `Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM` (35); на ≤ 14 JS к модулю не
обращается вовсе (п. 2), а если бы обратился — ни одного наблюдателя.

- **Состояние.** `WeakReference<View>` на decor, к которому подключён, и сам listener — **никогда не
  `ViewTreeObserver`** в поле: после пересоздания активности (шрифт / язык / плотность не в `configChanges`)
  `onHostResume` приходит до присоединения decor к окну, его VTO ещё плавающий и после слияния умирает; `remove` через
  сохранённый VTO бросил бы `IllegalStateException` → в релизе падение (`DefaultReactHostDelegate.kt:44`). Ключ
  последнего кадра в px (только UI-поток), стартует незаданным. Последний кадр — `@Volatile` неизменяемый Kotlin
  `data class Frame(visible: Boolean, keyboardTop: Double)`. Флаг `@Volatile dead`.
- **Подключение** (UI-поток): `initialize()` — `addLifecycleEventListener(this)` и
  `UiThreadUtil.runOnUiThread { attach(currentActivity) }`; `onHostResume` — `attach(currentActivity)`. `attach`: если
  `dead` — ничего; decor тот же — ничего; иначе `detach()` и `decor.viewTreeObserver.addOnPreDrawListener(listener)`
  (VTO берётся в момент вызова; плавающий при слиянии передаст listener окну).
- **Отключение** (UI-поток): `onHostDestroy` → `detach()`: `decor.viewTreeObserver` в момент вызова, `isAlive` →
  `removeOnPreDrawListener`; сброс ссылки, px-ключа и кадра — `current()` никогда не отдаст кадр чужого окна.
- **Перезагрузка JS.** Старый контекст получает только `onHostPause`, а `invalidate()` вызывается на bgExecutor
  (`ReactHostImpl.kt:1331-1405`), VTO не потокобезопасен. `invalidate()`: `dead = true`, сброс кадра,
  `removeLifecycleEventListener(this)`, `UiThreadUtil.runOnUiThread { detach() }`. `onPreDraw` проверяет `dead` перед
  отправкой — старый модуль не шлёт события в новый JS.
- **`onPreDraw`** (всегда `return true`): `dead` / нет decor / `rootWindowInsets == null` / нет `android.R.id.content`
  → ничего. `visible = insets.isVisible(ime())`; `top = decor.height − insets.getInsets(ime()).bottom − rootTop`,
  `rootTop` — `getLocationInWindow` у `android.R.id.content` (корень RN; при edge-to-edge 0). Ключ — `top`, если
  `visible`, иначе отдельное значение «скрыта»; совпал с прежним — ничего. Иначе запомнить `Frame` и, если
  `hasActiveReactInstance()`, `emitDeviceEvent("auraKeyboardFrame", map)`. Первый pre-draw после подключения кадр
  отправляет всегда (ключ не задан).
- **`@ReactMethod(isBlockingSynchronousMethod = true) fun currentFrame(): WritableMap?`** — последний `Frame` или `null`
  (ещё не видел окно / отключён). `WritableMap` — `Arguments.createMap()` **заново** на каждый возврат и каждый emit:
  Kotlin `Map` падает в JNI, а сохранённая `WritableNativeMap` при второй передаче уже consumed
  (`JavaTurboModule.cpp:764-777`).

### `KeyboardFramePackage.kt`, `MainApplication.kt`

`BaseReactPackage` по образцу `DeviceCountryPackage`, `needsEagerInit = false` (eager для legacy-модуля в bridgeless
не действует — только для `isTurboModule`, `ReactPackageTurboModuleManagerDelegate.kt:182-189`). В `MainApplication.kt` —
`add(KeyboardFramePackage())` рядом с `DeviceCountryPackage`. `MainActivity.kt` не меняется.

**Почему модуль, а не `MainActivity`** (решение 1): по наличию модуля JS отличает новую сборку от старой — на этом
держится запасной путь (решение 2); и синхронный `current()` для монтирования под открытой клавиатурой. Плюс модулю
приходят жизненный цикл React-контекста и `invalidate()` на перезагрузку JS.

**Событие:** `auraKeyboardFrame`, `{ visible: boolean, keyboardTop: number }`; `keyboardTop` — dp
(`PixelUtil.toDIPFromPixel`) от верха корня RN, т. е. в пространстве `measure().pageY`. В полноэкранном окне совпадает
со `screenY` RN; в разделённом — точнее (от окна, не от экрана). Плавающая клавиатура: `ime.bottom` = 0 → верх = низ
окна → отступ 0.

## 2. JS — `src/shared/ui/keyboard-avoider/`

- **`keyboard-frames.ts`** (новый): `KEYBOARD_FRAMES = { current(), subscribe(handler) }` при
  `ANDROID_EDGE_TO_EDGE && NativeModules.AuraKeyboardFrame`, иначе `null` (сначала флаг — на ≤ 14 и iOS к
  `NativeModules` не обращаемся, модуль не создаётся). `subscribe` — `DeviceEventEmitter.addListener('auraKeyboardFrame', …)`,
  возвращает подписку с `remove()`. Имена модуля и события — константы здесь же. Константу `observing` через
  `getConstants` не вводим: пороги стережёт тест (п. 4).
- **`use-keyboard-inset.ts`:**
  - **есть `KEYBOARD_FRAMES`** — единственный источник: кадр `visible` → `measure` (`pageY + height − keyboardTop`,
    тот же `keyboardOverlap`), не `visible` → 0. На `keyboardDidShow` / `keyboardDidHide` **не подписываемся** — нет
    двух событий на один показ и гонки «чьё позже». При монтировании — `current()`: `visible` → `measure`; `null` →
    как сейчас, `Keyboard.metrics()` при `Keyboard.isVisible()`.
    `current()` **пуст на первом монтировании avoider после старта или перезагрузки JS**: модуль создаётся при первом
    чтении `NativeModules` (inlineRequires) — в этом же эффекте. Первый pre-draw после подключения шлёт кадр, и
    отступ поправится через кадр (например, если в этот момент открыта панель эмодзи и `metrics()` устарел).
  - **нет** (Android 15+ со старым APK — новый JS из Metro на старой debug-сборке) — код `AURAT-0186` без изменений.
  - Поворот (`Dimensions` `change` при открытой клавиатуре → `Keyboard.dismiss()`) — в обоих путях: модуль пришлёт
    новый кадр сразу, но рамка Fabric после поворота пересчитывается позже, и `measure` прочёл бы старую.
  - Повторные одинаковые кадры отсекает модуль по px; `setInset` того же числа не перерисовывает.
  - Комментарий хука — переписать: откуда верх клавиатуры, почему RN-события — запасной путь.
- `KeyboardAvoider.tsx` — только комментарий. `edge-to-edge.ts`, `keyboard-overlap.ts` — без изменений.
- Перемер по `onLayout` (рамка avoider сдвинулась при открытой клавиатуре) — не делаем, см. TECH-DEBT 17.

## 3. iOS и Android ≤ 14

Без изменений: `KeyboardAvoider` там — RN `KeyboardAvoidingView` (`ANDROID_EDGE_TO_EDGE` = false), `KEYBOARD_FRAMES` =
`null` ещё до обращения к `NativeModules` — модуль не создаётся. На iOS модуля нет. Высоту панели на ≤ 14 отслеживает
сжатие окна (`adjustResize`).

## 4. Тесты

- **`KeyboardAvoider.test.tsx`** — `jest.mock('../keyboard-frames')` геттером (как `edge-to-edge`), фейк
  `{ current, subscribe }` на настоящем `EventEmitter`; новый `describe` «native frames»:
  - рамка внизу на 800, кадр `keyboardTop` 500 → отступ 300; кадр 300 (панель эмодзи выше) → 500, повторный
    `measure`; обратно 500 → 300; `visible: false` → 0;
  - слушателей `keyboardDidShow` / `keyboardDidHide` нет вовсе (`handlers.keyboardDidShow` — `undefined`);
  - монтирование с `current()` visible → отступ сразу; `current()` = `null` при заданном `Keyboard.metrics()` → отступ
    по нему, первое событие его перекрывает;
  - число слушателей события: один avoider 1 → 0 при размонтировании, два — 2 → 0;
  - поворот при открытой клавиатуре → `Keyboard.dismiss`.
  Существующие тесты (без модуля, `KEYBOARD_FRAMES` = `null`) — как есть: это запасной путь.
- **`keyboard-frames.test.ts`** (новый, `jest.isolateModules` + `Platform`, как `edge-to-edge.test.ts`): `null` на iOS,
  на Android 34 и на 35 без модуля (и `NativeModules.AuraKeyboardFrame` не читался на iOS / 34); на 35 с модулем —
  `current()` проксирует, `subscribe` слушает `'auraKeyboardFrame'` через `DeviceEventEmitter`, `remove()` отписывает
  (`listenerCount` 1 → 0).
- **Охрана моста** (по образцу охраны gradle): читает `KeyboardFrameModule.kt` и `MainApplication.kt` — имя модуля и
  события равны JS-константам; в payload ключи `visible` и `keyboardTop` (опечатка дала бы `NaN` в `paddingBottom`);
  порог SDK в Kotlin — `VANILLA_ICE_CREAM` / 35 — равен порогу `ANDROID_EDGE_TO_EDGE` (`edge-to-edge.ts:20`);
  `add(KeyboardFramePackage())` есть в `MainApplication.kt` вне комментария.
- **Нативное без устройства:** в слоте `cd android && ./gradlew :app:compileDebugKotlin` (сборка, не стек — если SDK
  доступен в слоте; иначе — первым шагом в маноре). JUnit не добавляю (новая зависимость ради одной строки арифметики).
- `tsc --noEmit`, eslint по затронутым путям, `jest --no-watchman` — всё зелёное.

## 5. TECH-DEBT 17 — новая формулировка (смысл; текст по-английски, как в файле)

- Заголовок: «On Android 15+ the field jumps above the keyboard instead of riding it» (часть про высоту уходит).
- Тело: `KeyboardAvoider` на Android 15+ берёт верх клавиатуры из своего модуля `AuraKeyboardFrame` — каждое изменение
  IME-инсета, панели Gboard и стилуса (`AURAT-0188`); RN `keyboardDidShow` / `Hide` — запасной путь сборки без модуля.
  Остаётся: отступ прыгает, а не едет (кадр приходит, когда инсет уже сменился, без анимации); поворот закрывает
  клавиатуру нарочно; после изменения размера окна без поворота (split screen / freeform) нижний край поля может
  остаться закрытым на разницу инсетов до следующего кадра клавиатуры.
- Критичность: Low — движение и редкий split screen (вместо «нижний край поля», что было неверно — `0186-011` п. 2).
- Когда платить: после RN 0.86 — `react-native-keyboard-controller` за `KeyboardAvoider`. **Правило очерёдности (здесь
  и только здесь):** `edgeToEdgeEnabled=true` и расширение `ANDROID_EDGE_TO_EDGE` на весь Android — только одним
  изменением с удалением модуля, никогда раньше (иначе на A50 модуль «есть, но молчит» и запасной путь выключен).
  Удаляется вместе: `KeyboardFrameModule.kt`, `KeyboardFramePackage.kt`, строка в `MainApplication.kt`,
  `keyboard-frames.ts` и его тест, охранный тест моста, запасной путь в `use-keyboard-inset.ts`.
- Решение 2 и комментарий в `keyboard-frames.ts` ссылаются на это правило, не повторяя его.

## 6. Проверка в маноре (координатор; нативная правка → новая debug-сборка)

AVD `Galaxy_A16_API36` (Android 16, 1080×2340), Gboard (память «AVD API 36 Gboard»). Замеры — `uiautomator dump` +
`dumpsys window`, как в `0186-011`.

0. **До установки нового APK:** новый JS из Metro на debug-сборке `0186` (модуля нет → запасной путь): пп. 1, 4, 5 —
   как в `0186-011`; панель эмодзи по-прежнему закрывает поле — ожидаемо.
1. Новый APK, жесты. Тред → тап в поле → панель ввода встык над клавиатурой (низ 1457 = верх IME).
2. Панель эмодзи → низ панели ввода = верх панели (≈ 1132), эмодзи видны при вводе; «ABC» → снова 1457. Буфер — то же.
3. phone-auth: панель стилуса → полная клавиатура без закрытия → «Send code» на 16 dp выше верха клавиатуры; обратно — то же.
4. Скрыть клавиатуру (назад / стрелка) → без зазора, как в `0186-011`.
5. Поворот при открытой клавиатуре → клавиатура закрывается, отступ 0.
6. Первое монтирование после старта приложения под открытой клавиатурой: холодный старт → phone-auth с открытой
   клавиатурой, сменить панель → «Send code» → verify-otp (`autoFocus`) — содержимое над клавиатурой.
7. Один прыжок или два при показе (промежуточный кадр): `adb shell screenrecord`, разбор по кадрам — записать.
8. Перезагрузка JS (`r` в Metro) при открытой клавиатуре — без падения; после неё п. 2 работает.
9. Пересоздание активности при открытой клавиатуре: сменить системный размер шрифта, вернуться — пп. 1–2 работают;
   уйти из приложения или сменить шрифт ещё раз — без падения.
10. Home → вернуться при открытой клавиатуре, затем панель эмодзи — п. 2 работает.
11. Три кнопки — повторить пп. 1–4.
12. Необязательно: плавающая клавиатура Gboard → отступа нет.
13. A50 (Android 11) на той же debug-сборке — всё как до задачи (KAV; модуль не создаётся).
14. Pixel 10 владельца — со сборкой релиза.

## Пересечение

`AURAT-0181` (slave-0) тоже добавляет пакет в `MainApplication.kt` рядом с `DeviceCountryPackage` — при втором мёрже
конфликт в одну строку, решается при мёрже.
