# AURAT-0212-005 — Spec (на одобрение владельцу; исполнение — после «да»)

Type: task (веб, денежный путь). Status: draft. Priority: P1.
Slave: `slave-1`, ветка `feature/AURAT-0212-web-stripe-embedded-checkout`.
Основания: `AURAD-0023` (поправка 2026-11-11), BFF `AURAT-0211-005` (одобрена), контракты
`v0.33.0`, база — `AURAT-0208`. Контекст — `004`.

## Что

После «Pay $X» в шторке Book открывается форма Stripe — прямо в шторке. Человек не уходит с сайта.
Карта, 3DS, Apple Pay, Google Pay и Link завершаются на месте. Дальше всё как сейчас: «Still
confirming…», затем бронь с баланса тем же ключом, затем Booked. Банковский метод (iDEAL,
Bancontact) уходит к банку и возвращается на нынешнюю `/checkout?payment=`. Деньги по-прежнему
зачисляет только BFF по данным Stripe: `onComplete` формы — лишь повод спросить статус.

## 1. Контракты и пакеты

- `@aura/contracts` `v0.32.0` → `v0.33.0`, **отдельным коммитом** (правило 6).
- `@stripe/stripe-js` `10.2.0` и `@stripe/react-stripe-js` `7.0.1`, точные версии. Release train
  `endive` совпадает с API BFF (`2026-09-30.endive`).
- Код формы — в отдельном чанке (`React.lazy`), он грузится только на шаге оплаты.
- Stripe.js загружается с `js.stripe.com` через `@stripe/stripe-js/pure`. Импорт сам скрипт не
  вставляет, в бандл скрипт не попадает.
- Экземпляр Stripe — один на публичный ключ, хранится в модуле `features/pay/model`.

## 2. Порт и адаптер

- `TopUpProvider.startCard` теперь отвечает видом страницы оплаты:
  `{ kind: 'redirect', redirectUrl } | { kind: 'embedded', clientSecret, publicKey } | null`.
  `null`, как и раньше, значит «карта здесь выключена» (404).
- `card-provider` всегда просит `ui: 'embedded'`. Ответ разбирается по `CardTopUpResponse`
  (`Schema.parse`).
- Фейк отвечает `kind: 'redirect'` на `/psp-sandbox` (решение 2А).
- `status` и `cancel` не меняются. 400 / 409 / 503 / сеть на старте → `failed`, ключ брони цел.
- `clientSecret` живёт только в памяти, в состоянии `usePay`. Его нет в `sessionStorage`
  (`pending-store`), в URL и в логах. Запись попытки в `sessionStorage` та же, что сейчас: она нужна
  для возврата от банка и для Back.

## 3. Поток в шторке (решение 1А)

`usePay` получает новую фазу `form`. Переходы и ориентиры в шторке:

| Событие | Что происходит |
|---|---|
| «Pay $X» | `savePending` → `startCard`; пока ждём ответ — «Booking…», как сейчас |
| `embedded` | фаза `form`: шаг оплаты вместо выбора, форма Stripe монтируется в шторке |
| `redirect` | `loadPage(redirectUrl)` — страница Stripe (фейк) или своя `/checkout?payment=<id>` (оплачено и ждёт) |
| `null` | строка «Top up in the Aura app», карта больше не предлагается (как сейчас) |
| `onComplete` | фаза `paying` → `settleTopUp` (опрос статуса) → Booked / нынешние исходы |
| Stripe.js не загрузился | `cancel` в фоне, шаг выбора, `error.failed` («That didn’t go through…») |
| Банк | Stripe уводит страницу к банку; возврат на `/checkout?payment=<id>` — нынешний путь |
| Back из банка (bfcache / свежая загрузка) | как сейчас (041): `/checkout?…&cancelled=1` |

**Шаг оплаты.**
- В шапке шторки появляется «←» с подписью `book-sheet` `pay.back` («Back to booking»). Под шапкой —
  только форма. Выбор времени, итог и кнопки скрыты; ступени воронки (`/match`) тоже не двигаются.
- Пока форма грузится, показывается строка `pay` `form.loading`.
- Desktop: та же модалка `lg`, форма прокручивается внутри.
- Телефон: шторка во весь экран. Это новый вариант `Sheet` (`fill`): высота — вся видимая область,
  CSS только на токенах.
