# AURAT-0165-007 — execute

Дата: 2026-11-06. slave-2, `feature/AURAT-0165-app-i18n-booking-sessions` @ `7f58117`. Не закоммичено, всё в stage.

## Сделано

### Строки — 6 новых namespace + `sessions`, 24 языка
- `features/booking` → `booking`: DateStrip (`strip.today` — своё короткое слово для карточки 58 pt, a11y «Today,
  {{date}}» / «…, fully booked»), DurationPicker (`<Trans>` «{{count}}<unit> min</unit>», a11y с ценой и %, «Biggest
  saving»), SlotGrid (Now, a11y, пустой день), QuickBookSheet (заголовок, 3 eyebrow, «Starts immediately»,
  «in N min / N h / N h M min / starting now»), строка тарифа, строки скидки, итог футера.
- `screens/booking` → `book-session` (имя `booking` занято фичей): Book, Review, Booked, тост «Session started».
  `ERROR_COPY` → `config/review-errors.ts` (ключи).
- `screens/reschedule` → `reschedule`; `screens/sessions` → `sessions` (+ всё, кроме сегментов);
  `screens/session-detail` → `session-detail` (экран, герой, лист отмены, алерт); `screens/write-review` →
  `write-review` (`config/copy.ts` удалён); `features/advisor-review` → `advisor-review` (`STAR_LABELS` →
  `STAR_RATINGS`, подписи — `stars.<n>`; карточка в треде).
- `shared`: `minutes` («{{count}} min», плюралы — переводы веба), `price.perMinute` — побайтно как у `0164`
  (значения и блок SAME_AS_ENGLISH), `shared:minutes` передан `0166` (вставлен там дословно).
- `app/i18n/namespaces.ts` +6, `.eslintrc.js` — `i18next/no-literal-string` на `error` для 7 слайсов.

### Склейки → данные (решения 2, 3)
- `savedWith` в параметре `BOOKED` — `SavedWith` (`{ kind: 'offer' } | { kind: 'campaign'; label }`, тип в
  `shared/config/navigation.ts`); Booked: «You saved {{amount}} with your welcome offer» / «You saved {{amount}} ·
  {{campaign}}» / «You saved {{amount}}». `screens/chat-thread/model/use-quick-book.ts` — только тип.
- Lib возвращает данные: `untilOf` (вместо `untilLabel`), `heroStateOf` (вместо `stateLabel`), `pastMinutes`,
  `windowRangeLabel`; слова — в хуках / компонентах. `discountLineOf` / `creditRowOf` / `campaignNameOf` — через
  `i18next.t` при вызове, как `shared/lib/discount-copy`. `BookingDuration.label` удалён (не нужен).
- Имена: «{{name}} — how was your reading?», в треде «How was your reading?» (проп `advisorName` у
  `ReviewPromptCard` удалён, одна строка в `ChatThreadScreen`), модерация — «the advisor’s profile», лист отмены без
  имени (проп `advisorName` у `CancelSessionSheet` удалён), a11y «действие, {{name}}». Карточка Upcoming: «Reading
  with Luna» → «Reading · {{name}}».
- Чистые разделители (`{{role}} · {{price}}{{perMinute}}`, `{{date}} · {{time}}`, «15:00, 16 Aug», «… · 30 min»,
  a11y карточки) — склеены в коде через « · » / «, », как `AdvisorRow` у `0164`: ключ из одних плейсхолдеров совпал бы
  с английским в 23 языках.
- `balanceCta` в `useCheckout` — готовый «Confirm & pay {{amount}}»; `CheckoutVerb` и чекаут не тронуты (`0166`).

### Переводы
- Память веба (`translate.mjs scan`): 88 из 175 строк — лист отмены, форма отзыва, Booked, длительности, состояния
  сессии. Остальное — по глоссарию и регистру языка; el-строки под `textTransform: 'uppercase'` (eyebrow быстрой брони,
  «Biggest saving», «Current time», подпись поля отзыва, eyebrow карточки в треде) — заглавными без тонов.
- Веб в ga `write-review:lead` — «léitheoir» (запрет глоссария; уже в списке расхождений) → «comhairleoir».
- `@sensitive`: payment (тариф, скидки, Total, You save / saved, остаток, Confirm & pay, Paid / Saved), cancellation
  (политика, примечания, лист отмены, алерт), refund (тиры, оценка, суммы).

