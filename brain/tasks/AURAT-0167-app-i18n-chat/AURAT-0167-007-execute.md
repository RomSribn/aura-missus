# AURAT-0167-007 — execute

Дата: 2026-11-06. slave-0, `feature/AURAT-0167-app-i18n-chat` (от `develop` @ `dc98590`). Не закоммичено — всё в
stage для ревью. 167 файлов, +6507 / −687.

## Сделано

### Строки — 4 namespace × 24 языка
- `features/chat` → `chat`: маркеры (`marker.divider.*` — капсом, `marker.preview.*` — обычный регистр), 5 отказов
  сервера (`refused.*`), 6 ошибок черновика (`draft.*`).
- `screens/chats` → `chats`: заголовок, All advisors, пустой экран, «online», «Session live · N min left»
  (плюралы), подсказка строки, превью (Photo / Video / Voice message / расклад / приглашение).
- `screens/chat-thread` → `chat-thread`: шапка, поле, доставка, голос / видео / файл / картинка, черновик, лист
  Attach, просмотрщик, приглашение, продление (`@sensitive payment`, тост `ended` — `@sensitive refund`), быстрая
  бронь (`@sensitive payment` на CTA с суммой и priceChanged).
- `features/tarot-spread` → `tarot-spread`: всё вокруг расклада; ключи и переводы веба `tarot-pick` (youChose /
  card / chosen / open — «Open {{card}} full size», английский как на вебе).
- «Today» над лентой — `shared:day.today` (решение владельца; разделители по дням — `AURAT-0172`).
- `app/i18n/namespaces.ts` +4; `.eslintrc.js` — `i18next/no-literal-string` на `error` для четырёх слайсов.
- Переводы: с веба — где английский совпал (`scan`: chat 6/15, chats 9/13, chat-thread 15/60, tarot 8/11) + из
  `book-session` для быстрой брони; остальное — 3 агента по группам языков (effort medium, 10–12 мин каждый) по
  глоссарию, регистру и форме кнопки; затем вычитка мной de / pl / el / fr / lt.
- Правки после вычитки: el `marker.preview.finished` «τελείωσε» (тот же глагол, что у разделителя и
  `advisor-review`); pl «pozostała / pozostały / pozostało», sk «zostávajú» в «Session live» (согласование глагола,
  как у `session-detail`).
- `SAME_AS_ENGLISH`: Online / online (12 языков, как у сегмента advisors), Video (10), fr Photo, Chats (5).

### Маркеры сессии (решение 5 `AURAI-0010`)
- `map-message.ts`: `markerOf` — точное совпадение (после `trim`) с `MARKER_CONTENT` BFF → `ChatMessage.marker`;
  тон распознанного — по виду, нераспознанного — прежняя регулярка. Одно место для шага 5 (`Message.marker`).
- `SessionMarker` и превью списка показывают слова приложения при `marker`, иначе текст сервера. Комментарии
  `map-message.ts`, `SessionMarker.tsx`, `types.ts` переписаны.

### Модель отдаёт причины
- `use-attachment-draft`: `error: DraftError` (6 причин); `refuseDraft` без языка, возвращает причину;
  `describeDraftError` / `describeRefusal` — `i18next.t` без `lng` (работает псевдоязык), язык — только для
  размеров; `DraftAttachmentBar` и `MessageBubble` подписаны на `chat`.
- Просмотрщик: `ViewerSubject` — `fromMe`, `advisorName`, `sentAt`; «You» и время — в `ImageViewer`.
  `messageTime` принимает `Pick<ChatMessage, 'sentAt'>`.
- `use-quick-book`, `use-extend-checkout`: `useTranslation('chat-thread')`; `ERROR_COPY` удалён, ошибка — ключ.
- `screens/chats/lib/preview.ts` — вид превью; расклад / приглашение — своё слово вместо английской заглушки BFF.
- Удалены `features/tarot-spread/config/copy.ts` (и `chosenDivider` из public API — `SpreadMessage` зовёт
  `useTranslation('tarot-spread')`) и `screens/chat-thread/config/session-invite.ts` (JSDoc — в `en.ts`).