- Свайп вниз по шапке работает как ×. Внутри iframe Stripe жесты шторке не достаются, и это
  правильно.

**Назад «←».** Вызывается `cancel` и ждётся ответ, кнопка в это время — «Booking…»:
- `cancelled` → шаг выбора, молча;
- `credited` → бронь, Booked (человек успел заплатить);
- `pending` → опрос, «Still confirming…»;
- `declined` → шаг выбора с `error.declined`.

## 4. Закрытие шторки, пока открыта форма (решение 3)

× / Esc / фон / свайп во время `form`:
- шторка закрывается сразу, `cancel` уходит в фоне;
- `cancelled` / `declined` / `credited` — запись попытки стирается. При `credited` деньги лежат на
  балансе, шапка обновляется, сессия не бронируется: человек сам закрыл шторку;
- `pending` или нет ответа — запись остаётся. Следующее открытие шторки этого советника доводит
  попытку на `/checkout?…&cancelled=1` — это путь 041, деньги не теряются.

Пока идёт `paying` / `confirming`, шторка не закрывается, как сейчас.

## 5. Истечение формы (решение 4)

- Сессия живёт 60 мин (`CHECKOUT_TTL_MS` BFF). Веб держит то же число в `config/pay.ts`
  (`CARD_FORM_TTL_MS`) и отсчитывает его от ответа старта.
- Когда время вышло, а форма всё ещё открыта, вызывается `cancel`, и его ответ обрабатывается как
  при «←».
- `cancelled` → шаг выбора со строкой `error.expired`. Следующее «Pay» — новая попытка с новым
  `paymentId`, ключ брони тот же.
- Новую форму сам веб не открывает: если человек ушёл от экрана, сессии Stripe не плодятся.

**Повторный маунт.** Форма монтируется один раз на ответ старта. Повторного старта тем же
`paymentId` веб не делает: «←» и истечение закрывают сессию, новое «Pay» — новый `paymentId`.
Поэтому 409 `card_top_up_payment_conflict` в нормальном потоке не возникает. Если он всё же придёт —
`failed`.

## 6. Заголовки (`deploy/web/headers.conf`)

CSP — добавляется по списку Stripe (`004`):

| Директива | Добавляется |
|---|---|
| `script-src` | `https://js.stripe.com https://*.js.stripe.com https://checkout.stripe.com` |
| `frame-src` | `https://js.stripe.com https://*.js.stripe.com https://hooks.stripe.com https://checkout.stripe.com https://link.com https://*.link.com` |
| `connect-src` | `https://api.stripe.com https://checkout.stripe.com https://link.com https://*.link.com` |
| `img-src` | без изменений: `https:` уже покрывает `*.stripe.com` и `*.link.com` |

Комментарий в шапке файла дополняется: что грузит Stripe и почему `maps.googleapis.com` не нужен.

**Permissions-Policy** — новый заголовок
`payment=(self "https://js.stripe.com" "https://checkout.stripe.com")`, по документации Stripe о
Google Pay. Без него Chrome на Android может не показать Google Pay. Другие возможности заголовок не
трогает.

Проверка: тест Vitest читает `deploy/web/headers.conf` и требует источники Stripe в трёх директивах
и `Permissions-Policy`. `build.sh` содержимое CSP не проверяет, поэтому проверка — в тесте.

## 7. Строки — `pay` и `book-sheet`, сразу на 24 языках

| Namespace · ключ | English | |
|---|---|---|
| `pay` `topUp.note` | `Secure payment by Stripe — you may be charged in your local currency` | меняется |
| `pay` `form.loading` | `Loading the secure payment form…` | новая |
| `pay` `error.expired` | `The payment form timed out. Nothing was charged — press Pay to start again.` | новая |
| `book-sheet` `pay.back` | `Back to booking` | новая (`aria-label` «←») |

`Stripe` — бренд, не переводится. Язык самой формы задаёт `locale` сессии: BFF берёт его из
`?lang`. Платёжные тексты — на вычитку носителю до маркетинга (`AURAI-0010` решение 7), задачу это не
держит.

## 8. Тесты (Vitest, слот)

`EmbeddedCheckout` и `loadStripe` — моки.

