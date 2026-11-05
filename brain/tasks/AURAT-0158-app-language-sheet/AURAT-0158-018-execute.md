# AURAT-0158-018 — execute: лист и списки обратно на legacy-API gesture-handler

Дата: 2026-11-05. Не закоммичено — ждёт одобрения владельца. По `017`.

- `BottomSheet.tsx`: `usePanGesture` + `GestureDetector` → `PanGestureHandler` (как до `013`). Вне `scrollable` —
  native-driver `Animated.event` в форме v2 (`nativeEvent.translationY`); `scrollable` — `onGestureEvent`
  JS-функцией. Конец касания — `onHandlerStateChange`: END закрывает по `releaseDismisses`, CANCELLED / FAILED — как
  отменённый; затем сброс. Конфиг-`useMemo`, ref колбэков и `testID` v3 ушли (legacy-хендлер сравнивает конфиг сам).
  Контекст `SheetListLink` — `{ panRef, … }`, один объект на всю жизнь листа.
- `BottomSheetLists.tsx`: `LegacyScrollView` / `LegacyFlatList`, `simultaneousHandlers: panRef` — связь объявлена со
  стороны списка: RNGH читает её в обе стороны (iOS `RNGestureHandler.mm:719-729`, Android
  `GestureHandlerOrchestrator.canRunSimultaneously`), а ref `LegacyFlatList` — не хендлер.
- Сохранено из `014`/`015`: `listPullStart`, пять сбросов при открытии, `onListScroll(0)` при размонтировании,
  `pulledTo`.
- Тесты: жест — через пропы `PanGestureHandler` (`onHandlerStateChange` / `onGestureEvent`); маппинг native-driver
  (`__isNative`, `_argMapping` = `{ nativeEvent: { translationY } }`); `simultaneousHandlers.current` списка = экземпляр
  хендлера листа (ScrollView и FlatList); закрытый лист без хендлера; **страж**: в дереве обычного и двух scrollable
  листов нет `GestureDetector` / `InterceptingGestureDetector` / `VirtualGestureDetector` / v3 `ScrollView` / `FlatList`.
  В тестах листа языка и профиля снова пропуск `simultaneousHandlers` в `JSON.stringify` — legacy-список в Jest это
  обычный ScrollView, ref листа попадает в пропы хоста (для legacy это верно, в отличие от `015`).
- `grep -rn "GestureDetector\|usePanGesture\|simultaneousWith\|NativeDetector\|handlerData" src` (без тестов) — пусто.

Проверка: `npx tsc --noEmit`, `npx eslint .` — чисто; `npx jest --no-watchman` — 176 наборов, 1615 тестов, зелёные.

Предложение рецензента — строка в `.claude/aura-build-rules.md`: gesture-handler только legacy-API, пока RN < 0.86.2
(gesture-handler #4241); перевод таро / ZoomableImage / advisor-profile на v3 блокирован тем же — к владельцу.
