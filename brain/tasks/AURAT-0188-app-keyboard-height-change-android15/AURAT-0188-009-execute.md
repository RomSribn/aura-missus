# AURAT-0188-009 — execute

2026-11-07, slave-2, `feature/AURAT-0188-app-keyboard-height-change-android15` (от `develop` @ `71e03d2`). По спеке v2
(`007`, одобрена — `008`). Не закоммичено — всё застейджено, ждёт ревью кода координатора и владельца.

## Файлы

Натив (`android/app/src/main/java/cc/silvermind/aura/`):
- `KeyboardFrameModule.kt` (новый) — legacy-модуль `AuraKeyboardFrame`, `LifecycleEventListener`. Только при
  `SDK_INT >= VANILLA_ICE_CREAM`: `OnPreDrawListener` на decor активности, `rootWindowInsets` → `{ visible, keyboardTop }`
  (dp от верха `android.R.id.content`), событие `auraKeyboardFrame` при смене px-ключа; `currentFrame()` — sync,
  `WritableMap?`, новая карта на каждый возврат / emit. В полях — `WeakReference` на decor и listener, VTO берётся в
  момент add / remove (`isAlive` перед remove); `detach` сбрасывает ссылку, ключ и кадр; `invalidate()` — `dead`, сброс
  кадра, `removeLifecycleEventListener`, `detach` через `UiThreadUtil.runOnUiThread`; `read()` проверяет `dead` и
  `hasActiveReactInstance()` перед emit; null-guard на `rootWindowInsets` и `content`.
- `KeyboardFramePackage.kt` (новый) — `BaseReactPackage`, `needsEagerInit = false` (комментарий — почему).
- `MainApplication.kt` — `add(KeyboardFramePackage())`.

JS (`src/shared/ui/keyboard-avoider/`):
- `keyboard-frames.ts` (новый) — `KEYBOARD_FRAMES` (`current`, `subscribe`) при `ANDROID_EDGE_TO_EDGE` и наличии модуля
  (флаг проверяется первым — на iOS / ≤ 14 `NativeModules` не читается), константы имён модуля и события, тип
  `KeyboardFrame`. Комментарий ссылается на правило очерёдности в TECH-DEBT 17.
- `use-keyboard-inset.ts` — с модулем: единственный источник (на `keyboardDidShow/Hide` не подписывается), mount по
  `current()`, при `null` — `Keyboard.metrics()`; без модуля — путь `0186`; поворот → `Keyboard.dismiss()` в обоих.
  Комментарий переписан.
- `KeyboardAvoider.tsx` — только комментарий.
- `__tests__/KeyboardAvoider.test.tsx` — мок `../keyboard-frames` геттером, фейк на `events.EventEmitter`; прежний
  `describe` Android 15+ переименован в «an APK without the module»; новый «frames from the native module» (9 тестов:
  кадры 500 → 300 → 500, скрытие, нет слушателей RN, mount по кадру, закрытый кадр не берёт `metrics`, `null` +
  `metrics` → событие перекрывает, 1 → 0 слушателей, два avoider 2 → 0, поворот).
- `__tests__/keyboard-frames.test.ts` (новый) — `isolateModules`: `null` на iOS и 34 без чтения `NativeModules`, на 35
  без модуля; `current()` проксирует; `subscribe` / `remove` (`listenerCount` 1 → 0). Охрана моста: имена модуля и
  события в `.kt`, ключи payload `keyboardTop` / `visible`, все проверки SDK в `.kt` — `VANILLA_ICE_CREAM` и порог JS 35,
  `add(KeyboardFramePackage())` в `MainApplication.kt` вне комментариев.
- `TECH-DEBT.md` — строка 17 переписана по `007` §5 (правило очерёдности и список удаляемого — только здесь).

## Решения по ходу

- Тест подписки берёт обычный `DeviceEventEmitter`, не из изолированного реестра: inline requires Babel разрешают
  `react-native` в момент вызова `subscribe`, уже вне `isolateModules` (комментарий в тесте).
- `KeyboardFrames` (тип) не экспортирую — потребителей вне файла нет.
- TECH-DEBT.md и до задачи не проходил `prettier --check` — таблицу не переформатировал, менял только строку 17.
- Перемер по `onLayout` не делал (по спеке).

## Проверки в слоте

- `node_modules` слота были устаревшими (tsc падал на чужом `src/test-support/advisor.ts`, `topics`) → `npm ci` (exit 0).
- `npx tsc --noEmit` — 0; `eslint src/shared/ui/keyboard-avoider` — 0; `prettier --check` слайса — чисто.
- `jest --no-watchman` — 227 наборов, 3107 тестов, все зелёные.
- `./gradlew :app:compileDebugKotlin` — BUILD SUCCESSFUL (2 м 24 с), предупреждений по коду приложения нет. Gradle при
  этом сам доустановил в `~/Library/Android/sdk` NDK 27.1.12297006 (его не было).

## Открыто

Проверка в маноре — `007` §6 (новая debug-сборка; п. 0 — новый JS на APK 0186 до установки).
