# AURAT-0165-004 — context

Дата: 2026-11-06.

## Источники
- `AURAF-0023`, `AURAI-0010` § Recommendation п. 3 и решения 5, 7; build rules § Translations.
- Образцы: `AURAT-0162` (спека, замер шрифтом — opentype.js по бандл-TTF, `008`), `AURAT-0164-005/007` (имена в
  падежных местах — решение 1, `price.perMinute`).
- Веб (`aura-web` `develop` @ `88dd553`): память переводов есть для cancel-session, write-review, booked,
  book-session, reschedule-session, sessions, session-detail — английский во многом совпадает дословно.
- Код slave-2 @ `7f58117` — ground truth (ниже).

## Что в коде
- Ни у одного слайса задачи нет `config/locales`, кроме `screens/sessions` (только `segments.*`, `0157`).
- Форматтеры `0159` уже подключены: DateStrip (weekday / month по CLDR, `upperLabel`, сжатие до 0.6), слоты
  (`formatClockTime`), `longDateLabel` / `shortDateLabel` / `relativeDayLabel`, `formatUsdMinor` — с явным языком.
  Осталось только английское вокруг них: `', fully booked'`, `'Now, start immediately'`, `' min'`, `in N h M min`,
  `${n} min chat`, `In progress · N min left`, `→ 15:30`, слот Reschedule `«15:00, 16 Aug»`.
- Склейки: `${advisor.role} · $X/min`; `You saved $X with ${savedWith}` — `savedWith` фрагмент («your welcome
  offer» или серверная метка кампании) едет параметром навигации `BOOKED` (`shared/config/navigation.ts`) и из
  `screens/chat-thread/model/use-quick-book.ts`; `${campaignLine} · You save $X`; `Confirm & pay ${total}`
  (`balanceCta` в `useCheckout` — `features/store-topup`, задача 0166); `Session started · N min` (тост).
- Имена в падежных местах: «How was your reading with {{firstName}}?» (форма отзыва, карточка в треде),
  «…on {{firstName}}'s profile» (модерация), «Your N-minute chat session with {{name}} on …» (лист отмены), a11y
  «Session with / Open the chat with / Reschedule the session with / Open the session with / Review {{name}}».
- `STAR_LABELS` и копии write-review — английские строки в `config` (нужно: ключи).
- Отмена и возврат (лист отмены, алерт «Session cancelled», политика на Review) — `@sensitive`.
- `QuickBookSheet` и `ReviewPromptCard` рисуются в треде чата, но принадлежат моим слайсам.

## Пересечение с AURAT-0166 (деньги, slave-3)
Заглушка 0166 перечисляет «Biggest saving» (`features/booking/ui/DurationPicker`) и «You saved … with
${savedWith}» (`screens/booking/ui/BookedScreen`) — это файлы моих слайсов. Ещё денежное в моих файлах: строка
тарифа «$X/min × N min», строки скидки (`block-discount.ts`: Welcome offer · N% off / First-session credit /
Discount / Seasonal sale), Total, You save, «$X stays on your balance», Confirm & pay. В slave-3 пока нет изменений
кода (папка 0166 — до `003`). Нужен раздел по слайсам — решение владельца.

## Прочее
- Имена namespace: `features/booking` и `screens/booking` — оба «booking»; тест требует уникальности → экранам
  `book-session` (как на вебе).
- `shared:price.perMinute` уже переведён в slave-1 (`0164`, не в develop) — беру его блок дословно, чтобы мёрж
  второй из задач прошёл без конфликта по значениям.
- `features/advisor-review/ui/ReviewPromptCard` и `QuickBookSheet` переносятся здесь; строки самого треда — задача «чат».
