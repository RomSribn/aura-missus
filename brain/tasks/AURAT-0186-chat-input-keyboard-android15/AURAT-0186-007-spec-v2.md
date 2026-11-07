# AURAT-0186-007 — spec v2 (draft, ждёт одобрения владельца)

Заменяет `005`. Причина — `004` (с «Поправкой»), замечания — `006`.

## Механизм: `shared/ui/keyboard-avoider` (экспорт `KeyboardAvoider` из `@/shared`)

`<KeyboardAvoider style={…} legacyAndroid="height" | undefined>{…}</KeyboardAvoider>`

- **iOS** — как сейчас: RN `KeyboardAvoidingView behavior="padding"` (все семь мест на iOS уже `padding`).
- **Android ≤ 14** — как сейчас: RN `KeyboardAvoidingView behavior={legacyAndroid}` (тред и шторка — `undefined`,
  пять экранов — `'height'`). На A50 ничего не меняется.
- **Android 15+ (edge-to-edge)** — свой `View` без KAV:
  - `keyboardDidShow` → `measureInWindow` контейнера → `paddingBottom = max(0, y + height − endCoordinates.screenY)`
    (на показ `screenY` = верх клавиатуры, `ReactRootView.java:986-987`);
  - `keyboardDidHide` → `paddingBottom = 0` (координаты закрытия не используются — `006` п. 1);
  - при монтировании с уже открытой клавиатурой — то же по `Keyboard.metrics()`.
  Арифметика — чистая функция в `lib` слайса, подписка — хук в слайсе.
- Флаг `ANDROID_EDGE_TO_EDGE = !isIOS && Platform.Version >= 35` — внутри слайса (единственный потребитель),
  на `isIOS` из `shared/lib/styles.ts`. Комментарий: верно, пока `targetSdkVersion ≥ 35` и
  `edgeToEdgeEnabled=false`; при `true` — «весь Android».

## Где

1. **Тред** — `ChatThreadScreen.tsx:189`: `KeyboardAvoider` вместо KAV; комментарий над ним переписать.
2. **Пять экранов** — phone-auth, verify-otp, create-account, edit-profile, write-review: `KeyboardAvoider
   legacyAndroid="height"`. Чинит зазор после закрытия на Android 15+ (на develop уже есть).
3. **phone-auth, verify-otp — нижний край**: на Android `SafeAreaView edges={['top','bottom']}` (на ≤ 14 нижний
   инсет 0 — без изменений; на 15+ кнопка над панелью навигации). iOS — `['top']`, как нарисовано и сейчас.
4. **Шторка — условно.** Сначала в маноре на develop (Android 15+): поиск страны на phone-auth, `BirthDateSheet`.
   Поле видно — шторку не трогаем. Закрыто — отдельный шаг: `KeyboardAvoider` в `BottomSheet.tsx:626`.
   От чего зависит (в `004` открыто): (а) уважает ли система `setDecorFitsSystemWindows(true)` + `ADJUST_RESIZE`
   диалога при принуждении; (б) шлёт ли корень активности `keyboardDidShow/Hide`, пока фокус в диалоге.

## Тесты

- `keyboard-avoider/__tests__`: арифметика (показ → перекрытие; скрытие → 0; клавиатура ниже контейнера → 0);
  компонент на Android 35 — padding по `keyboardDidShow`, 0 по `keyboardDidHide` с `screenY = visibleHeight`;
  iOS / Android 34 — рендерит RN KAV с нужным `behavior` (`jest.isolateModules` +
  `Object.defineProperty(Platform, 'OS' | 'Version', { configurable: true })`, восстановление в `afterEach`).
- Тест-охрана сборки: читает `android/build.gradle` и `gradle.properties` — `targetSdkVersion ≥ 35`,
  `edgeToEdgeEnabled=false`; иначе сообщение «пересмотри ANDROID_EDGE_TO_EDGE».
- `ChatThreadScreen.test.tsx`: поле ввода внутри `KeyboardAvoider`.

## Известные ограничения (Android 15+)

- Без анимации: RN шлёт событие с `duration` 0 — поле прыгает; до или после выезда клавиатуры — смотрим в маноре.
- Высоту клавиатуры при открытой клавиатуре (панель Gboard, смена раскладки) не отслеживает: RN на API 30+
  шлёт событие только при смене видимости. Плавно и с отслеживанием высоты — только
  `react-native-keyboard-controller` (отдельная задача, решение владельца).

## Вне задачи (решение владельца)

- Белые иконки строки состояния на бумаге (Android 15+, все экраны после онбординга) — отдельная задача:
  тёмные иконки и полоса «бумага» вместе.
- `edgeToEdgeEnabled=true` для всех Android / keyboard-controller — после RN 0.86.

## Проверка в маноре (после мёржа)

Устройства: Pixel 10 владельца (Android 17), AVD `Galaxy_A16_API36` — по разу с жестами и с трёхкнопочной
навигацией; A50 (Android 11) — не регрессия.
0. До мёржа, на develop: шторки с полями (поиск страны, `BirthDateSheet`) — поле над клавиатурой или нет (п. 4).
1. Тред → тап в поле → поле и кнопка отправки над клавиатурой; то же с черновиком вложения, плашкой сессии,
   кнопкой «вниз».
2. Скрыть клавиатуру (назад / стрелка Gboard) → поле внизу, без зазора и не под панелью навигации.
3. Пять экранов: открыть клавиатуру → кнопка / поле над ней; скрыть → кнопка на месте, без зазора и не под
   панелью навигации (phone-auth, verify-otp — особенно).
4. Открыть панель Gboard (эмодзи / буфер) при открытом поле — записать, что видно (ограничение).
5. Момент прыжка поля относительно анимации клавиатуры — записать.
6. A50: всё то же, поведение как до задачи.

---
**Лёгкая проверка v2 (slave-1-ac, 2026-11-07): пройдена**, все 11 замечаний учтены. Деталь на реализацию:
мерить внешний `View` самого `KeyboardAvoider` (его `paddingBottom` не двигает рамку → измерение не зависит
от уже выставленного отступа); тест — повторный `keyboardDidShow` при выставленном padding даёт тот же отступ.

---
**Поправка (`010`, ревью кода slave-1-ac):** мерим не `measureInWindow`, а `measure` (`pageY + height`). На Android
`measureInWindow` прибавляет `viewportOffset` корня = `locationOnScreen − visibleFrame.top` (`ReactSurfaceView.kt:48-60`),
при edge-to-edge это −строка состояния → отступ был меньше нужного на её высоту.
