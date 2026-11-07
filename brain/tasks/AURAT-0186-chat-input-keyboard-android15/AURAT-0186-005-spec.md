# AURAT-0186-005 — spec (draft, ждёт одобрения владельца)

Тип: задача (фичи не нужно). Причина и разбор — `AURAT-0186-004-context.md`.

## Что сделать

1. **Один источник правды для «окно edge-to-edge»** — `shared/config/platform.ts` (экспорт из `@/shared`):
   - `ANDROID_EDGE_TO_EDGE = Platform.OS === 'android' && Platform.Version >= 35` — с комментарием: верно,
     пока `targetSdkVersion ≥ 35` (сейчас 36); при `edgeToEdgeEnabled=true` станет `Platform.OS === 'android'`.
   - `KEYBOARD_AVOIDING_BEHAVIOR` = `'padding'` на iOS и на Android 15+, `undefined` на Android ≤ 14
     (там окно сжимает `adjustResize`, а KAV поверх даёт подскок на кадр — `004`).
2. **Тред** (`ChatThreadScreen.tsx`): `behavior={KEYBOARD_AVOIDING_BEHAVIOR}`; комментарий над KAV
   переписать — почему Android ≤ 14 без поведения, а 15+ с ним. iOS — без изменений.
3. **Шторка** (`BottomSheet.tsx`): то же. Если диалог `Modal` на Android 15+ всё-таки сжимается системой,
   формула KAV даёт 0 — двойного подъёма не будет (кроме возможного подскока на кадр; смотрим в маноре).
4. **Пять экранов с `'height'`** — не трогаю, только проверка в маноре.
5. Тест: `platform.test.ts` — значения констант для iOS / Android 34 / Android 35.

Чего нет: `edgeToEdgeEnabled=true`, `react-native-keyboard-controller`, цвет иконок строки состояния — см.
«Альтернатива» и «Находка» в `004`; по ним — решение владельца, отдельными задачами.

Известное ограничение: на Android поле встаёт над клавиатурой рывком, когда она уже выехала (RN шлёт
`keyboardDidShow` с `duration` 0). Плавно, как на iOS, — только с keyboard-controller.

## Проверка в маноре (после мёржа)

Устройство или эмулятор Android 15+ (Pixel / AVD API 35 и 36), плюс A50 (Android 11) — не регрессия.
1. Тред с советником → тап в поле → поле и кнопка отправки над клавиатурой, последнее сообщение видно.
2. То же с черновиком вложения (полоса над полем) и с плашкой сессии; кнопка «вниз» над полем.
3. Скрыть клавиатуру (жест «назад» / стрелка Gboard) → поле внизу, без зазора.
4. Шторки с полями: выбор страны (поиск) на phone-auth, `BirthDateSheet` на Home.
5. Экраны с `'height'`: phone-auth, verify-otp, create-account, edit-profile, write-review — поле/кнопка
   над клавиатурой.
6. A50: всё то же, поле не подпрыгивает.
