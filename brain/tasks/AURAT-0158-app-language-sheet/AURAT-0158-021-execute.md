# AURAT-0158-021 — execute: тяга scrollable-листа на UI-потоке, список прижат к верху

Дата: 2026-11-05. Не закоммичено — ждёт одобрения владельца. По `020`.

- `BottomSheet.tsx`: у scrollable-листа `onGestureEvent` — native-driver `Animated.event`
  (`{ nativeEvent: { translationY: gestureY } }`, форма v2) с `listener`. Сдвиг листа = `max(0, gestureY − pullFrom)`
  (`listPull`), складывается с `drag` и прогрессом открытия; скрим тоже от суммы. JS-`listener` считает
  `listPullStart` как раньше и пишет `pullFrom` только при смене: при передаче — точку передачи, при возврате выше
  неё — `NOT_PULLING` (лист стоит). Legacy `createHandler` ставит native-событие прямо на view
  (`ActionType.NATIVE_ANIMATED_EVENT`), а RN зовёт `listener` на JS (`AnimatedEvent.__getHandler`).
- Возврат: пружина `pullFrom` → последняя точка пальца — лист едет с того места, где стоит, без скачка; по
  окончании `pullFrom` паркуется. Тот же путь после отказа хоста закрыться (`holdCheck`). `pulledTo` больше не нужен.
- Открытие сбрасывает и `gestureY` / `pullFrom`.
- `BottomSheetLists.tsx`: пока лист тянут (`isPulled`), `onScroll` с y > 0 возвращает список в 0
  (`scrollTo` / `scrollToOffset`, `animated: false`); не `scrollEnabled`. `BottomSheetScrollView` сливает свой ref с
  внешним.
- Тесты: native-событие с одним `listener` и маппингом v2; пружина без скачка (60 → 60 сразу после отпускания →
  покой); список прижат к 0 только во время тяги; передача 90 − 40 = 50 — по-прежнему. Тестовый `move` повторяет
  телефон: пишет значение маппинга, затем зовёт обработчик.

Проверка: `npx tsc --noEmit`, `npx eslint .` — чисто; `npx jest --no-watchman` — 176 наборов, 1617 тестов, зелёные;
v3 в `src` нет.
