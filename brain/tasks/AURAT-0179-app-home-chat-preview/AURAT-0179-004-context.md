# AURAT-0179-004 — context

Проверено по коду слота (`develop` @ `76bd8aa`):

- `screens/chats/lib/preview.ts` — `previewOf(message)` → `MessagePreview` (`text` / `attachment` / `spread` / `invite` /
  `system`); тесты `screens/chats/lib/__tests__/preview.test.ts` (111 строк). Импортирует только `@/features/chat`
  (`attachmentWordOf`, типы) и `@/shared` (`AuraIconName`) — переезд в `features/chat/lib` без новых зависимостей.
- `screens/chats/ui/ChatListRow.tsx:21-40` — `previewText(preview, t)`: `chat:attachment.*`, `chats:preview.spread|invite`,
  `chat:marker.preview.*`, системная строка с «— ». Иконка 13 / stroke 1.9 / `ink3` перед текстом, бейдж непрочитанного
  в той же строке после текста (`AURAT-0176`); текст жирнее при непрочитанном.
- `screens/chats/config/locales/*.ts` — `preview: { spread, invite }` в 24 языках; больше нигде не используются
  (`SAME_AS_ENGLISH`, `native-review.json`, glossary — ни одного упоминания).
- `features/chat/config/locales` — namespace `chat`: `marker`, `refused`, `draft`, `attachment`. Папки `ui/` у слайса
  пока нет.
- `screens/home/ui/ContinueChatCard.tsx:39` — `{lastMessage.text}`; `accessibilityLabel={t('continueChatLabel', {name})}`
  («Continue chat, Olivia Moon») **перекрывает детей**: превью голосом сейчас не читается вовсе. Аватар не скрыт —
  его инициал был бы прочитан, если убрать label (в `ChatListRow` он скрыт).
- Дизайн Home (`screens/07-home.png`, `prototype/screens.jsx:108-118`, README §Home): вторая строка карточки — только
  текст 12.5 `ink3`, места под глиф нет. Глиф превью описан только для строки Chats (`CHAT_ATTACHMENTS.md` §7).
- Тест Home `HomeScreen.test.tsx:216` — карточка с обычным текстом; хелперы `switchLanguage` / `backToEnglish` есть.

Противоречий нет.
