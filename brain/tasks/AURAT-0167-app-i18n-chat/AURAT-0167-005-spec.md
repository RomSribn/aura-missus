# AURAT-0167-005 — spec: чат на 24 языках

Тип: задача фичи `AURAF-0023` (шаг 3, задача 7 из 7), строка `AURAF-0023-003` (чат).
Status: draft, ред. 2 — учтено ревью slave-1-9e (14 замечаний, `wf-spec-0167-0168-review.md`, владелец: «да,
передавай»); вопросов к владельцу нет; ждёт одобрения владельца.

## Что получится

Человек с телефоном на любом из 24 языков видит на своём языке всё, что приложение само пишет в чате: список
чатов и пустой экран, шапку треда, поле ввода, вложения во всех состояниях (голос, видео, файл, фото, ошибки,
черновик, лист «Attach», просмотр фото), подписи доставки, приглашение на приватную сессию, продление сессии и
быструю бронь из чата, расклад таро и маркеры «Ваша сессия началась / завершилась». Чтец экрана говорит на том же
языке и слышит то, что видно (превью строки, текст неотправленного сообщения, ошибку черновика). Сами сообщения
советника и названия карт остаются как пришли (вне объёма). До запуска (шаг 4) — только в dev
(`AURA_I18N_ENABLED`).

## Объём

| Слайс | Namespace | Что |
|---|---|---|
| `features/chat` | `chat` (новый) | маркеры сессии — два набора ключей: для разделителя (капсом) и для превью (обычный регистр); 5 отказов сервера при отправке (`describeRefusal`); 6 ошибок черновика |
| `screens/chats` | `chats` (новый) | заголовок «Chats», «All advisors», пустой экран (заголовок, текст, Browse advisors), строка: «online» (середина строки, строчный), «Session live · N min left», подсказка «Opens the chat»; превью: Photo / Video / Voice message / расклад / приглашение, маркер |
| `screens/chat-thread` | `chat-thread` (новый) | шапка (Online / Away, Book now), «Today» над лентой (`shared:day.today`), поле ввода (placeholder, 2 a11y), пузырь (Not delivered · Tap to resend, Sending N%, a11y неотправленного), вложения (голос: 5 статусов + 2 a11y; видео 2 a11y; файл: 3 статуса + «… of …»; бокс картинки: 3 статуса + a11y), черновик (Ready to send, Remove, a11y ошибки), лист Attach (заголовок, 3 строки × подпись + подсказка), просмотр фото (Close, «2 of 5», Share or save, «You», время), приглашение (eyebrow капсом, title, text, CTA, «… — applied for you»), продление (CTA «Extend · {{cost}}», Choose a block, тост «Added N minutes», тост «session ended … on your balance»), быстрая бронь (5 ошибок, «Start now · {{cost}}» / «Book · {{cost}}», Choose a length, тост «Session started · N min») |
| `features/tarot-spread` | `tarot-spread` (новый) | Your spread, Choose a card, подпись, подсказка жеста, Turning it over…, I chose this card., ошибка выбора, You chose (eyebrow капсом), разделитель «You chose {{card}}» (капсом), a11y карты в веере, a11y открытия карты, Close в просмотре |

Чувствительное: `@sensitive refund` — тост «Your session ended before the minutes were added. … is on your
balance.» (как session-detail / paid-session); `@sensitive payment` — CTA продления и быстрой брони с суммой,
priceChanged, «Added N minutes». Остальной чат — нет.

## Как

### Маркеры сессии (решение владельца 5 `AURAI-0010`)
- Распознавание — в одном месте, `features/chat/lib/map-message.ts`: **точное** совпадение (после `trim`) с текстом
  BFF `MARKER_CONTENT` — «Your session has started» / «Your session has finished» — даёт `ChatMessage.marker:
  'started' | 'finished'`. Шаг 5 заменит это чтением `Message.marker` (контракт v0.28) в той же функции.
