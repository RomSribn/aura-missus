# AURAT-0120-007 — реализация

Date: 2026-10-22

## Код (slave-1, `feature/AURAT-0120-sheet-swipe-dismiss`, не закоммичено)

- `shared/ui/bottom-sheet/drag.ts`:
  - `releaseDismisses(translationY, velocityY, sheetHeight)` — закрыть при отпускании или нет;
  - закрывает, если протянули больше 30 % высоты шторки (и не бросили обратно вверх быстрее
    1000 pt/s) или резко бросили вниз (≥ 1000 pt/s);
  - не закрывает, если отпустили выше начальной точки.
- `BottomSheet.tsx`:
  - `PanGestureHandler`, `activeOffsetY` 10 (тапы по кнопкам не перехватываются),
    `failOffsetX` ±20;
  - `Animated.event` с native driver на `drag`; `translateY = slide + drag`; вверх резиновое
    сопротивление, максимум 24 pt; затемнение `progress × (1 − drag / высота)`;
  - отпустили за порогом → `onClose()`, как тап по затемнению. Слайд-аут идёт от места, где
    отпустили. Если через 120 мс хост всё ещё `visible` (шторка удерживается, например во
    время оплаты), шторка пружиной возвращается;
  - до порога, CANCELLED или FAILED → возврат пружиной;
  - `GestureHandlerRootView` внутри `Modal`: на Android модалка — отдельное окно;
  - новый проп `dragFromGrip`: тянет только полоса grip (зона касания увеличена);
  - `onClosed`, `SHEET_HANDOFF_WAITS_FOR_CLOSE` и AURAT-0020 не тронуты.
- `CountryPickerSheet`: `dragFromGrip` — у неё прокручиваемый список.
- Остальные 9 шторок не менялись: свайп достался им через общий компонент.

## Тесты

- Новый `drag.test.ts`: 5 тестов на правило.
- `BottomSheet.test.tsx`, блок «swipe down»: длинный свайп → `onClose`, бросок → `onClose`,
  короткий → нет; при `dragFromGrip` контент вне жеста.
- tsc и eslint чистые; jest: 130 suites, 966 tests пройдены.

Дальше: APK из слота на A50, проверка владельцем.