- `psp.test.tsx` (мок провайдера):
  - старт → форма → `onComplete` → Booked без перехода;
  - «←» → `cancel` → шаг выбора; `credited` после «←» → Booked;
  - × при открытой форме → шторка закрыта, `cancel` вызван;
  - `kind: 'redirect'` в режиме embedded → `loadPage` с адресом `/checkout?payment=`;
  - истечение (фальшивые таймеры) → `cancel` → строка `error.expired`;
  - Stripe.js не загрузился → `failed` и `cancel`;
  - 404 старта → «Top up in the Aura app»;
  - строки `topUp.note` и `form.loading`.
- `card-provider.test.ts`: тело старта с `ui: 'embedded'`; разбор обоих `kind`; 404 → `null`.
- `fake-provider.test.ts`: `kind: 'redirect'`.
- Тест заголовков: п. 6.
- Остальные тесты `AURAT-0208` (возврат, Back, «Still confirming…», `processing`) остаются зелёными
  без правок по смыслу.

## 9. Порядок

1. Подъём контрактов `v0.33.0` — первым, отдельным коммитом.
2. Остальное (п. 1–8) — одним заходом в слоте: lint, typecheck, test, build. Проверка маркера
   фейка в `build.sh` остаётся.
3. Манор — после выката `AURAT-0211` на bff-dev (там нужен `pk_test_` в Coolify). Сначала мёрж с
   вопросом владельцу, затем проверка из шага 001. До выката BFF web-dev с новым вебом получит от
   старого BFF `{ redirectUrl }` без `kind`. Схема `v0.33.0` такой ответ не примет, будет `failed`
   («That didn’t go through»), без списаний. Поэтому мёрж веба — только после мёржа и выката
   `AURAT-0211`.

## Решения (на одобрение)

| # | Вопрос | Варианты | Рекомендация |
|---|---|---|---|
| 1 | Где форма | **А** — шаг внутри шторки Book, на телефоне во весь экран; Б — отдельный диалог поверх | **А** (как в 001): один диалог за раз — правило дизайн-системы |
| 2 | Фейк для dev | **А** — hosted-фейк `/psp-sandbox` как есть (порт отвечает `redirect`); Б — фейковая встроенная форма | **А**: путь возврата всё равно нужен для банков |
| 3 | × при открытой форме | **А** — закрыть сразу, `cancel` в фоне; заплатил в последний миг — деньги на балансе, незакрытое (`pending`) доводит 041; Б — × работает как «←»: шторка остаётся, ждёт `cancel`, при `credited` бронирует | **А**: × всегда закрывает; «←» — для тех, кто хочет вернуться к выбору |
| 4 | Форма истекла (60 мин) | **А** — `cancel`, шаг выбора со строкой «форма устарела, нажмите Pay»; Б — сразу новая форма с новым `paymentId` | **А**: без новых сессий Stripe, пока человека нет у экрана |

## Вне задачи

- BFF и контракты — `AURAT-0211`. Удаление hosted на BFF — отдельная задача после мёржа этой; ID
  выдаёт `aura-app-manor`.
- Branding формы в Dashboard Stripe (цвета, шрифт, лого Aura) — настройка владельца, кода нет.
- `web.aura-app.cc` в live — с воротами `AURAD-0023`.
- Сохранённые карты, своя форма на Payment Element, строки 011 / 042.

## Проверка в маноре (после мёржа и выката `AURAT-0211` на bff-dev)

web-dev против bff-dev, sandbox:
- `4242 4242 4242 4242` → Booked без ухода с сайта;
- `4000 0025 0000 3155` → 3DS поверх страницы, затем Booked;
- `4000 0000 0000 9995` → отказ в форме, другая карта проходит;
- «←» и × — ничего не списано, сессия в Stripe `expired`;
- iDEAL → банк и возврат на `/checkout`, Booked;
- Google Pay (Chrome Android) и Apple Pay (Safari 17+ / iOS 17+);
- язык формы = язык веба; `test+location_NL@example.com` → евро в форме, USD на балансе;
- в консоли нет нарушений CSP;
- повтор старта под `rk_test_` (`AURAT-0211-008` п. 2) — на стороне BFF, веб его не делает (п. 5).
