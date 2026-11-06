# AURAT-0166-005 — spec: деньги на 24 языках

Тип: задача фичи `AURAF-0023` (шаг 3, задача 6 из 7), строка `AURAF-0023-003` (частично — деньги).
Status: approved 2026-11-06 (решения — `006`; ключ минут — `shared:minutes` от `0165`).

## Что получится

Человек с телефоном на любом из 24 языков видит на своём языке всё, что касается его денег: лист пополнения,
выбор «чем платить» (на экране Review и в листах), разбивку «что откуда списано», кнопку оплаты во всех её фазах
(«Ждём App Store…», «Зачисляем 26,00 $ на баланс…»), сообщения об исходе оплаты, лист промокода с отказами и тостом,
баннер платной сессии, лист продления и подтверждение досрочного завершения. Суммы — по CLDR его языка (`0159`).
До запуска (шаг 4) — только в dev (`AURA_I18N_ENABLED`).

## Объём

| Слайс | Namespace | Что |
|---|---|---|
| `features/store-topup` | `store-topup` | TopUpSheet; PayWith, PayCompact, PayBreakdown, UseBalanceToggle, TopUpLink, PayNotice (6 исходов), CheckoutButton; тексты `use-checkout` (CTA всех фаз, «… left after», «… not enough», «… stays on your balance», «Charged by …») |
| `features/promo-code` | `promo-code` | заголовок листа и строки в профиле «Coupons & Promo Codes», «No coupons right now.», поле, Apply, тост зачисления, 9 отказов |
| `features/paid-session` | `paid-session` | SessionBanner (+ a11y), SessionBlockSheet (заголовок, блоки и их a11y, 3 ошибки, примечание о невозврате, Close, End session early), Alert «End this session?», «Extend +N min», ставка «$1.99/min» |
| `shared` | `shared` | `OffChip` — «−50 %» по правилам языка; `duration.minutes` — «{{count}} min» (плюралы); `price.perMinute` — тот же ключ, что у `0164` |
| `screens/profile` | — | строка «Coupons & Promo Codes» — текст из `promo-code` (одна строка в конфиге профиля) |

Платёжные namespaces `store-topup`, `promo-code`, `paid-session` — `@sensitive payment` целиком (оплата, возврат,
деньги промокода): в `native-review`, до маркетинга в стране — носитель (решение 7 `AURAI-0010`).

## Как

### Склейки → целые строки
- **Глагол оплаты.** `CheckoutVerb` остаётся ключом логики, текст — три целые строки: `cta.storeBook` «Pay
  {{price}} & book», `cta.storeStartNow` «Pay {{price}} & start now», `cta.storeExtend` «Pay {{price}} & extend»;
  так же «Top up to book / extend». Подпись больше не берётся из значения типа.
- **Бренд стора в предложении.** Где «App Store» / «Google Play» / «Apple» — подлежащее или агент («… couldn't
  complete the payment», «Charged by Apple as …», «Your Apple Account · one tap»), строка делится по платформе
  контекстом i18next (`_ios` / `_android`): переводчик согласует глагол с каждым брендом отдельно. Английский
  не меняется. Где бренд стоит отдельно («Waiting for {{store}}…», строка метода оплаты) — подстановка.
- **«Use my balance · {{amount}}»** — одна строка, сумма жирным через `<Trans>`; a11y — своя строка.
- **Минуты** — `shared:duration.minutes_*` «{{count}} min» с плюралами (`formatMinutes` уходит из
  `paid-session/lib` в `shared/lib` — по правилу 4 единый источник; бронь `0165` сможет взять его же).
  «+{{count}} min», «{{count}} min booked · tap for details», Alert «The remaining {{count}} min are…» — целые
  строки с `count` (как `finish-session` / `extend-session` на вебе).
- **Знак суммы.** `−${formatUsdMinor(x)}` → `formatUsdMinor(-x)` — минус и его место по CLDR («−1,99 $» в fi / sv).
- **OffChip** — `shared:offer.pctOff` «−{{pct}}%» с типографикой языка (de «−50 %», fr — неразрывный пробел).

