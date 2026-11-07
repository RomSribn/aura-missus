# AURAT-0186-009 — execute

2026-11-07, slave-0, `feature/AURAT-0186-chat-input-keyboard-android15` (от `develop` @ `1bf1943`). По спеке v2 (`007`).
Не закоммичено — ждёт ревью владельца и координатора; всё застейджено.

## Файлы

Новый слайс `src/shared/ui/keyboard-avoider/`:
- `KeyboardAvoider.tsx` — iOS: RN KAV `padding`; Android ≤ 14: RN KAV `legacyAndroid`; Android 15+: свой `View`
  с `paddingBottom` из хука.
- `use-keyboard-inset.ts` — `keyboardDidShow` → `measureInWindow` своего внешнего `View` → перекрытие;
  `keyboardDidHide` → 0 (координаты закрытия не используются); при монтировании под открытой клавиатурой —
  `Keyboard.metrics()`; «билет» отбрасывает измерение, пришедшее после более нового события.
- `keyboard-overlap.ts` — `max(0, низ − верх клавиатуры)`.
- `edge-to-edge.ts` — `ANDROID_EDGE_TO_EDGE = !isIOS && Platform.Version >= 35` (на `isIOS` из `shared/lib/styles`).
- `index.ts`; экспорт `KeyboardAvoider` из `shared/ui/index.ts` и `@/shared`.
- `__tests__/`: `keyboard-overlap.test.ts`; `edge-to-edge.test.ts` (ios / 34 / 35 / 37 через `isolateModules`
  + охрана сборки: `targetSdkVersion ≥ 35`, `edgeToEdgeEnabled=false`, сообщение «revisit ANDROID_EDGE_TO_EDGE»);
  `KeyboardAvoider.test.tsx` (iOS / legacy Android — RN KAV с нужным `behavior`; 15+ — padding по показу, тот же
  padding на повторный показ, 0 на скрытие с `screenY` = высота видимой области, монтирование под клавиатурой,
  отписка).

Экраны (`KeyboardAvoidingView` → `KeyboardAvoider`, `Platform` убран где больше не нужен):
- `chat-thread/ui/ChatThreadScreen.tsx` — без `legacyAndroid`; комментарий над ним переписан.
- `phone-auth`, `verify-otp`, `create-account`, `edit-profile`, `write-review` — `legacyAndroid="height"`.
- `phone-auth` — `edges` на Android `['top','bottom']` (константа `EDGES` в файле), iOS `['top']`.
- `chat-thread/ui/__tests__/ChatThreadScreen.test.tsx` — поле ввода внутри `KeyboardAvoider`.
- `TECH-DEBT.md` — строка 17: прыжок без анимации и неотслеживаемая высота клавиатуры на Android 15+ →
  `react-native-keyboard-controller` после RN 0.86 (решение владельца), вместе с `edgeToEdgeEnabled=true`.

## Решения по ходу

- verify-otp нижний край **не** получил: внизу у него нет кнопки — только распорка (`spacer`), содержимое
  сверху; нижний инсет ничего бы не изменил. Отступ от панели навигации нужен только phone-auth.
- `KeyboardAvoiderProps` из слайса не экспортирую — потребителей нет (правило 5).
- `BottomSheet` не тронут — ждёт шага 0 проверки в маноре (`007` п. 4).

## Проверки в слоте

`npm ci` (exit 0); `npx tsc --noEmit` — 0; eslint по затронутым путям — 0; `jest --no-watchman` —
226 наборов, 3086 тестов, все зелёные.

## Открыто

- Шторки (поиск страны, `BirthDateSheet`) — шаг 0 в маноре на develop; по итогу — отдельный шаг.
- Разделённый экран / оконный режим: `measureInWindow` — в координатах окна, `screenY` — экрана; при окне не на
  весь экран отступ может разойтись. Не проверялось; к чек-листу как необязательное.
- Проверка в маноре — чек-лист `007`.

---
**Поправка (`010`, ревью кода slave-1-ac):** мерим не `measureInWindow`, а `measure` (`pageY + height`). На Android
`measureInWindow` прибавляет `viewportOffset` корня = `locationOnScreen − visibleFrame.top` (`ReactSurfaceView.kt:48-60`),
при edge-to-edge это −строка состояния → отступ был меньше нужного на её высоту.
