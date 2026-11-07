# AURAT-0197-011 — fix по code review (`010`)

Дата: 2026-11-08 · slave-3, всё застейджено, **коммитов нет**.

## Правки
1. **Повтор и согласие** (`use-chat-thread.ts`): `retry` выходит при `consent.required`; экран получает `retry` =
   `undefined`, пока нужна галочка, — у пузыря нет кнопки повтора, а подпись — «Not delivered» без «Tap to resend»
   (`MessageBubble.deliveryMeta` пишет «Tap to resend» только когда повтор возможен).
2. **Профиль после ошибки** (`use-chat-consent.ts`): при монтировании (открытие треда) и при `AppState → active` —
   `profileStore.load()`, если `status === 'error'`; у готового профиля — ничего.
3. **409 у переключателя**: профиль перечитывается **и** `failed` — строка ошибки, не молчаливый откат.
4. **Быстрые нажатия**: `pending` — пока запрос в пути, `set` ничего не делает (ref, не состояние — второй тап до
   рендера тоже отсекается); строка в `ProfileMenu` `disabled`, `accessibilityState.busy`. Ответы в обратном
   порядке больше невозможны.
5. **Озвучка ошибки переключателя**: `AccessibilityInfo.announceForAccessibility(switch.failed)` при переходе в
   `failed` (оба платформы; live region у вложенного текста в строке-кнопке Android не зачитывает).
6. **Поздние переводы** (`ChatProvider`): `message.translated` / `translations` для сообщения, которого тред ещё не
   держит, кладутся в `lateTranslations` (до `LATE_TRANSLATIONS_MAX = 50` на тред, старейший вытесняется) и
   применяются через `mergeTranslation`, когда сообщение приходит (синк, старая страница). Сбрасывается при смене
   аккаунта.
- **Двойное нажатие на галочку**: тоже ref-охрана.
- **Пробел §3/§7**: у кнопки «Show» (`elsewhere`) — `accessibilityLabel` `translation.showLabel` «Show the
  translation, {{language}}» (язык своим именем после запятой), 24 языка.

## Тесты (добавлено)
- `ChatProvider.translation`: предел `TRANSLATION_ROUNDS_MAX`; ответ раунда после смены аккаунта не применяется;
  переводы из `refreshSpreads`; повторный `message.new` известного не трогает непрочитанные; событие раньше
  сообщения — применяется при приходе, позднее `pending` не откатывает; предел карты — старейший вытеснен.
- `use-chat-consent`: перечитывание при открытии и при foreground; двойное нажатие; уход с экрана во время
  запроса; 404 — отдельный файл `use-chat-consent.absent.test.tsx` (отказ живёт весь запуск).
- `use-translation-switch`: 409 → `failed`; второй `set` во время запроса игнорируется; озвучка ошибки.
- `ChatThreadScreen.consent`: неотправленное сообщение без кнопки повтора и без «Tap to resend», пока нужна
  галочка.
- `ChatThreadScreen.translation` (новый): «Original anzeigen» через `use-chat-thread` — один ответ переворачивается
  и обратно, второй остаётся переводом.
- `MessageBubble.translation`: псевдоязык читается как английский; `accessibilityLabel` кнопки «Show».

## Проверки
- `npm run lint` (`--max-warnings 0`) — чисто; `npx tsc --noEmit` — чисто.
- `npx jest --no-watchman` — **245 наборов, 3283 теста**, все зелёные.
- `translate.mjs check` — 0 запрещённых форм (243 совета — те же ложные: `{{language}}`, падежи).
