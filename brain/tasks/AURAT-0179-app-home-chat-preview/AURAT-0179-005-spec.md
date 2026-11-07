# AURAT-0179-005 — spec (v2, draft)

Тип: задача (без новой фичи), фича — `AURAF-0023`. Контекст — `004`.
v2 — ревью координатора slave-1-ac (2026-11-07): п. 1–3 «исправить», 4–6 «мелочи», факты к решениям 1 и 2 — внесены.

## Что видит человек

1. **Карточка Home «Continue your chat»** — вторая строка говорит то же, что строка этого диалога в Chats, на языке
   приложения:
   - приглашение в сессию → «Einladung zur privaten Sitzung» (а не «Continue this reading privately»);
   - расклад → «Tarot-Legung» (а не «Choose a card»);
   - фото / видео / голосовое без подписи → «Foto» / «Video» / «Sprachnachricht»; документ — имя файла;
     вложение с подписью — подпись;
   - отметка начала / конца сессии → «— Deine Sitzung hat begonnen» (с тире, как в Chats);
   - обычный текст — как есть.
   Глиф — по решению 2. Шрифт, размер, цвет строки — как сейчас; длинное обрезается «…» в одну строку.
2. **Chats** — без изменений (тот же текст, глиф, бейдж, жирность при непрочитанном).
3. **Голос на Home** (решение 1 — **А**, владелец): карточка без `accessibilityLabel`, читается нарисованное —
   «Olivia Moon, <превью>, кнопка, Opens the chat» (iOS собирает детей через «, », Android — `getTalkbackDescription`,
   RN 0.85.3). Инициал аватара не читается. «В сети» на Home не звучит ни сейчас, ни после — точка присутствия на
   аватаре без подписи (`Avatar.tsx:60`); если нужно — отдельная правка.

## Как (код)

- **`features/chat/lib/preview.ts`** — `previewOf` переезжает из `screens/chats/lib/preview.ts`, комментарии как есть.
  - Тип `MessagePreview` → **`PreviewContent`** (имя `MessagePreview` занимает компонент; JSDoc и тесты — за ним).
  - Импорты — **относительные** внутри слайса (иначе цикл `index.ts → ui → lib → index.ts`):
    `{ AttachmentWord, attachmentWordOf } from './attachment-name'`, `{ ChatMessage, SessionMarkerKind } from
    '../model/types'`, `AuraIconName` — из `@/shared`.
  - Тесты — `features/chat/lib/__tests__/preview.test.ts`, без изменений, кроме импортов (`ChatMessage` из
    `'../../model/types'`, как `replace-spreads.test.ts:3`).
  - Наружу (`index.ts`) не экспортируются — их потребитель только компонент ниже.
- **`features/chat/ui/MessagePreview.tsx`** — компонент `MessagePreview`
  `{ message: ChatMessage; style?: StyleProp<TextStyle>; withIcon?: boolean }`: фрагментом (строка-родитель держит
  свою раскладку) — глиф 13 / 1.9 / `ink3`, если `withIcon` и он есть у превью, и `<Text numberOfLines={1}>` со
  словами. Слова — нынешний `previewText` из `ChatListRow`; `useTranslation('chat')` — в самом компоненте
  (перерисовка на смену языка). Экспорт — `features/chat/index.ts`.
- **`features/chat/index.ts`** — `attachmentWordOf` и тип `AttachmentWord` из экспорта **убираются**: их единственный
  потребитель вне слайса уезжал внутрь (правило 5). `nameOfAttachment`, `SessionMarkerKind` остаются (потребители в
  `screens/chat-thread`).
- **Строки**: `chats:preview.spread|invite` → `chat:preview.spread|invite`, 24 языка дословно (из
  `screens/chats/config/locales/<lang>.ts` в `features/chat/config/locales/<lang>.ts`); из `chats` — удаляются.
  Новых переводов нет. JSDoc в `chat/en.ts`, которые теперь видит и Home, называют оба места — строка Chats после
  глифа и строка карточки Home «Continue your chat», 12,5 pt, одна строка, «…»: `preview.*` (новое), `attachment.*`
  (en.ts:65-69), `marker.preview.*` (en.ts:27), шапка en.ts:1-7 и комментарий `chatI18n` (`locales/index.ts:11`).
