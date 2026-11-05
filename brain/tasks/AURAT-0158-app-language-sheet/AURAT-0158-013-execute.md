# AURAT-0158-013 — execute: свайп листа по списку (вариант 2) на API gesture-handler 3

Дата: 2026-11-05. Не закоммичено — ждёт ревью. Ветка та же, после мёржа `011`.

Владелец по ходу: «почему используем депрекейтед методы?» — первая версия была на `LegacyScrollView` /
`LegacyFlatList` (старый `PanGestureHandler` листа делит касание только со старыми списками). Решение владельца:
«Лист на новый API» — `BottomSheet` и его списки на v3 в этой задаче; остальные 4 места на старом API (таро
`SpreadStage`, `ZoomableImage`, `ProfilePhotoViewer` / `AdvisorHero` / `use-profile-motion` в advisor-profile) —
отдельной задачей.

## Что сделано

- `shared/ui/bottom-sheet/BottomSheet.tsx`: `PanGestureHandler` → `usePanGesture` + `GestureDetector`. Вне
  `scrollable` лист по-прежнему идёт за пальцем на UI-потоке (`Animated.event` с `useAnimated`, отображение
  `handlerData.translationY`). Отпускание — `onDeactivate` (`canceled` не закрывает), сброс — `onFinalize`.
  Проп `dragFromGrip` заменён на `scrollable`: тянется весь лист; касание, начатое на списке, тянет лист, только
  когда список в самом верху, и с этого места (`listPullStart` в `drag.ts`); касание на грипе или заголовке
  тянет лист всегда.
- `shared/ui/bottom-sheet/scroll.tsx` (новый): `BottomSheetScrollView`, `BottomSheetFlatList` — `ScrollView` /
  `FlatList` из gesture-handler 3 с `simultaneousWith: <жест листа>`, без overscroll (`bounces={false}`,
  `overScrollMode="never"`), сообщают листу касание и позицию. Экспорт через `@/shared`.
- Лист языка — `scrollable` + `BottomSheetScrollView`; выбор страны (`CountryPickerSheet`) — `scrollable` +
  `BottomSheetFlatList`.
- Тесты: `drag.test.ts` (+`listPullStart`), `BottomSheet.test.tsx` — жест через обработчик v3
  (`getByGestureTestId('bottom-sheet-pan')`): длинный / быстрый / короткий / отменённый свайп, закрытый лист не
  тянется; scrollable — с верха списка закрывает, прокрученный список не закрывает, довёл до верха → тянет с этого
  места, короткий после верха — назад, за грип — всегда, следующее касание с чистого листа. В тестах листа и
  профиля `JSON.stringify` дерева пропускает пропы связей жестов (мок кладёт жест в пропы хоста).

## Проверка

`npx tsc --noEmit`, `npm run lint` — чисто; `npx jest --no-watchman` — 176 наборов, 1610 тестов, все зелёные; новых
предупреждений в консоли нет.

## Открыто — только на устройстве (манор)

- Свайп на всех листах приложения (жест листа теперь v3): Top Up, промокоды, удаление аккаунта, отмена сессии,
  отзывы и т. д. — следует за пальцем без рывков, быстрый свайп закрывает, тап по кнопкам внутри не ломается.
- Лист языка и выбор страны: прокрутка списка; свайп вниз по списку с верха закрывает; прокрученный список сначала
  доезжает до верха, потом тянет лист; поиск страны с клавиатурой.
- Android (TalkBack/жесты) и iOS отдельно — согласование двух жестов платформенное.
