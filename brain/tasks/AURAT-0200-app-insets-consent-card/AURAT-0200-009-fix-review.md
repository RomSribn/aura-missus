# AURAT-0200-009 — fix review

2026-11-08, slave-0, та же ветка. Все замечания `008`. Не закоммичено, всё застейджено.

## Правки

1. **ro** — «ca conversația mea să fie tradusă automat».
2. **Шторка на Android ≤ 14 — свой avoider, не RN KAV.** `keyboard-avoider/use-legacy-keyboard-inset.ts` (новый):
   `keyboardDidShow` → `screenY`; `keyboardDidHide` → «клавиатуры нет», координаты hide не читаются; отступ =
   `keyboardOverlap(layout.y + layout.height, screenY)`, пересчёт и на `onLayout` (сжатие окна после события → 0); монтаж
   под открытой клавиатурой — `Keyboard.metrics()`. `KeyboardAvoider`: при `!isIOS && legacyAndroid === 'padding'` —
   `LegacyPaddingAvoider` (View + `onLayout`); iOS и `height` / без пропа — RN KAV, как было.
3. **«Клавиатура поднята»** — `children` у `KeyboardAvoider` может быть функцией `(raised) => …`: Android 15+ — `inset > 0`,
   ≤ 14 `padding` — показ без скрытия, iOS и KAV — `false` (iOS не меняется). `BottomSheet`: над клавиатурой
   `paddingBottom = theme.spacing.xl` (20), иначе `max(36, insets.bottom + 20)`.
4. **bg** — «любовен живот», «за моите гадаения».
5. **ga** — «…sonraí íogaire a roghnaím a roinnt sa chomhrá, mar shampla faoi shláinte, saol grá nó creideamh, le haghaidh
   mo léamha, agus go n-aistreoidh…».
6. **pl** «w swoim profilu»; **nl** «Ik kan de vertaling op elk moment uitzetten…»; **mt** «bħas-saħħa, il-ħajja romantika
   jew it-twemmin».
7. Тесты:
   - `bottom-bar-inset.test.tsx` (был `.ts`) — хук под `SafeAreaProvider initialMetrics`: Android 48 → 60, 0 → 26.
   - `toast/__tests__/Toast.test.tsx` (новый) — Android 48 → 144, 0 → 96, iOS 34 → 96.
   - `BottomSheet.keyboard.test.tsx` — + Android 15+ с моком `KEYBOARD_FRAMES` (кадр 500 → avoider `800 − 500`, шторка
     20; скрытие → 0 и 36), + Android ≤ 14 (не RN KAV; показ 500 → 300 и 20; скрытие со `screenY` 776 → 0 и 36).
   - `phone-auth/ui/__tests__/CountryPickerSheet.test.tsx` (новый) — тело `{ height: 70 % окна, flexShrink: 1 }`.
   - `KeyboardAvoider.test.tsx` — тип `render(legacyAndroid?: 'height' | 'padding')` + блок «Android 14-, a sheet» (6:
     не KAV, отступ по показу, 0 после сжатия окна по `onLayout`, 0 на hide при `screenY` 776, `raised` детям, отписка).
8. Комментарии: `Toast.tsx` (таб-бар растёт на `max(inset, 10) − 10`, над ним зазор шире ~10 pt, чем на 14);
   `use-chat-consent.ts` (без Anthropic / AI); `MessageBubble.translation.test.tsx` — «marked as machine-translated».

## Проверки в слоте

`npx tsc --noEmit` — 0; `npm run lint` — 0; `jest --no-watchman` — 249 наборов, 3307 тестов, все зелёные;
`translate.mjs check` по `chat-settings` — 0 запрещённых форм. Prettier — затронутые файлы чисты, кроме тех, что были
грязными на `develop` (мои строки в них — по prettier).

## В чек-лист манора (дополнение к `007`)

- A50, дата рождения: записать экран при открытии — нет ли прыжка на кадр (событие `keyboardDidShow` раньше, чем окно
  диалога сжалось: отступ = клавиатура на кадр, затем 0). Если прыгает — применять показ только после следующего за ним
  layout (отдельный шаг).
- A50: после закрытия клавиатуры шторка садится на низ экрана без зазора строки состояния.
- AVD API 36, 3 кнопки: над клавиатурой у шторки снизу 20, не 68.