- **`ChatListRow`** — `previewText`, `previewOf` и глиф уходят; на их месте
  `<MessagePreview message={lastMessage} withIcon style={[styles.preview, unread > 0 && styles.previewUnread]} />`
  внутри той же `previewRow` перед бейджем. `screens/chats/lib/` пустеет — удаляется.
- **`ContinueChatCard`** — `<MessagePreview message={lastMessage} style={styles.preview} />` вместо `lastMessage.text`.
  Голос (А): `accessibilityLabel` убирается, `accessibilityHint={t('continueChatHint')}`; обёртка аватара —
  `accessibilityElementsHidden` + `importantForAccessibility="no-hide-descendants"`, как `ChatListRow.tsx:76-79`.
  Строки `home`: `continueChatLabel` удаляется (24 языка), `continueChatHint` добавляется — переводы 24 языков
  дословно из `chats:row.hint` (та же английская фраза «Opens the chat»).
  Если решение 2 — глиф: своя строка-обёртка (`row`, `alignItems: 'center'`, `gap: 6`, `minWidth: 0`), `flexShrink: 1`
  у текста, глиф под 12,5 pt — родитель `styles.body` колонка, фрагмент встал бы над текстом.

## Тесты

- `features/chat/lib/__tests__/preview.test.ts` — переехавшие тесты `previewOf`, зелёные как есть.
- `ChatListRow.test.tsx`, `ChatsScreen*.test.tsx` — без правок, зелёные (поведение Chats то же).
- `HomeScreen.test.tsx` — новый `describe` на немецком: приглашение (`text: 'Continue this reading privately'` +
  `sessionInvite`), расклад (`'Choose a card'` + `spread`), фото без подписи, отметка `started`, обычный текст — на
  экране слово приложения, английской подписи сервера нет. Голос — по образцу `ChatListRow.test.tsx:137-172`: у
  карточки нет label, первым читается имя, потом превью, инициал аватара скрыт, есть hint.
- Проверка: `npm run lint`, `npm run typecheck`, весь Jest, `node scripts/i18n/translate.mjs check`.
- **Живая проверка в маноре после мёржа (A50)** — Home и Chats показывают одно и то же на языке приложения:
  - чаттер присылает `::SESSION::` и расклад;
  - фото и голосовое без подписи, фото с подписью;
  - отметки начала и конца сессии последним сообщением;
  - смена языка из dev-меню при открытом Home;
  - приглашение на de / el / ga — одна строка с «…»;
  - TalkBack (и VoiceOver, если есть iPhone) на карточке Home.

## Решения владельца

Состояние на 2026-11-07: решение 1 — **А**, решение 2 — **только слово** (владелец); спека одобрена (`006`). Ниже —
история обсуждения.

1. **Голос карточки Home** — **А** (выбрано): как у строки Chats, см. «Что видит человек» п. 3 и «Как» — `ContinueChatCard`.
   (Б — оставить label, превью голосом не слышно — отклонено.)
2. **Глиф на Home** (маленькая иконка 13 pt перед словом, как в Chats: фото — `image`, видео — `video`, голосовое —
   `mic`, документ — `doc`, расклад — `cards`, приглашение — `cal`; у текста и отметок — нет).
   - Дизайн об этом месте **молчит**: на `07-home.png` карточки нет (снимок кончается на «Top advisors»), прототип
     выводит сырой `.text` (`prototype/screens.jsx:113`) — тот самый баг, он старше вложений; глиф описан только для
     списка Chats (`CHAT_ATTACHMENTS.md` §7).
   - Ограничение — **ширина**: на 360 pt строка ~178 pt при 12,5 pt (≈ 28 знаков). Приглашение ga (36), el (30), de
     (30), hu (29) уже обрезается «…» без глифа; глиф съест ещё ~3 знака и потребует обёртку.
   - **Рекомендую без глифа** — длинные слова и так на пределе; с глифом — одна обёртка, тот же компонент.

## Не здесь

Веб (`AURAT-0170`), английская подпись в BFF (нужна старым версиям приложения), «в сети» голосом на Home, каталог
советников (`AURAT-0174`, slave-0).