- Тон: у распознанного — по виду (teal / muted); у нераспознанного — как сейчас (`toneOf`).
- Два места, два набора ключей: `marker.divider.*` — в треде через `ThreadDivider` (капсом; el — капсом без тонуса,
  JSDoc «drawn in capitals — write Greek in capitals already»); `marker.preview.*` — в списке, обычный регистр
  (переводы с веба `message:marker.*`). el «finished» — тот же глагол, что у `advisor-review` `prompt.ended`
  («Η ΣΥΝΕΔΡΙΑ ΣΑΣ ΤΕΛΕΙΩΣΕ»), ради одного слова на одном экране.
- Нераспознанный текст — как пришёл. Комментарии переписать: `map-message.ts:9-10`, `SessionMarker.tsx:9, 23-24`.

### Модель отдаёт причины, текст — при отрисовке
- `use-attachment-draft`: `error` — причина (`DraftError`: `tooLarge` + байты, `textFile`, `unreadable`,
  `unopenable`, `pasteFailed`, `pasteMany`), `refuseDraft` возвращает причину. Слова — `describeDraftError` в
  `features/chat`, как `describeRefusal`: `i18next.t` **без** `lng` (так работает псевдоязык), язык — только в
  `formatFileSize` / `formatMegabytes` (образец `block-discount.ts`). Компоненты, что их показывают
  (`DraftAttachmentBar`, `MessageBubble`), зовут `useTranslation('chat')` сами — перерисуются на смену языка.
- `use-chat-thread`: в просмотрщик — момент сообщения и флаг «это я»; «You» и время форматирует `ImageViewer`.
- `use-quick-book`, `use-extend-checkout`: `useTranslation('chat-thread')` в хуке, ошибка — ключом (`confirm.error`
  уже ключ), тосты — переводом в момент показа.
- `screens/chats/lib/preview.ts` возвращает вид превью (текст / вложение по типу / расклад / приглашение / маркер),
  `ChatListRow` переводит. Сообщение с `spread` или `sessionInvite` показывает своё слово, а не `content`: BFF
  кладёт туда английские заглушки «Choose a card» / «Continue this reading privately».

### Что становится с конфигами-текстами
- `features/tarot-spread/config/copy.ts` удаляется: тексты — ключи `tarot-spread`, функции-сборщики
  (`chosenDivider`, `openCardLabel`, `cardLabel`) — интерполяция. `chosenDivider` уходит из public API:
  `SpreadMessage` (memo) сам зовёт `useTranslation('tarot-spread')` и отдаёт в `ThreadDivider` ключ `youChose`
  (экран берёт namespace фичи нижнего слоя — как `write-review` берёт `advisor-review`). Тест: смена языка при
  готовом раскладе на экране.
- `screens/chat-thread/config/session-invite.ts` удаляется (JSDoc о том, почему без цифр, переезжает в `en.ts`);
  `SessionInviteCard` (memo) зовёт `useTranslation('chat-thread')` сам.
- `renderItem` треда язык не учитывает — поэтому каждый memo-компонент с текстом подписан на язык сам.

### Склейки и падежи → целые строки
- «Session live · {{count}} min left» — плюралы.
- Приглашение: «{{offer}} — applied for you» одной строкой.
- Быстрая бронь: «Start now · {{cost}}» и «Book · {{cost}}» — две целые строки.
- Таро — ключи веба `tarot-pick` (там падеж и род уже решены): `youChose` «You chose {{card}}» (pl «Twój wybór:
  {{card}}», de «Deine Wahl: {{card}}»; el для разделителя — капсом), `card` «Card {{n}} of {{total}}», `chosen`
  «I chose this card.», `open` — английский приложения меняю на веб-овский «Open {{card}} full size», чтобы взять
  переводы («Otwórz kartę {{card}}…» — имя в приложении).
- «{{received}} of {{total}}», «{{index}} of {{total}}», «Sending {{pct}}%» (пробел перед % — как
  `shared:offer.pctOff`).

### a11y (label-in-name, подсказка — результат, не жест)
- Шапка: у кнопки продления убрать подпись «Extend the session» — читается видимое «Extend +10 min».
- Строка списка: убрать подмену `accessibilityLabel` — RN соберёт имя, превью, время, «online», «Session live» из
  дочерних (имя первым); подсказка «Opens the chat». Тест: превью входит в доступное имя.
