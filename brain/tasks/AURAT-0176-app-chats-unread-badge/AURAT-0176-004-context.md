# AURAT-0176-004 — context

## Веб (`aura-web` develop @ `154c842`) — образец

- `entities/message/model/chat-live.ts`: `unread: Record<advisorId, number>`, `viewing: string | null`.
  `advisorMessagesArrived({advisorId, count})` — `count > 0 && viewing !== advisorId` → `+count`;
  `threadOpened` — `viewing = id`, счётчик удалён; `threadClosed` — `viewing = null`; `chatLiveReset` — всё.
- Что считается (`chat-sync.ts`): `message.new` с `direction === 'advisor'` (тред не в кэше → 1); догон `after`
  только по треду, который уже в кэше (`countNewFromAdvisor` — новые по id, `direction === 'advisor'`).
  **Первое чтение треда (без курсора) не считается** — это история, а не новое.
- Тред на экране = смонтирован `use-chat-thread` (на скролл не смотрит). Удаление сообщения столом счётчик не уменьшает.
- Строка (`widgets/conversation-list`): справа в строке превью — коралловая «таблетка» с числом (min-width 18, h 18,
  radius 9, `--accent-strong` #DA3557, белый 700 11/18), превью при непрочитанном — `--ink` 600; число `aria-hidden`,
  рядом скрытый текст `unread_one/_other` «{{count}} new message(s)». Предела «99+» нет.
- Навигация (`app-layout` `UnreadBadge`): число **диалогов** с непрочитанным (`selectUnreadConversations`), только
  вошедшему; скрытый текст `nav.unread_*` «{{count}} conversation(s) with new messages». На узком экране — поверх иконки
  (absolute, top 2 / right 0).

## Приложение (`develop` @ `cffdbf5`) — что есть

- `features/chat/model/ChatProvider.tsx` — единственный владелец сообщений: `mergeServerMessages` (сокет `message.new`,
  догон `readThread` с курсором `lastServerIds`, пинг FCM, `AppState active`, `onOpen` сокета), `removeServerMessages`,
  сброс всего по смене `userUid` (эффект с `epoch`). Первое чтение треда идёт без курсора (`after === undefined`).
  Курсор `lastServerIds` двигает и своя отправка (`deliver`).
- `screens/chats/model/use-chats.ts` → `ChatListRow` (memo): строка превью — иконка + текст `ink3`; справа в
  заголовке — время. Места под число — в строке превью справа, как в вебе.
- `app/navigation/AuraTabBar.tsx` — свой бар, только иконки (25 px) + точка активной вкладки (цвет сезона);
  `accessibilityLabel` из `app:tabs.*`. `tabBarBadge` не применим — бар свой.
- `screens/chat-thread/model/use-chat-thread.ts` — экран треда; точка «писал советник, пока ты не внизу» —
  `use-thread-scroll.ts` (маркеры сессии и свои сообщения её не зажигают).
- Пуш: `features/push/model/notification-taps.ts` — холодный старт из пуша открывает тред (`openThread`).
- Тема: `accent` #EC5F73 (белый текст на нём ≈ 3,3:1), токена «strong» нет. В дизайне `11-chats-list` счётчика нет.
- Сезон (`SEASONAL.md` §5) красит только активную иконку и точку — бейдж не из пяти мест сезона.

## Расхождения / решения владельцу

1. Что такое «визит» в приложении: жизнь процесса (как веб, Б) или отметка на устройстве (В).
2. Тред открыт, но человек читает старые страницы — считать ли (веб: нет).
3. Удалённое столом непрочитанное — уменьшать ли счётчик (веб: нет).
4. Цвет бейджа: `accent` приложения (≈3,3:1 с белым) или новый токен `accentStrong` #DA3557, как в вебе (≈4,5:1).
