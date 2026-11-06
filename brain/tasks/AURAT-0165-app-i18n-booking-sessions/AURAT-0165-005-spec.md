# AURAT-0165-005 — spec: бронь и сессии на 24 языках

Тип: задача фичи `AURAF-0023` (шаг 3), строка `AURAF-0023-003` (часть — бронь и сессии).
Status: approved 2026-11-06 (`006`).

## Что получится

С телефоном на любом из 24 языков бронь (выбор длины, дня, времени, Review, Booked), перенос, вкладка Sessions,
экран сессии с листом отмены, форма отзыва и быстрая бронь в треде говорят на этом языке всё, что пишет само
приложение: заголовки, кнопки, пустые и ошибочные состояния, подписи VoiceOver / TalkBack, тосты и алерты. Даты,
время и суммы — уже по CLDR (`0159`), остаётся английское вокруг них. Имена советников, роли, названия кампаний —
с сервера, английские до шага 5. До запуска (шаг 4) видно только в dev (флаг `AURA_I18N_ENABLED`).

## Объём

| Слайс | Namespace | Что |
|---|---|---|
| `features/booking` | `booking` (новый) | DateStrip (a11y «fully booked»), DurationPicker (`{{count}} min`, a11y, «Biggest saving»), SlotGrid (Now, a11y «unavailable», пустой день), QuickBookSheet (заголовок, 3 eyebrow, «Starts immediately», «in 12 min / 2 h 10 min / starting now», Another time), строки скидки и тарифа из `block-discount` / `use-booking-confirm`, итог в футере («30 min chat · 15:00 – 15:30», «starts now») |
| `screens/booking` | `book-session` (новый) | Book a session: заголовок, 2 ошибки, роль · цена/мин, «Private chat session» + подпись, How long / Pick a date / Available times, примечание, You save, Choose a time / Review booking / Pick a time. Review: заголовок, Date / Time / Format, Total, 5+2 ошибки, политика отмены, You save · Free cancellation, Confirm & pay, Pick another time. Booked: заголовок, текст (с именем / без), You saved, остаток на балансе, «30 min chat», View session. Тост «Session started · N min» |
| `screens/reschedule` | `reschedule` (новый) | заголовок, 3 состояния, Current time, примечание, New date / New time, 3 ошибки, Confirm new time / Pick a new time; превью «15:00, 16 Aug» — порядок из перевода |
| `screens/sessions` | `sessions` (есть) | заголовок, 2 пустых состояния, ошибка загрузки, Find an advisor; карточка: «In progress / Today · 30 min chat», Reschedule, Open, a11y; строка прошлой: длительность, Open chat / Review, a11y |
| `screens/session-detail` | `session-detail` (новый) | 2 состояния, Date / Time / Format / Paid from balance / Saved, Completed / Cancelled / In progress · N min left, Reschedule, Cancel, Open chat / Open session chat · N min left; лист отмены; алерт «Session cancelled» |
| `screens/write-review` | `write-review` (новый) | всё из `config/copy.ts` (ключи вместо строк), тосты, ошибка |
| `features/advisor-review` | `advisor-review` (новый) | `STAR_LABELS` (5 подписей звёзд — ключами), вопрос карточки в треде |
| `shared` | `shared` | `price.perMinute` — блок `AURAT-0164` дословно (24 языка); `minutes` — «{{count}} min» с плюралами (общая единица для брони, сессий, чата и оплаты) |

Оплата (`PayWith`, `PayBreakdown`, `PayNotice`, `CheckoutButton`, `TopUpSheet`, глагол `Pay $X & book`), промокоды,
`shared/ui/offer` (`PriceTag`, `CouponTicket`) — задача «деньги» `AURAT-0166`. Строки самого треда чата — задача
«чат».

## Как

### Строки
- Namespace на слайс, регистрация в `app/i18n/namespaces.ts`, `i18next/no-literal-string` на `error` для семи
  слайсов. Config отдаёт ключи (`STAR_LABELS`, `ERROR_COPY`, копии write-review), `t()` — в компонентах и хуках;
  `React.memo`-строки (`DayCard`, `SlotPill`, `NowPill`, строки Sessions) зовут `useTranslation` сами.
- Lib-хелперы (`untilLabel`, `durationLabel`, `stateLabel`, `discountLineOf`…) возвращают **данные** (вид + числа),
  слова — в хуке / компоненте; либо принимают `t`. Модульного `t()` нет.
- Переводы — из веба, где английский совпадает (`translate.mjs scan … --web`): лист отмены почти целиком, форма
  отзыва, Booked, длительности, «Biggest saving», «Pick a time», «Starts now · N min», «You save», состояния сессии.
  Остальное — по глоссарию и регистру языка.
- Плюралы для всех счётных: «N min», «N-minute chat session», «N min left», «in N min / N h».
- `@sensitive cancellation` / `refund`: лист отмены, алерт «Session cancelled», политика отмены на Review и Book,
  «Free cancellation up to 24 h before»; `@sensitive payment`: Confirm & pay, Total, You save / You saved, остаток на
  балансе, строки скидки и тарифа.