- Неотправленное сообщение: подпись «Not delivered: {{text}}» (у вложения без текста — слово вложения из превью),
  подсказка «Sends it again».
- Ошибка черновика: подпись — текст ошибки, подсказка «Hides this message», `accessibilityLiveRegion="polite"`.
- Бокс картинки: подпись «Couldn’t load · {{file}}», подсказка «Loads it again».

### Переводы
- `translate.mjs scan … --web` по четырём `en.ts`; с веба — где английский совпал (`004`) + `tarot-pick:youChose /
  card / chosen / open`; el для мест капсом — переписать капсом без тонуса, а не копировать. Заглавное «Online» веба
  (`conversation-list:online`) для «online» в середине строки не беру.
- Быстрая бронь — переводы `book-session:started`, `review.errors.priceChanged / notBookable / failed` копирую туда,
  где английский совпадает; свои ключи (FSD).
- Остальное — по глоссарию, регистру и форме кнопки; 2–3 агента по группам языков (effort medium),
  `translate.mjs check`, моя вычитка de / pl / el / fr / lt.

### Узкие места — `@max` по замеру шрифтом (opentype.js по бандл-TTF, 360 pt)
- шапка треда: «Book now» (sm-кнопка рядом с именем), «Online / Away»;
- строка списка: пилюля «Session live · N min left», «online» после имени;
- голосовое сообщение (`VOICE_WIDTH`): Voice / Playing / Won’t play / Tap to retry / No longer available;
- бокс картинки — по **самой узкой плитке мозаики**: half(ATTACHMENT_WIDTH − 28) ≈ 109 pt, 13 / 12 pt, вес 600,
  одна строка; где не влезает — `numberOfLines={1}` и короче формулировка;
- подпись доставки: в пузыре и на плашке поверх картинки без подписи (10 pt, ширина = самая узкая картинка − 32 pt)
  — `@max` и у пяти текстов `describeRefusal`, которые выводятся там же;
- мета файла «Couldn’t load · Tap to retry»; лист Attach; CTA приглашения; подсказка жеста расклада (266 pt).

### Линтер и тесты
- `i18next/no-literal-string` на `error` для четырёх слайсов. Правило **не** видит JSX внутри пропов вне
  `jsx-attributes.include` (`ListHeaderComponent` / `ListFooterComponent`: «Today», «Chats», «All advisors»), `.ts`
  и `src/app/**` — дыру с `List*Component` передаю в шаг 4 (добавить пропы в `include`). Поэтому — тесты отрисовки
  на de: шапка треда, заголовок и подвал списка, CTA быстрой брони и продления, ошибки.
- Тесты: маркеры — точное совпадение переводится (de; el в разделителе капсом и в превью обычным), неизвестный
  текст как есть и с прежним тоном; превью вложений / расклада / приглашения на de; ошибка черновика перечитывается
  при смене языка; `describeRefusal` на de с лимитом в формате языка; плюралы «N min left» / «Added N minutes»
  (pl / lt); a11y строки, неотправленного, черновика, шапки; «You» и время в просмотрщике; расклад и приглашение
  меняют язык на экране; существующие тесты — на новые тексты.

## Решение владельца
1. **«Today» над лентой треда** — решено (владелец через координатора slave-1-9e, 2026-11-06): здесь подпись
   переводится как есть (`shared:day.today`); в `TECH-DEBT.md` не пишется. Подгрузка истории скроллом вверх (как в
   Telegram) и разделители по дням вместо «Today» — отдельная задача `AURAT-0172` (`app-chat-history-scroll`),
   начнётся после мёржа `0167`.

## Не в объёме
- Тексты сообщений советника, названия и ключевые слова карт (колода, `AURAF-0023-010`), имя файла по умолчанию
  `'file'` при пустом имени из пикера (это имя файла, оно уходит на сервер).
- Переход на `Message.marker` — шаг 5. Включение правила на весь `src`, `List*Component` в `include`, флаг языков —
  шаг 4.

## Общие файлы
`app/i18n/namespaces.ts` (+4), `.eslintrc.js` (+4 пути), `translations.test.ts` (`SAME_AS_ENGLISH` при нужде).
Параллельных i18n-задач нет.