### Модель отдаёт ключи там, где текст живёт долго
- `use-promo-code` хранит отказ причиной (`notFound` / `tooMany` + минуты …), лист переводит при отрисовке —
  смена языка с открытым листом не оставит английский отказ. Тост — переводом в момент показа.
- `use-checkout`, `use-paid-session` — тексты через `t` внутри хука (`useTranslation`), хук перерисуется на смену
  языка. Alert — переводом в момент вызова.

### Переводы
- Сначала `translate.mjs scan … --web`: с веба — Pay with, Aura balance, «… left after», «… not enough»,
  исходы оплаты, все отказы промокода, Add more minutes, End this session? / Keep going / End session / End
  session early, «Balance {{amount}}», примечание о невозврате (где английский совпадает). Остальное — по
  глоссарию и регистру языка; кнопки — форма кнопки языка.
- Исполнение: строки пишу сам; 23 перевода — сам или 2–3 агентами (effort medium, по группам языков, ~30–40 мин),
  затем `translate.mjs check` и проверка мной.

### Узкие места — `@max` по замеру шрифтом (360 pt)
- PayCompact: плитки в пол-листа, `numberOfLines={1}` — «Balance», «One tap», «{{amount}} · not enough».
- SessionBanner: «Paid session live» (eyebrow), «Left» под счётчиком, подстрока в одну строку.
- SessionBlockSheet: «10 min» в плитке блока; заголовок листа.
- Кнопка оплаты: «Pay CA$36.49 & start now», «Adding $26.00 to your balance…» — в одну строку на 360 pt, где
  язык позволяет; где нет — короче формулировка, не обрезка.
- TopUpLink «Top up» — рядом с суммой в строке метода.

### Линтер и тесты
- `i18next/no-literal-string` на `error` для трёх слайсов; бренды — литералы с `eslint-disable` и причиной.
- Тесты: CTA на de для каждого глагола и фазы, PayNotice на de, отказ промокода переводится при смене языка,
  плюралы минут (pl / lt / ga), OffChip на de / fr, существующие тесты — на новые тексты.

## Решения владельца
1. **Граница с `AURAT-0165` и задачей чата.** Рекомендую — по слайсу: «You saved … with …», «— applied for you»,
   «Biggest saving», «Confirm & pay …», «Start now · …» (`features/booking`, `screens/booking`) — в `0165`;
   «Extend · …», «Choose a block», тост «Added N minutes» (`screens/chat-thread`) — в задачу чата. Здесь — всё
   внутри store-topup / promo-code / paid-session / shared/ui/offer. Альтернатива: денежные строки брони — сюда
   (тогда правки в файлах `0165`, конфликт при мёрже).
2. **Заглушка «Visa ···· 4242 / Change»** в TopUpSheet вне store-rail (PSP нет, карты нет). Рекомендую убрать
   строку карты вне store-rail: она показывает карту, которой у человека нет (`AURAI-0010`, рек. 13). Вне
   store-rail лист остаётся как был — тарифы и Pay. Альтернатива: оставить, «Change» перевести, номер — литерал.

## Не в объёме
- `features/booking`, `screens/booking`, `screens/chat-thread` (решение 1), профиль кроме строки промокода.
- Названия продуктов в консолях сторов (в приложении не показываются; цена — `displayPrice` стора, уже в валюте
  покупателя).
- Нативные объявления языков, включение флага — шаг 4.

## Заметка (не i18n)
`CouponTicket` пишет «Half price …» при любом `pct`: если кампания даст не 50 %, подпись соврёт. Не трогаю —
отмечу в `TECH-DEBT.md`, если владелец не скажет иначе.

## Общие файлы
`app/i18n/namespaces.ts`, `.eslintrc.js`, `translations.test.ts`, `shared/config/locales/*` — с `0163`, `0164`,
`0165`. `price.perMinute` беру ровно таким, как в `0164` (тот же текст во всех 24), — слияние без спора.
