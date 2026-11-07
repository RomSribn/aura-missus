# AURAT-0197-004 — context

Код — `slave-3/master` @ `92c9694` (ground truth).

## Контракты v0.31.0 (клон `aura-contracts`, тег `v0.31.0`)
- `Message.translation?: MessageTranslation` — `pending | translated(content) | failed`, у каждого `language`;
  `.catch(undefined)`. Только у `direction: 'advisor'`.
- `HistoryQuery.translatedFrom` → `HistoryResponse.translations?: MessageTranslationUpdate[]` (`messageId`,
  `translation`); предел — «как у `deletedIds`» (в приложении `DELETED_IDS_PAGE = 200`).
- WS `message.translated { advisorId, messageId, translation }` (`translated | failed`), пуша нет.
- `ProfileResponse.chat?: ChatSettings { language, translationEnabled, consent: { version, givenAt } | null }`;
  `PATCH /v1/me/chat-settings` (`ChatSettingsPatchRequest` `.strict()`: `consentVersion ≤ CHAT_CONSENT_VERSION`,
  `translationEnabled`) → `ProfileResponse`; `409 chat_consent_required`; версия новее серверной → `400`, клиент
  тогда «оставляет перевод выключенным и чат не блокирует».
- `language.ts` / `SendMessageRequest`: `?lang` отправки пишет язык чата; клиент без выбора языка его не шлёт.

## Приложение
- `features/chat/model/ChatProvider.tsx` (1202 строки): `mergeServerMessages` **пропускает уже известные id** —
  обновлённый перевод известного сообщения сейчас потерялся бы; WS `switch` — `message.new / deleted / typing /
  presence / session.updated`; `readThread` — `after` + `deletedFrom`, раунды удалений `DELETION_ROUNDS_MAX = 5`
  (образец для раундов переводов). Смена языка режет треды (`AURAT-0172`) — переводу это не мешает: сравнение языка
  делается при рендере.
- `features/chat/lib/map-message.ts` — DTO → `ChatMessage`; `lib/preview.ts` `previewOf(message)` берёт
  `message.text`; `ui/MessagePreview.tsx` — Home `ContinueChatCard` и Chats `ChatListRow`.
- `screens/chat-thread/ui/MessageBubble.tsx` — `React.memo`, текст + мета-строка (время); место для подписи —
  мета-строка пузыря советника. `ChatInputBar` + `use-chat-thread.send` — место для галочки и запрета отправки.
- `shared/api/bff/http-client.ts:62` и `upload.ts:79` — `?lang` на **каждом** запросе (`withLanguage`), без опции
  его снять. Флаг — `I18N_ENABLED` (`shared/config/env.ts:127`); `LANGUAGE_CHOICE_AVAILABLE = I18N_ENABLED || __DEV__`
  — в `features/app-language` (недоступен фиче чата).
- `entities/user` — `profileStore` единственный владелец профиля (`save`, `uploadAvatar`, `removeAvatar` →
  `publish(toProfile(response))`); `toProfile` поле `chat` теряет.
- `screens/profile` — `ProfileMenu` (строки со стрелкой: promo, language, terms, privacy); `shared/ui` есть `Toggle`
  (52×31, teal) и `OptInRow`; чекбокса в `shared/ui` нет.
- Названия языков — `features/app-language/lib/language-names.ts` (`ownName`, `nameIn`), из index не экспортированы.
- Иконки: `check` есть (для галочки), `sparkle`, `globe`, `chat`.

## Противоречия / заметки
- `AURAI-0012` §7 предлагает подпись «Переведено», заглушка и спека контрактов — «Переведено ИИ». Беру «Переведено
  ИИ» (AI Act ст. 50, legal: «пометка снимает вопрос»).
- Для «другого языка» §7 — «Переведено на …», §2 — «переключатель работает». Решение 2 спеки.
- Блокирует ли неотмеченная галочка отправку — источники не говорят. Решение 1 спеки.
- Дизайн-макетов для подписи, галочки и переключателя нет — спека описывает словами, по токенам темы.
