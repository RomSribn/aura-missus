# AURAT-0200-008 — review

2026-11-08. Ревью кода координатора (3 ревьюера, серьёзное перепроверено отдельно). Владелец: «Передавай все
(Recommended)». Чисто: нижние отступы, токены, iOS и A50 для футеров (по коду safe-area-context 5.8.0); тесты шторок
(9 / 126) и промо / даты / языка (6 / 47) зелёные.

Серьёзное:
1. **high** `chat-settings/locales/ro.ts` — «această conversație» = «этот разговор», сужает согласие (оно на аккаунт) до
   треда → «conversația mea».
2. **medium, A50** `BottomSheet.tsx` `legacyAndroid="padding"` — RN KAV на Android держит `keyboardDidHide` и считает от
   его `screenY` (высота видимой области без строки состояния) → после закрытия шторка приподнята на ~24 dp. Нужен свой
   маленький avoider: show — запомнить `screenY`; hide — 0, `screenY` из hide не брать; отступ = overlap(`layout.y +
   height`, `screenY`) на show и в `onLayout` (окно диалога может сжаться после события → 0). В чек-лист A50: запись
   экрана с датой рождения — нет ли прыжка на кадр; если есть — показ применять после следующего layout.

Мелочи:
3. Android 15+ с кнопками: у шторки над клавиатурой `paddingBottom` = max(36, 48 + 20) = 68 dp пустоты. Avoider сообщает
   «клавиатура поднята» → отступ `theme.spacing.xl` (20).
4. bg: «личен живот» → «любовен живот»; «гадания» → «гадаения» (глоссарий).
5. ga: цель после объекта, мн. ч.: «…sonraí íogaire a roghnaím a roinnt sa chomhrá, mar shampla faoi shláinte, saol grá
   nó creideamh, le haghaidh mo léamha, agus go n-aistreoidh…».
6. pl «w moim profilu» → «w swoim profilu»; nl «Ik kan de vertaling op elk moment uitzetten…»; mt «bħas-saħħa,
   il-ħajja romantika jew it-twemmin».
7. Тесты: хук с `SafeAreaProvider initialMetrics` (Android 48 → 60); Toast (Android 48 → 144, iOS 96); BottomSheet —
   Android 35 с моком `KEYBOARD_FRAMES` (500 → высота − 500, затем 0), Android 30 `padding` show / hide, тело
   `CountryPickerSheet` = `{ height, flexShrink: 1 }`; тип `render(legacyAndroid)` в `KeyboardAvoider.test.tsx` +
   `'padding'`.
8. Комментарии: `Toast.tsx` (таб-бар растёт на max(inset, 10) − 10, над ним на ~10 dp больше зазор, чем на 14);
   `use-chat-consent.ts:37` (без Anthropic / AI); `MessageBubble.translation.test.tsx:74` «marked as AI».

Не здесь: альбомная ориентация на Android 15+ (боковой инсет футеров) — координатор в бэклог.

Дальше — `009` правки.
