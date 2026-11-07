# AURAT-0193-001 — initial

Дата: 2026-11-07
Репо: `aura-app-manor` (приложение, Android). Выдан координатором (сессия slave-1-ac) по находке в проверке `AURAT-0188`
в маноре (`AURAT-0188-011`, п. 9). Владелец — на вопрос «Давнее падение при пересоздании активити … Что делаем?» — «Выдай и
запускай». Свободного слота нет (0188 ждёт проверки на A50 / Pixel, 0180 и 0181 в работе) — делает координатор в своём
слоте slave-1, как `AURAT-0185`.

## Что не так

AVD API 36, debug-сборка `develop` @ `0ea88d0`: смена системного размера шрифта (`settings put system font_scale 1.15`)
при открытом приложении → `FATAL EXCEPTION: main`:

```
Unable to instantiate fragment com.swmansion.rnscreens.ScreenFragment: calling Fragment constructor caused an exception
Caused by: java.lang.IllegalStateException: Screen fragments should never be restored. Follow instructions from
https://github.com/software-mansion/react-native-screens/issues/17#issuecomment-424704067 to properly configure your main activity.
  at com.swmansion.rnscreens.ScreenFragment.<init>(ScreenFragment.kt:66)
  … FragmentManager.restoreSaveStateInternal … ReactActivity.onCreate(ReactActivity.java:60)
```

`MainActivity.kt` не переопределяет `onCreate`. react-native-screens 4.25.2 (README, Android) требует до
`super.onCreate(savedInstanceState)` поставить `supportFragmentManager.fragmentFactory = RNScreensFragmentFactory()`
(`com.swmansion.rnscreens.fragment.restoration.RNScreensFragmentFactory`), иначе при восстановлении состояния активности
`FragmentManager` создаёт `ScreenFragment`, а тот падает.

Когда падает: любое пересоздание активности с сохранённым состоянием — смена размера шрифта или масштаба экрана
(`fontScale` / `density` нет в `configChanges`), смена языка системы (до `AURAT-0181`, который добавляет `locale`), и — по
документации react-native-screens — возврат в приложение после того, как система убила его процесс в фоне.

## Что нужно

1. `MainActivity.kt`: `override fun onCreate(savedInstanceState: Bundle?)` — `fragmentFactory = RNScreensFragmentFactory()`,
   затем `super.onCreate(savedInstanceState)`; комментарий — почему.
2. Охранный тест (как `edge-to-edge.test.ts` читает gradle): `MainActivity.kt` ставит `RNScreensFragmentFactory` до
   `super.onCreate`.
3. Проверка в маноре на новой debug-сборке: смена шрифта при открытом приложении и в фоне — без падения, экран тот же;
   убийство процесса в фоне (`am kill` после Home) и возврат — без падения; A50 — как до задачи.

Не нужна спека: правка из документации библиотеки, без вариантов (как `AURAT-0185` — однострочный фикс по слову владельца).
