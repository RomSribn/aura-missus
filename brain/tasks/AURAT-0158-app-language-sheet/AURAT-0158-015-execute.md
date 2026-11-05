# AURAT-0158-015 — execute (правки ревью 014)

Дата: 2026-11-05. Не закоммичено — ждёт ревью владельца.

1. **Повторное открытие.** `BottomSheet` при открытии сбрасывает `listY`, `onList`, `pullStart`,
   `lastTranslationY`, `pulledTo`; список при размонтировании сообщает 0 (`useEffect` по `[sheet]` — значение
   контекста теперь мемоизировано и меняется только при открытии / закрытии, не посреди прокрутки). Тест «прокрутить
   до 300 → закрыть → открыть → свайп по списку закрывает»; с отключёнными сбросами он падает (проверено).
2. `testID` жеста — только при `__DEV__`, ключ в релизе отсутствует.
3. Конфиг `usePanGesture` в `useMemo([visible, scrollable, onDrag])`, колбэки через `callbacks` ref. Тесты листа
   размонтируют деревья в `afterEach`.
4. Тесты движения: `dispatchesAnimatedEvents` + `_argMapping` = `{ nativeEvent: { handlerData: { translationY } } }`
   вне scrollable; scrollable — JS-функция; сдвиг листа после передачи = 50 (90 − 40); `simultaneousHandlers`
   нативного жеста списка содержит тег жеста листа — для `BottomSheetScrollView` и `BottomSheetFlatList`.
5. JS-поток для scrollable-листов (грип тоже) — принято как размен ради позиции списка; проверить на слабом
   Android в маноре; Reanimated — позже, не блокирует.
6. Фильтр `simultaneousHandlers` в `JSON.stringify` тестов листа и профиля убран: v3 не кладёт связи в пропы хоста.
   Фраза в `013` («мок кладёт жест в пропы хоста») — неверна.
7. `onListDrag` пишет `drag` только при изменении (`pulledTo`), `settle` и открытие сбрасывают — пружина не
   обрывается.
8. `scroll.tsx` → `BottomSheetLists.tsx`.

Проверка: `npx tsc --noEmit`, `npx eslint .` — чисто; `npx jest --no-watchman` — 176 наборов, 1615 тестов, все
зелёные.
