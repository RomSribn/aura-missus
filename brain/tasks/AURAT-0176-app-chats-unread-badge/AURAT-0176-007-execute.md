# AURAT-0176-007 — execute

2026-11-07, slave-2, ветка `feature/AURAT-0176-app-chats-unread-badge` (от `develop` @ `cffdbf5`). По спеке `005` v3.
Всё в stage, не закоммичено — ждёт ревью владельца.

## Что сделано

- `features/chat/model/ChatProvider.tsx` — непрочитанное: ref `Record<advisorId, Set<messageId>>` + зеркало счётчиков
  в state; `noteUnread` (только `direction === 'advisor'`, нет в треде и в `deletedServerIds`, тред не читается);
  `mergeServerMessages(…, countUnread)` — сокет `true`, `readThread` — `countUnread` решается один раз до `await`
  (`lastServerIds` пуст и `firstSync !== 'done'` — история); `removeServerMessages` убирает id; сброс при смене
  `userUid`. `threadReading` / `threadLeft` на ref (`threadLeft` чистит только свой id). Два контекста:
  `useChatUnreadSummary()` (`unreadThreads`, действия) и `useChatUnread()` (`unreadOf`); экспорт в `index.ts`.
- `screens/chat-thread/model/use-thread-scroll.ts` — `atBottom`; при смене `advisorId` на том же экране — зона
  `bottom`, точка «вниз» гаснет, лента к новейшему.
- `screens/chat-thread/model/use-chat-thread.ts` — эффект `[advisorId, focused && atBottom]` → `threadReading` /
  `threadLeft`.
- `screens/chats` — `unread` в `ChatListItem` и `ChatListRow`: `CountBadge` в конце строки превью, превью `ink` 600.
- `app/navigation/AuraTabBar.tsx` — обёртка иконки 25, бейдж (`ring`) у Chats, `accessibilityValue.text`.
- `shared/ui/count-badge` — `CountBadge` (без `height`, `minWidth = minHeight` 18, `radius.pill`,
  `maxFontSizeMultiplier` 1.3, опция `ring` — обводка 2 pt `paper`). `theme.ts`: `colors.accentStrong` #DA3557
  (с комментарием: кнопки и OffChip остаются на `accent`), блок `countBadge`.
- Строки: `chats:row.unread_*`, `app:tabs.chatsUnread_*` — 24 языка, переводы из веба (`translate.mjs scan`,
  `conversation-list:unread`, `app:nav.unread`), плюралы веба (у ga / mt / sl — с `_two`). JSDoc «только голос».

## Тесты

Новые: `ChatProvider.unread.test.tsx` (13), `ChatThreadScreen.unread.test.tsx` (3; тест «тред поверх треда» падает
без сброса зоны — проверено), `CountBadge.test.tsx` (3); дополнены `ChatListRow.test.tsx` (+4), `AuraTabBar.test.tsx`
(+4, `@/features/chat` замокан).
`npm run lint` — чисто, `tsc --noEmit` — чисто, Jest — 221 сьюта, 3022 теста, всё зелёное.
`translate.mjs check` — замечаний к новым ключам нет.

## Открыто

- Живая проверка (A50, крупный шрифт, сезонная иконка) — в manor после мёржа.
- Мелочь вне задачи: при открытии треда поверх треда `use-thread-scroll` не сбрасывает «что пришло» (`seen`) —
  поведение 0172, здесь не трогал.