### a11y
- Шапка: без подписи «Extend the session» — читается видимое «Extend +10 min».
- Строка списка: без подмены `accessibilityLabel`, подсказка «Opens the chat».
- Неотправленное: «Not delivered: {{text}}» (без текста — имя файла), подсказка «Sends it again».
- Ошибка черновика: подпись — сама ошибка, подсказка «Hides this message», `accessibilityLiveRegion="polite"`.
- Картинка: «Couldn’t load · {{file}}», подсказка «Loads it again». Строки листа Attach читаются из видимого.

### Вёрстка — замер шрифтами (бандл-TTF, 360 pt)
- Бокс картинки: самая узкая плитка ~109 pt; английский «This file won’t open» (114 pt) уже не влезал в строку →
  до двух центрированных строк (`numberOfLines={2}`, отступ 8), `@max` 28 / 24 (было 18 — английский сам не
  проходил).
- Голос: `@max` 22 (~125 pt); все языки влезают.
- Маркеры капсом (≤ 250 pt), «Session live» (≤ 215 pt), подсказка расклада, CTA листов (≤ 253 pt) — влезают все.
- Подпись доставки «Not delivered · Tap to resend» в el / hu до 196 pt при 10 pt — в пузыре до ~220 pt, влезает.
- Мета файла «Couldn’t load · Tap to retry» в el 189 pt (~170 pt места) — переносится на 2 строки; оставлено.
- `@max` у отказов сервера — 40 (плашка поверх картинки ~217 pt: она во всю ширину блока, а не плитки).

### Тесты
- Новые: маркеры (точное совпадение, пробелы, переформулировка, сообщение советника), SessionMarker на de / el
  капсом / нераспознанный; строка списка на de / el / pl (плюралы с согласованием), расклад / приглашение в превью,
  доступное имя строки; `describeRefusal` / `describeDraftError` на de, код из будущего контракта; черновик меняет
  язык на экране, a11y ошибки; шапка на de и без подписи продления; приглашение меняет язык, el капсом; расклад
  меняет язык на экране, открытый — на pl; экран треда на de («Heute», шапка, поле, маркер), список на de (заголовок
  и подвал — их не видит линтер); быстрая бронь (CTA, ошибка, тост) и продление (CTA, плюрал pl, тост о деньгах) на
  de; подпись просмотрщика меняет язык (fi «Sinä», «10.00»).
- Обновлены: `attachment-rules`, `preview`, `MessageBubble.attachments` (’), `ChatThreadScreen` (a11y resend),
  `.session` (кнопка продления по видимому тексту), `.spread` («full size»).
- `tsc` — 0, `eslint .` — 0, Jest — 196 наборов / 2745 тестов, `translate.mjs check` — 0 запретных форм.

## Для шага 4
- `i18next/no-literal-string` не видит JSX внутри `ListHeaderComponent` / `ListFooterComponent` (и вообще пропов
  вне `jsx-attributes.include`), `.ts` и `src/app/**` — добавить эти пропы в `include` при включении правила на весь
  `src`. Здесь закрыто тестами отрисовки.

## Для носителя (из отчётов агентов)
- `@sensitive`: `extend.*`, `quickBook.*` во всех языках; ga и mt целиком; mt `refused.desk`.
- Короткие статусы под `@max` (`voice.*`, `image.*`); lt / lv `tarot-spread:hint`; hu «Koppints újraküldéshez»;
  ro «Întindere de tarot» (термин глоссария); pt `viewer.you` «Você» (с веба); da `quickBook.book` «Book tiden».
- ro / hu / el «Session live» без слова «сессия» («În desfășurare» / «Folyamatban» / «Σε εξέλιξη», как в
  session-detail) — под `@max`.

## Не сделано / дальше
- Вёрстка на устройстве (флаг `AURA_I18N_ENABLED`): бокс картинки в мозаике, шапка треда, лист Attach, расклад —
  de / el / hu / ga / pl — в маноре после мёржа.
- Ревью координатора slave-1-9e (по просьбе владельца), затем коммит и мёрж — с одобрения владельца.