### Склейки
- `', fully booked'`, `', unavailable'` — целые a11y-строки с датой / временем внутри.
- `{{role}} · {{price}}{{perMinute}}` — одной строкой `book-session`, как в `advisors` у `0164`.
- «You save {{amount}}» и «{{campaign}} · You save {{amount}}» — две целые строки.
- «Confirm & pay {{amount}}» — целая строка; в `useCheckout` уходит готовый текст (тип `CheckoutVerb` не трогаю).
- «You saved … with …» — см. решение 2.
- Превью переноса: `{{time}}, {{date}}` — одна строка, порядок задаёт перевод.
- «→ {{time}}», «{{start}} – {{end}} · {{count}} min» — строки с плейсхолдерами (стрелка и тире остаются, разделитель
  времени — `–`, как в `slotRangeLabel`).

### Узкие места (`@max` + замер шрифтом на 360 / 393 pt, как в `0162-008`, `0164-007`)
- DateStrip 58 pt: слово «Today» (`shared:day.today`) уже сжимается до 0.6 — проверяю, что все 24 влезают.
- Пилюли времени (треть ширины): «Now». Карточки длительности (треть): «N min». Тег «Biggest saving» (9.5 капсом,
  над карточкой — не шире её). Eyebrow быстрой брони (капсом). Pill «30 min» на Review.
- Кнопки: Review booking / Pick a time (футер — половина ширины), Keep it / Cancel session (1 : 1), Reschedule /
  Cancel на экране сессии, sm-кнопки в строках Sessions (Reschedule, Open, Open chat, Review), Confirm new time.
- Одна строка: итог футера Book («30 min chat · 15:00 – 15:30»), «You save …», «Current time», подписи DetailRow.
- Капсом рисуются eyebrow быстрой брони, «Biggest saving», eyebrow карточки Sessions — el пишется заглавными без
  тонов.

### Тесты
- Обновить тесты экранов и хуков, которые ищут английский текст; добавить: memo-строка перерисовывается на de
  (DayCard или PastSessionRow), «You saved» с кампанией и с офером, плюралы «N min left» на pl / lt.
- `tsc`, `eslint .`, Jest — зелёные; `translate.mjs check` — без запретных форм.
- Вёрстка на устройстве (псевдоязык, de / fi / hu / el / ga) — в маноре после мёржа.

## Решения владельца

1. **Граница с «деньгами» (`AURAT-0166`) — по слайсам** (рекомендую). Всё в `features/booking`, `screens/booking`
   (в том числе денежные строки: тариф, скидка, Total, You save / You saved, остаток, Confirm & pay, «Biggest
   saving») переводит эта задача; `features/store-topup`, `features/paid-session`, `features/promo-code`,
   `shared/ui/offer` — 0166. Так две задачи не правят одни файлы. Общая единица «{{count}} min» — ключ
   `shared:minutes` отсюда; 0166 берёт его, не заводит свой. Я напишу сессии slave-3 после решения.
   Альтернатива: денежные строки брони — в 0166 (тогда обе задачи правят `BookReviewScreen`, `BookedScreen`,
   `DurationPicker`, `block-discount`).
2. **«You saved $X with …» — без фрагмента** (рекомендую). Сейчас в параметре навигации едет готовое английское
   «your welcome offer» или серверная метка кампании. Станет данными: `savedWith: { kind: 'offer' } |
   { kind: 'campaign'; label }`, и две целые строки — «You saved {{amount}} with your welcome offer» (как на вебе) и
   «You saved {{amount}} · {{campaign}}» (название кампании стоит отдельно, без падежа). Задевает
   `shared/config/navigation.ts` и одну строку в `screens/chat-thread/model/use-quick-book.ts` (тип параметра).
3. **Имена в падежных местах — переписать английский** (рекомендую, как решение 1 у `0164`):
   - форма отзыва: «How was your reading with Luna?» → «Luna — how was your reading?» (имя стоит отдельно; так уже
     у веба на pl); карточка в треде — «How was your reading?» (это и так тред с Луной);
   - модерация: «…on Luna's profile» → «…on the advisor's profile» (строка `moderationAny` веба);
   - лист отмены: «Your 30-minute chat session with Luna on …» → «Your 30-minute chat session on {{date}} at
     {{time}} will be released.» (лист открыт с экрана этой сессии, советник на нём);
   - a11y — «действие, {{name}}»: «Reschedule, Luna», «Open session, Luna», «Open chat, Luna», «Review, Luna»,
     «Luna, today at 15:00» — вместо «… with Luna»;
   - «Luna will be ready for you…» и «Luna sees the new time on their side» — имя подлежащее (именительный), остаются.
   Альтернатива: английский как есть, переводчик в каждом языке обходит падеж сам (приложение, «s poradcem {{name}}»).

## Не в объёме
- Серверный контент: имена, роли, названия кампаний, маркеры сессии — шаг 5.
- Оплата и пополнение, промокоды, `PriceTag` / `CouponTicket` — `AURAT-0166`; тред чата — задача «чат».
- Нативные объявления языков, включение флага — шаг 4.

## Общие файлы
С `AURAT-0163` / `0164` / `0166`: `app/i18n/namespaces.ts`, `.eslintrc.js`, `shared/config/locales/*`
(`price.perMinute` — дословно как у 0164; `minutes` — новый), `shared/config/navigation.ts` (решение 2). Конфликт
решает задача, которая мёржит позже.
