# AURAT-0120-004 — контекст

Date: 2026-10-22

## Код (ground truth)

- `shared/ui/bottom-sheet/BottomSheet.tsx`: core RN `Modal` (`transparent`,
  `animationType="none"`), свой слайд на `Animated` (320 мс, bezier .22/1/.36/1, выход 200 мс)
  и затемнение. Закрывается тапом по затемнению и через `onRequestClose`. Свайпа нет.
  - `onClosed` и `SHEET_HANDOFF_WAITS_FOR_CLOSE` — передача между шторками (AURAT-0020,
    AURAT-0119).
- Шторки, 10 штук:
  - без прокрутки и полей ввода: QuickBook, SessionBlock, TopUp, DeleteAccount, PhotoSource,
    AttachmentSource, CancelSession;
  - `BirthDateSheet` — поля ввода (клавиатура);
  - `CountryPickerSheet` — список с прокруткой и поле поиска: тут конфликт свайпа шторки и
    прокрутки.
- Зависимости:
  - уже стоят `react-native-gesture-handler` 3.0.1, `react-native-screens` 4.25.2; новая
    архитектура (Fabric) включена;
  - `react-native-reanimated` не установлен.
- Готовый паттерн в проекте: `PanGestureHandler` + `Animated.event` с native driver
  (`ZoomableImage`, `ProfilePhotoViewer`, тарот). `ImageViewer` уже закрывается свайпом вниз
  (PanResponder, порог 25 %).
- Навигация на `@react-navigation/stack` (JS stack), native-stack не используется.
- Xcode 26.6, RN 0.85.3.

## Дизайн

`MOTION_AND_ICONS.md`:
- шторки закрываются тапом по затемнению, кнопкой или свайпом вниз («gorhom gives you the
  swipe»);
- рекомендована `@gorhom/bottom-sheet`;
- тайминг: 320 мс, cubic-bezier (.22, 1, .36, 1), затемнение 200 мс.

## Варианты (веб, 2026)

1. **TrueSheet** (`@lodev09/react-native-true-sheet` v3, только Fabric, RN 0.81+, Xcode 26.1+).
   Нативные шторки: iOS UISheetPresentationController, Android BottomSheetDialog. Свайп,
   клавиатура, a11y и Liquid Glass на iOS 26 даёт система, до 3 detents. Сейчас это
   рекомендуемый путь к «настоящей нативной» шторке.
2. **react-native-screens formSheet**. Шторка — это экран native-stack. На Android
   `fitToContents` пока экспериментальный (FormSheet v5 в 4.26). У нас JS stack, а шторки —
   компоненты, а не экраны, так что пришлось бы переписать навигацию.
3. **@gorhom/bottom-sheet** (указан в дизайн-хендоффе). Тянет `react-native-reanimated`
   (у нас его нет) и плотно завязан на reanimated и gesture-handler: известная причина
   блокировок при апгрейдах.
4. **Свой жест на нашем `BottomSheet`** (gesture-handler уже стоит, паттерн в проекте есть).
   Шторка идёт за пальцем, закрывается по порогу или по скорости, иначе возвращается пружиной.
   Одинаково на iOS и Android, без новых зависимостей. Сохраняются дизайн-тайминги и вся
   логика передачи между шторками.
5. RN `Modal presentationStyle="pageSheet"`. Нативный свайп есть только на iOS, но шторка
   почти во весь экран, а не по контенту. Не подходит.

Источники:
- https://reactlibs.dev/articles/true-sheet-native-bottom-sheets/
- https://sheet.lodev09.com/
- https://reactnavigation.org/docs/native-stack-navigator
- https://newreleases.io/project/github/software-mansion/react-native-screens/release/4.26.0
- https://www.pkgpulse.com/guides/gorhom-bottom-sheet-vs-expo-bottom-sheet-vs-rnsbs-2026
- https://github.com/Pkcarreno/cron/issues/47
