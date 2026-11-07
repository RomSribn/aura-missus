# AURAT-0188-004 — context

Код — `develop` @ `71e03d2`, RN 0.85.3 в `node_modules` слота.

## Почему высоту не видно (подтверждено по исходникам)

1. `ReactRootView.CustomGlobalLayoutListener.checkForKeyboardEvents` (`ReactRootView.java:964-1004`, API 30+): событие
   уходит только когда `rootInsets.isVisible(ime())` **меняется**. Высота при открытой клавиатуре не сравнивается
   (в отличие от `checkForKeyboardEventsLegacy` < API 30, где есть «KeyboardHeightChanged»). Значит, ни
   `keyboardDidShow`, ни `Keyboard.metrics()` не узнают о панели эмодзи — нужен свой источник.
2. Триггер RN — `OnGlobalLayoutListener` на корне; данные — `getRootView().getRootWindowInsets()`. На этом окне (AVD
   API 36, edge-to-edge) он срабатывает на показ / скрытие (`AURAT-0186-011`).

## Кто ещё слушает инсеты (с чем уживаться)

| Кто | Что | Вывод |
|---|---|---|
| RN `StatusBar.setTranslucent` (`WindowUtil.kt:41-57`) | `decorView.setOnApplyWindowInsetsListener(…)` / `(null)` | слот decorView может быть перезаписан или **обнулён** — не наш |
| react-native-screens `InsetsObserverProxy` (`SheetDelegate.kt:91`) | `ViewCompat.setOnApplyWindowInsetsListener(decorView, …)` | тот же слот decorView |
| RN `ReactSafeAreaView`, LogBox, RedBox, PerfMonitor | слушатели на своих view / окнах-диалогах | не пересекаются |
| safe-area-context (`SafeAreaProvider.kt:29`) | `ViewTreeObserver.OnPreDrawListener` + `rootWindowInsets` | прецедент: наблюдатель дерева не занимает слот |
| RN `ReactRootView` | `OnGlobalLayoutListener` + `rootWindowInsets` | то же |

`setOnApplyWindowInsetsListener` — один слот на view; `View.setWindowInsetsAnimationCallback` — тоже один. Наблюдатели
`ViewTreeObserver` складываются — их можно добавить сколько угодно, ничего не перехватывая.

## WindowInsetsAnimationCompat.Callback — почему не он

Даёт покадровую анимацию показа / скрытия, но смена высоты открытой клавиатуры (панель Gboard) анимацией не обязана
быть (keyboard-controller ради этого отдельно разбирает `onApplyWindowInsets`) — а нужна именно она. Езда вместе
с клавиатурой — вне задачи (TECH-DEBT 17, keyboard-controller после RN 0.86).

## Координаты

`keyboardDidShow.screenY` — `visibleDisplayFrame.bottom`, экранные px → dp. Хук сравнивает с `measure().pageY + height`
(от корня RN; `AURAT-0186-010`). IME-инсет (`getInsets(ime()).bottom`) отсчитан от низа окна → верх клавиатуры в
координатах окна = `decorView.height − ime.bottom`; минус верх корня RN в окне (`content.getLocationInWindow`, при
edge-to-edge 0) — ровно пространство `pageY`. В полноэкранном окне это совпадает со `screenY` RN, в разделённом — точнее.
Плавающая клавиатура Gboard: `isVisible(ime)` = true, `ime.bottom` = 0 → верх = низ окна → отступ 0 (верно: она не
занимает инсет).

## Образец своего модуля

`DeviceCountryModule` (`AURAT-0152`): legacy `ReactContextBaseJavaModule` + `BaseReactPackage`, добавлен вручную в
`MainApplication.kt` (своё не автолинкуется), JS читает через `NativeModules`. `ReactContext.emitDeviceEvent(name, args)`
есть (`ReactContext.java:158`); sync-методы legacy-модулей поддержаны interop-слоем (`TurboModuleInteropUtils.kt`).
Новых зависимостей не нужно: `androidx.core` / платформенные `WindowInsets` уже в сборке (RN тянет их сам).