### Вёрстка — замер шрифтом (opentype.js по бандл-TTF, 360 pt)
Не влезало и укорочено: «Biggest saving» (тег 86 pt, капсом 9.5 — 20 языков) → «лучшая цена / топ-экономия»
(de Bestpreis, fr Meilleur prix, pl Najtaniej, hu Legjobb ár…); fr «Now» → «Immédiat» (пилюля 84 pt); кнопки строк
Sessions: cs Přesunout, fr Reporter, hr Premjesti; Open chat → существительное (el Συνομιλία, fr Discussion, ga Comhrá,
hu Csevegés, lt Pokalbis, ro Conversație); fr Review → Noter; «Cancel session» в листе 1 : 1 (115 pt) → глагол (13
языков: Stornieren, Annuler, Cancelar…); «Tap a star to rate» (268 pt) → «Tap a star» (15 языков); DateStrip «Today»
— fr «Auj.» (`AUJOURD’HUI` = 80 pt при 58). Дни недели и месяцы CLDR — все ≤ 58 pt. `@max` — по замеру.

### Тесты
- Новые: `BookedScreen.test.tsx` (офер, кампания, без метки, старая ссылка, de); memo-карточка отзыва на de.
- Обновлены: slots, block-discount, ReviewPromptCard, Sessions, SessionDetail, WriteReview, ChatThread.review.
- `tsc` — 0; `eslint .` — 0; Jest — 188 наборов, 2233 теста; `translate.mjs check` — 0 запретных форм.

## Не сделано / проверить
- **Мёрж develop**: там уже `AURAT-0163` (`b0f6e90`) — конфликты в `namespaces.ts`, `.eslintrc.js`,
  `translations.test.ts` (оба добавляют рядом); разрешу при коммите после ревью. Блок SAME_AS_ENGLISH 0165 стоит после
  `fr:push:channels.messages` — в стороне от блоков 0164 и 0166.
- DateStrip `minimumFontScale` / `adjustsFontSizeToFit` не трогал — правит `0164` (под Fabric не работает).
- `shared:day.today` fr «Aujourd’hui» — 80 pt; в DateStrip больше не используется, остался в Review (строка Date — место есть).
- Вёрстка на устройстве (псевдоязык, de / fi / hu / el / ga): футер Book, тег «Biggest saving» (absolute — проверить
  на 3 и 4 карточках), пилюля Now, кнопки строк Sessions, лист отмены, CTA отзыва — в маноре после мёржа.
- Ревью носителем: `translate.mjs review` — `book-session`, `booking`, `reschedule`, `session-detail` (payment,
  cancellation, refund) до маркетинга в стране.

## Раунд 2 — ревью координатора (`wf0165-review.md`), владелец: «да, передай»

### Решения владельца
1. Минус у сумм: везде `formatUsdMinor(-x, language)`, знак U+2212 ставит форматтер (меняет `0166`). Здесь —
   строка скидки на Review (`BookReviewScreen`) и строка кредита (`use-booking-confirm`); тесты считают ожидание
   через `formatUsdMinor(-x, lang)`, порядок мёржа с `0166` не важен.
2. **Приняты отступления от спеки**: превью переноса «{{time}}, {{date}}» склеено в коде (S4); карточка Upcoming
   «Reading · {{name}}» (S5).
3. **Передано задаче «чат»** (S3): в `screens/chat-thread/model/use-quick-book.ts` остаются английскими тост
   «Session started · N min», `ERROR_COPY` и CTA баланса («Book · $X» / «Start now · $X» / «Choose a length»).
   Готовые ключи для неё: `book-session:started`, `book-session:review.errors.*`.

### Исправлено
- **«Biggest saving»** — снова «наибольшая экономия / скидка» (тег на самом длинном и дорогом блоке): de
  Top-Ersparnis, nl Max. korting, sv Mest sparat, da Mest sparet, hu Max. spórolás, fr Économie max, pt Mais
  poupança, pl Max. zniżka, lt Top nuolaida, lv Top atlaide, el ΜΕΓ. ΕΚΠΤΩΣΗ, mt L-akbar skont. Все ≤ 86.7 pt.
