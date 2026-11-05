# AURAT-0158-022 — fix: ревью 021 (рецензент по просьбе владельца) — «в таком виде не мёржить»

Дата: 2026-11-05. Попутно: сборка `248c7db` (legacy) — 40 мин на A50, assert'а нет.

1. **Блокирует, iOS.** JS-`listener` у native `Animated.event` не вызывается: legacy-хендлер iOS шлёт move-события
   только в `sendEventForNativeAnimatedEvent` → NativeAnimated, не в JS (`RNGestureHandlerManager.mm:367-375,
   472-479`). `pullFrom` не трогается — на iPhone свайп листа со списком мёртв. Правка: `useNativeDriver: !isIOS`
   (на iOS — JS-событие, пишет `gestureY` и зовёт `listener`), комментарий, тест.
2. **Серьёзное, Android (PLAUSIBLE).** Движения (FabricEventDispatcher, следующий кадр) и смены состояния
   (deviceEventEmitter, сразу) идут разными каналами: END может опередить последнее движение → опоздавший
   `listener` ставит `pullFrom = 0`, лист остаётся оттянутым; короткий флик может не закрыть. Правка: `panActive`
   (BEGAN / ACTIVE → true, `onFinish` → false, `listener` при false — выход); в END прогнать передачу с его
   `translationY`; `gestureY` в `onFinish` не сбрасывать. Тест: движение после END ничего не меняет.
3. Прижатие срабатывает и при тяге не со списка: `isPulled = onList && pullStart !== null`.
4. Тесты: прижатие `FlatList` (`scrollToOffset`), `onScroll` потребителя молчит при прижатии, тесты к 1 и 2.
5. Пружина — в последнее принятое движение (его держит `gestureY`), а не в `translationY` из END.
