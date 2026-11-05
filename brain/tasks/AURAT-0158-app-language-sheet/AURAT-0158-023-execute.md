# AURAT-0158-023 — execute (правки ревью 022)

Дата: 2026-11-05. Не закоммичено — ждёт одобрения владельца.

1. **iOS.** Обработчик движений scrollable-листа — `listPullEvent(gestureY, listener, native = !isIOS)`
   (`bottom-sheet/list-pull.ts`): на Android — native-driver событие (тяга на UI-потоке, движения доходят и до JS);
   на iOS — JS-событие (пишет `gestureY` и зовёт `listener`), потому что legacy-хендлер iOS шлёт native-событие только
   в NativeAnimated. Схема `gestureY − pullFrom` та же; на iOS дрожь гасит прижатие списка — проверить на iPhone.
2. **Android, гонка каналов.** `panActive`: BEGAN / ACTIVE → true, `onFinish` → false; `listener` вне касания
   ничего не делает. На END передача прогоняется ещё раз по его `translationY` (быстрый флик, все движения которого
   пришли после END, закрывает лист). `gestureY` в `onFinish` не трогается.
3. `isPulled = onList && pullStart !== null` — тяга за грип / заголовок не прижимает катящийся список.
4. Тесты: iOS-путь (функция), `list-pull.test.ts` (native: маппинг v2 + один listener; JS: пишет значение и зовёт
   listener), движение после END ничего не меняет, флик с движениями после END закрывает, грип не прижимает
   список, `FlatList` прижимается (`scrollToOffset`) и `onScroll` потребителя молчит. Тестовый `move` — JS-событие
   (Jest = iOS) или эмуляция native (Android). `scrollTo` в пресете Jest — один `jest.fn` на все ScrollView: тесты
   очищают его перед наблюдением, `afterEach` — `restoreAllMocks`.
   Мутационная проверка: убрать `onList` из `isPulled`, guard `panActive`, передачу на END или поставить
   `useNativeDriver: true` на iOS — каждый раз падает свой тест.
5. Пружина — в `max(translationY END, последнее движение)`: туда, где стоит `gestureY`.

Проверка: `npx tsc --noEmit`, `npx eslint .` — чисто; `npx jest --no-watchman` — 177 наборов, 1623 теста, зелёные.

На устройстве: Android (A50) — ~20 отпусканий на ходу и короткие флики с верха, тяга без дрожи; iOS (iPhone или
симулятор) — свайп по списку и за грип двигает лист, дрожи нет.