- **Лист отмены**: кнопка не совпадает со словом «закрыть»: fr Oui, annuler; es Sí, cancelar; pt Sim, cancelar;
  nl Ja, annuleren; el Ναι, ακύρωση; ro Da, anulează; mt Iva, ikkanċella; ga Cealaigh é; lt Taip, atšaukti; da
  Afbestil. a11y-подпись начинается с того же слова. hu keep — Megtartás. Всё ≤ 112 pt.
- **Футер Book** — вёрсткой: строка под суммой ≤ 140 pt и до 2 строк; кнопка не сжимается меньше своей подписи —
  если рядом не помещается, уходит отдельной строкой под сумму (`flexWrap`, у `cta` `flexGrow` вместо `flex: 1`,
  без `fullWidth`). Замер (`footer2.cjs`, 360 pt) — в одну строку помещаются все 24 языка, кроме: hu до выбора
  времени; с зачёркнутой ценой («96,00 US$ 192,00 US$» ≈ 200 pt) — bg cs da de es hr hu lt pl pt sk sv (там
  кнопка под суммой, стабильно, пока действует скидка). Укорочено: book.review el Έλεγχος, hu Áttekintés, nl
  Bekijken, ro Verifică, sv Granska; pickTime da Vælg en tid, fr Choisir l’heure, pl Wybierz termin, pt Escolher hora.
  JSDoc en.ts — новый бюджет (≈ 119 pt).
- **Confirm & pay без цены** — целый ключ `review.confirm` (@sensitive payment, 24 языка), вместо дыры
  («Bestätigen &  zahlen», «…fizetés: »).
- @sensitive: pl «Środki na pierwszą sesję»; hu «legkésőbb» в политике и reassure; fi «viimeistään» (reassure,
  политика, примечания); sl «do 4 ur» (4 строки); pt / sv — текст листа без предлога перед датой с днём недели.
- Остаток на балансе — формы `store-topup:remainder` из `0166` (el es fr it mt pt ro, ед. ч.).
- Формы кнопок: pickTime / pickAnother / reschedule pick — инфинитив (fr es pt nl cs sk lt lv), ед. императив
  (bg hr sl), сущ. (el hu); nl Adviseur zoeken; bg Пренасрочи / Прегледай; hr Promijeni termin.
- a11y label-in-name: все четыре подписи строк Sessions = «<видимое слово>, {{name}}» (выводятся генератором из
  видимого ключа); en reviewLabel «Review, {{name}}», detailsLabel «Details, {{name}}» (de/nl — в SAME_AS_ENGLISH).
  Now: fr nowLabel «Immédiat, …», et Kohe, it Adesso.
- openLive без «session», слово языка для чата, ≤ 246 pt, `@max 32`; pl pozostała / pozostały / pozostało, sk
  zostávajú (и в state.live).
- mt часы: sagħtejn / sigħat, untilHoursMinutes — «{{hours}} h {{minutes}} min». ro / mt примечание переноса —
  без рода советника. Мелочи: hu «a Konzultációk», sl Prestavi, es Cambiar hora, ga Am reatha, lv „Sesijas”, hr
  Otkazana, U+00A0 перед % во всех строках с `{{pct}} %`; es formatBody без vosotros.

### Тесты (+29)
DateStrip — memo-карточка на de; use-booking-confirm — смена языка при смонтированном хуке (тариф, скидка) и
минус nl; slots — границы untilOf (60 мин, 59:40, 29 / 31 с); use-quick-booking — «in 2 h 10 min», «in 2 h»,
«starting now» и mt; block-discount — savedWithOf кампании (с меткой и null); use-book-review и use-quick-book —
`savedWith`, который уходит в BOOKED, и `review.confirm` без цены; SessionDetail — плюралы cs / ro / pl, текст
листа, de; Sessions — a11y карточки и de; WriteReview, Reschedule — de.
`tsc` 0; `eslint .` 0; Jest 189 наборов, 2262 теста; `translate.mjs check` — 0 запретных форм.

### Не сделано (по желанию в ревью)
- F17 (el textLabel капсом читается как a11y), S6 (псевдоязык в строках цены), bg «Отмени я», T8 (Booked с
  советником и остатком), cancelled / completed в герое (T7).
- Вёрстка на устройстве — по-прежнему в маноре после мёржа (футер Book со скидкой, тег, лист отмены).
