# AURAT-0179-007 — execute

Дата: 2026-11-07. Слот slave-3, ветка `feature/AURAT-0179-app-home-chat-preview` (не закоммичено, всё в индексе слота).
По спеке `005` v2, решения `006` (голос — А, глиф на Home — нет).

## Файлы (aura-app, 80 файлов)

- `features/chat/lib/preview.ts` ← `screens/chats/lib/preview.ts` (git mv): тип `MessagePreview` → `PreviewContent`,
  импорты относительные (`../model/types`, `./attachment-name`), JSDoc типа — про оба места.
- `features/chat/lib/__tests__/preview.test.ts` ← `screens/chats/lib/__tests__/` (git mv), импорт `../../model/types`.
- `features/chat/ui/MessagePreview.tsx` — новый: фрагмент «глиф (по `withIcon`) + `<Text numberOfLines={1}>`», слова —
  бывший `previewText` из `ChatListRow`, `useTranslation('chat')` внутри.
- `features/chat/index.ts` — `+ MessagePreview`; `− attachmentWordOf`, `− AttachmentWord` (потребителей вне слайса нет).
- `features/chat/config/locales/*.ts` — `preview.spread|invite` (23 языка дословно из `chats`); `en.ts` — JSDoc
  `preview`, `attachment`, `marker.preview`, шапка — оба места; `index.ts` — комментарий `chatI18n`.
- `screens/chats/config/locales/*.ts` — `preview` удалён (24); шапка `en.ts` — где теперь слова превью.
- `screens/chats/ui/ChatListRow.tsx` — `<MessagePreview withIcon …/>`, `useTranslation('chats')`; `screens/chats/lib/`
  удалена.
- `screens/home/ui/ContinueChatCard.tsx` — `<MessagePreview …/>` без глифа; без `accessibilityLabel`,
  `accessibilityHint={t('continueChatHint')}`; аватар в обёртке `accessibilityElementsHidden` +
  `importantForAccessibility="no-hide-descendants"`.
- `screens/home/config/locales/*.ts` — `continueChatLabel` → `continueChatHint` (24; переводы — дословно `chats:row.hint`).
- `screens/home/ui/__tests__/HomeScreen.test.tsx` — `describe('the continue-chat preview')` на немецком: приглашение,
  расклад, фото без подписи, отметка `started`, текст; голос — нет label, читаются «Olivia Moon», «Einladung zur privaten
  Sitzung», hint «Öffnet den Chat». Деревья размонтируются в `afterEach` (иначе act-предупреждения от сброса сторов).

## Проверка

- `npx tsc --noEmit` — 0 ошибок; `npm run lint` — 0.
- Jest весь (`--no-watchman`) — 221 suites / 3035 tests, всё зелёное.
- `translate.mjs check` — 0 avoided; советы по `chat:preview.*` и `home:continueChatHint` — те же, что были у этих
  строк в `chats` (переводы не менялись).

## Открыто

Живая проверка в маноре после мёржа (A50) — список в `005` «Тесты». Коммит и мёрж — по одобрению владельца.
