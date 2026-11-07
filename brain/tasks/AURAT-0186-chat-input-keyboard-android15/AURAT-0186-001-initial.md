# AURAT-0186-001 — initial

Дата: 2026-11-07. Слот: `aura-app-manor` slave-0, ветка `feature/AURAT-0186-chat-input-keyboard-android15`
от `develop` @ `1bf1943`. Запуск — координатор slave-1-ac по просьбе владельца.

Владелец (дословно): «проведи анализ положения инпута для ввода на скрине чата с адвайзором, нашелся кейс,
когда клавиатура скрывает его. Google pixel 10, 17 android».

Скрин: тред с Olivia Flores, клавиатура (Gboard, укр.) открыта, композера над клавиатурой нет — он под ней.
Копия скрина: `AURAT-0186-screen-pixel10-android17.jpg` рядом.

Гипотеза координатора (проверить, не принимать на веру): targetSdk 36 → на Android 15+ edge-to-edge
принудительный, `edgeToEdgeEnabled=false` в gradle.properties его не отменяет; при edge-to-edge
`adjustResize` не сжимает окно, `KeyboardAvoidingView` в `ChatThreadScreen` не поднимается. На A50
(Android 11) поле видно. Проверить и другие экраны с KAV: phone-auth, verify-otp, edit-profile,
write-review, shared/ui/bottom-sheet. Связанное: AURAT-0172, react-native-safe-area-context 5.8.

Порядок: анализ и спека → одобрение владельца → реализация. Слейв без Metro/эмулятора; проверка на
Android 15+ — в маноре после мёржа. Ход задачи — координатору slave-1-ac.
