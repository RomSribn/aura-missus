# AURAI-0013 — Платёжный провайдер для aura-web: комиссия, подключение, одобрение ниши

Date: 2026-11-11 · Источники проверены 2026-11-11 · Продолжает `AURAI-0006` (раздел PSP), закрывает
открытый вопрос 1 `AURAF-0009` на уровне рекомендации, решение — за владельцем.

## Decision

Рекомендация: **Stripe на Silvermind OÜ (Эстония) через Stripe Checkout**. Montonio — запасной вариант
и дешёвые банковские платежи. Adyen или Stripe IC+ — когда объём оправдает переход. High-risk-эквайер —
только если Stripe откажет.

## Context

- Веб уже готов принять PSP: порт `TopUpProvider` в `features/pay`, `startCard({ amountMinor,
  paymentId, returnUrl }) → { redirectUrl }`, маршрут возврата `/checkout`, «Still confirming…»
  с опросом. Сейчас работает фейковый провайдер за `VITE_PSP_ENABLED` (`AURAT-0108`, `AURAD-0019` Р4).
  BFF и контракты ждут выбора провайдера (`AURAF-0009`).
- В `AURAI-0006` (2026-10-18) PSP упирался в юрлицо. Теперь юрлицо есть: **Silvermind OÜ**, Эстония,
  рег. код `17345387`. Владелец не резидент Эстонии (`AURAI-0014`).
- Рынок — ЕС, 24 языка. Кошелёк ведётся в USD minor units (`AURAD-0002`), возвраты при отмене идут
  на баланс (`AURAD-0009`, `CHECKOUT.md` правило 6). Советник — персона, за которой стоит пул
  чаттеров (`AURAD-0001`).
- Ниша — платные консультации экстрасенсов и таро. Эквайеры считают её спорной из-за чарджбэков
  («услуга не соответствует описанию») и репутационного риска. MCC назначает эквайер: обычно
  **7996** (Visa: «… Fortune Tellers») или **7299** (Miscellaneous personal services).

## Research / Analysis

### 1. Возьмут ли нишу

| Провайдер | Ниша | Что сказано (проверено 2026-11-11) |
|---|---|---|
| **Stripe** (EE) | **Разрешена** | В списке Restricted Businesses (ред. **2026-09-22**) «Psychic services and fortune tellers» запрещены **только в JP, MX, TH**. В общих списках prohibited и restricted ниши нет. Список «не исчерпывающий». Kasamba и Purple Garden (группа Ingenio; EU-представитель — adviqo GmbH, это Questico / Viversum) прямо называют своими процессорами «PayPal or Stripe» |
| **Adyen** | **Restricted (R)** | «Services associated with pseudoscience (e.g. clairvoyance, horoscopes)» — R и для merchant, и для platform. До онбординга нужны доп. документы. Есть минимальный счёт, сумма зависит от отрасли и не публикуется (список ред. 2025-11-13) |
| **Montonio** (EE) | Не указано | Своего списка запретов не публикует. **Карты проводит через Adyen**, а у Adyen ниша R → ответ зависит от андеррайтинга Adyen. Спросить письменно |
| **Mollie** | Не проверено | Страница со списком отдаёт 403, видна только общая оговорка о «reputational risk». Онбординг эстонских компаний не подтверждён. По цене Mollie всё равно дороже Stripe (см. §2) |
| MakeCommerce / Maksekeskus (EE) | **Запрещена** | «fortune telling» в списке forbidden fields |
| Revolut Business | **Запрещена** | «Fortune-tellers» в prohibited (по выдаче поиска; сама страница отдаёт 403) |
| Paddle (MoR) | **Запрещена** | «clairvoyance, horoscopes, fortune-telling». MoR-провайдеры (Paddle, Lemon Squeezy) — не вариант |
| PayPal / Braintree | Не подтверждено | AUP отдают 403. В AUP Braintree (2017) «fortune tellers» упомянуты. При этом Ingenio использует PayPal, значит работать с нишей можно, вероятно после pre-approval. `AURAI-0006` пишет «запрещена» — это не подтвердилось ни в одну сторону |
| Worldline | Restricted | «Fortune Tellers/Astrologers» (PDF 2015 года, устарел) |
| Ecommpay, Barion | Запрещена | По выдаче поиска |
| High-risk (Corepay и др.) | Берут | «Psychic service merchants pay premium rates». Ставок не публикуют, резерв типичен. Corepay ориентирован на США (нужен EIN) |

**Кошельки на вебе.** В Acceptable Use Guidelines Apple Pay for the web ниши нет. Единственная
оговорка близко к нам — «purchase or transfer of currency» без одобрения Apple; пополнение
внутреннего баланса Aura валютой не является, но при сомнении спросить. В Google Pay API AUP
(действует с 2026-10-21) ниши тоже нет, ограничений для веба нет. Запрет Google Pay на цифровые
услуги касается Android-приложений (`AURAI-0006`), на сайт он не распространяется.

**Пороги схем.** С 2026-04-01 Visa VAMP считает merchant excessive при **1,5 %** (fraud + disputes),
но только от 1 500 случаев в месяц — нас это коснётся не скоро. Ближе другой порог: Stripe называет
excessive **> 0,75 %** диспутов и может включить мониторинг ещё до этого порога, если рост резкий.
Регистрация в схемах (как для 5967 / 7995 / 7273) у MCC 7996 / 7299, по нашим данным, не требуется,
но первоисточник это исследование не проверяло.

### 2. Комиссия

Тарифы для эстонской компании (EUR):

| | Карты ЕЭЗ (потреб.) | Премиум / корп. ЕЭЗ | Не-ЕЭЗ | Прочее |
|---|---|---|---|---|
| **Stripe** | **1,5 % + €0,25** | 2,8 % + €0,25 | UK 2,5 %, intl 3,15 % + €0,25; **+2 % при конвертации** | Диспут **€20** (+€20 за оспаривание, вернут при выигрыше). Checkout и Payment Links бесплатно. IC+ по запросу |
| **Montonio** Core | **1,29 % + €0,20** | — | — | **€14,99/мес.** Банковский платёж €0,05. Тариф Starter: €11,99/мес., 1,49 % + €0,25, банк €0,20 |
| Mollie | 1,80 % + €0,25 | 2,90 % + €0,25 | 3,25 % + €0,25 | — |
| Adyen | IC++ + 0,60 % + $0,13 | IC++ | IC++ | Минимальный счёт «depending on industry» |

Локальные методы через Stripe: iDEAL | Wero **€0,29** (NL), Bancontact 1,4 % + €0,25 (BE),
BLIK 1,6 % + €0,25 (PL), EPS 1,6 % + €0,25 (AT), Przelewy24 2,2 % + €0,25, Pay by Bank
0,5 % + €0,25 (до €5), Revolut Pay 1,5 % + €0,25. Klarna (2,99–4,99 %) для пополнений не нужна.

Комиссия с одного пополнения картой ЕЭЗ (потребительской):

| Пополнение | Stripe | Montonio Core | Mollie | Adyen (оценка*) | iDEAL через Stripe | Для сравнения: Play 15 % |
|---|---|---|---|---|---|---|
| €15 | €0,48 (3,2 %) | €0,39 (2,6 %) | €0,52 (3,5 %) | ≈ €0,27 (1,8 %) | €0,29 (1,9 %) | €2,25 |
| €30 | €0,70 (2,3 %) | €0,59 (2,0 %) | €0,79 (2,6 %) | ≈ €0,42 (1,4 %) | €0,29 (1,0 %) | €4,50 |
| €50 | €1,00 (2,0 %) | €0,85 (1,7 %) | €1,15 (2,3 %) | ≈ €0,62 (1,2 %) | €0,29 (0,6 %) | €7,50 |

\* Для Adyen interchange по IFR (дебет 0,2 %, кредит 0,3 %) плюс сборы схем — грубо 0,4–0,5 %,
и ещё $0,13 ≈ €0,11. Минимальный счёт в оценку не входит.

Выводы:

- Против стора веб экономит **~12–13 п.п.** с каждого пополнения при любом провайдере. Разница между
  самими провайдерами — десятые доли процента.
- Montonio Core выгоднее Stripe примерно на 0,4 п.п. на пополнении €30, но из-за абонплаты
  окупается только с **~130 пополнений по €30 в месяц** (≈ €4 тыс. оборота). Starter не
  окупается никогда: та же ставка, что у Stripe, плюс абонплата.
- **Диспуты стоят дороже, чем разница в ставках.** Проигранный диспут — это €20 плюс сумма платежа.
  При доле диспутов 0,5 % и чеке €30 это €0,25 на каждое пополнение, то есть **+0,8 % оборота**.
  При 1 % — +1,7 %. В этой нише главные рычаги — профилактика диспутов и размер чека, а не выбор
  самого дешёвого провайдера.
- Фиксированная часть (€0,20–0,25) заметна на малых чеках. Минимальное пополнение от €20–25 держит
  ставку около 2 %. Viversum, лидер ниши в DE, работает так же: предоплаченный баланс,
  пополнения €9,90–99,90.
- **Валюта.** Если брать с карты ЕЭЗ доллары, Stripe возьмёт +2 % при зачислении в EUR, а банк
  покупателя — ещё 1–3 % за конвертацию. Это минус к конверсии и источник диспутов «не узнаю сумму».
  Мультивалютное зачисление в USD у Stripe в ЕС есть, но нужен отдельный USD-счёт, а проблему банка
  покупателя оно не снимает.

### 3. Простота подключения

| | Онбординг | Подходит к порту `AURAT-0108` | Кошельки и методы | Языки checkout |
|---|---|---|---|---|
| **Stripe** | Самостоятельный, онлайн. Stripe — партнёр e-Residency, критерий «OÜ registered». Для нерезидента-директора и спорной ниши ждать доп. KYC, возможен резерв | **Один к одному**: `startCard → Checkout Session.url`, вебхук → BFF; официальный `stripe-node` для NestJS | Apple Pay и Google Pay на той же hosted-странице; iDEAL / BLIK / Bancontact / EPS — в одной интеграции | 23 из 24: **нет `ga`** (уйдёт в `en`). `pt` в таблице Stripe помечен как бразильский |
| Montonio | Самостоятельный, эстонский саппорт | Hosted-страница есть, интеграцию нужно писать | Карты и кошельки через Adyen; банки сильны в Балтии, PL, FI | Не проверялось |
| Mollie | Самостоятельный, но EE не подтверждён | Hosted-страница есть | Широкий набор | Не проверялось |
| Adyen | Через продажи, документы для R, минимальный счёт | Интеграция тяжелее | Всё | Всё |
| High-risk | Через брокера, резерв, часто нужен US-entity | Часто устаревшие шлюзы | Ограниченно | — |

## Recommendation

1. **Stripe — основной провайдер для aura-web.** Ниша для ЕЭЗ не ограничена (список от 2026-09-22),
   и Stripe реально обслуживает крупнейших игроков ниши. Среди провайдеров с самостоятельным
   онбордингом у него самая низкая ставка для карт ЕЭЗ, если не считать Montonio, который окупается
   только на объёме. Stripe ложится на готовый порт без переделок, закрывает в одной интеграции
   кошельки и дешёвые локальные методы и поддерживает 23 из 24 языков.
   **Предусловие до любого кода BFF:** активировать аккаунт Silvermind OÜ с честным описанием
   («live chat consultations with psychics / tarot readers, prepaid balance, for entertainment»),
   получить live-платежи и письменный ответ поддержки, что бизнес поддерживается. Скрывать нишу
   нельзя: закрытие аккаунта с удержанными деньгами обходится дороже любой комиссии.
2. **Рычаги экономии, которые весят больше выбора провайдера:**
   - минимальное пополнение €20–25;
   - локальные банковские методы там, где они доминируют: iDEAL €0,29, BLIK, Bancontact. Они
     дешевле и не дают чарджбэков;
   - цены в **EUR** для ЕС, без долларов на карте;
   - профилактика диспутов: 3DS на всех картах ЕЭЗ (SCA обязательна и переносит ответственность
     за fraud на банк), понятный дескриптор (`AURA-APP.CC`), чек на e-mail, возврат
     неистраченного баланса на карту по запросу — Terms §07 уже обещает это для покупок в сторе.
     «Entertainment only», 18+ и отказ от гарантий уже есть в Terms §03 и §05.
3. **Montonio — план B.** Подключать, если Stripe откажет, или вторым рельсом для банковских
   платежей Балтии. До этого письменно спросить у Montonio про нишу: карты идут через Adyen,
   а там ниша в статусе R.
4. **Позже, на объёме ~€50–100 тыс. в месяц:** запросить у Stripe IC+ или перейти на Adyen
   (IC++ + 0,60 % + $0,13). Это −0,5…0,8 п.п. на картах.
5. **Не брать:** PayPal на старте (статус ниши не ясен, дороже карт), Paddle и другие MoR, Revolut,
   MakeCommerce, Ecommpay, Barion. Mollie не даёт преимуществ. High-risk — только запасной вариант:
   выше ставка, резерв на месяцы.

### Риски

- **Модель персон (`AURAD-0001`) уже раскрыта.** Terms §05 и Privacy §01 прямо говорят, что
  советники — персоны, отвечают члены команды и под одним советником может отвечать несколько
  человек. В Terms §03 и в подвале — «entertainment only», 18+ (опубликовано: `AURAT-0042-118`,
  `AURAT-0202-005`). Андеррайтеру показываем эти пункты, а бизнес для Stripe описываем той же
  формулировкой.
- **Условия знают только сторы.** Terms §06–07 («credits you buy through the app store»,
  «Purchases are processed by …») и раздел Privacy «Payments, balance and sessions» ничего не
  говорят об оплате на вебе. До активации Stripe нужно добавить: оплату картой на вебе через Stripe,
  возврат неистраченного на карту по запросу и Stripe в список получателей данных. Refund policy
  на сайте эквайер смотрит обязательно.
- **Баланс — закрытый.** Тратится только на услуги Aura и в деньги не выводится, поэтому это не
  e-money. Добавлять вывод баланса без лицензии нельзя.
- **Stripe может закрыть аккаунт в любой момент.** Держать долю диспутов < 0,75 % и иметь
  наготове план B.

## Implementation Notes

После решения владельца (`AURAD`) задачи разносятся по манорам через `wts-task`:

- **BFF** (`aura-bff-manor`):
  - модуль Stripe: `POST /v1/wallet/top-ups` создаёт Checkout Session с параметрами:
    - `mode=payment`;
    - сумма — из таблицы продуктов пополнения; продукт определяет зачисление, как правило 1
      (`AURAD-0010`);
    - `client_reference_id` и `metadata` с `paymentId` и `userId`, idempotency key;
    - цена — `price_data` в USD без `currency_options`: валюту из `currency_options` Adaptive
      Pricing не пересчитывает;
    - `payment_method_types` не передавать: методы включаются в Dashboard (dynamic payment
      methods);
    - `success_url` — `…/checkout?session_id={CHECKOUT_SESSION_ID}`;
    - `expires_at` — короче суток, которые стоят по умолчанию;
    - `consent_collection.terms_of_service: required` — согласие с Terms станет доказательством
      в диспуте;
    - по желанию `integration_identifier` (например `web-top-up`) — для метрик в Checkout studio;
  - зачисление — одна идемпотентная функция по ID Checkout Session. Её вызывают и вебхук, и
    `GET /v1/wallet/top-ups/:id`, когда клиент вернулся: Stripe советует оба пути, потому что вебхук
    может задержаться. Зачислять только при `payment_status = paid`;
  - вебхуки → записи в ledger по образцу `STORE_REFUND`:
    - `checkout.session.completed`;
    - `checkout.session.async_payment_succeeded` и `checkout.session.async_payment_failed` — для
      отложенных методов: Pay by Bank, а BLIK может отказать уже после подтверждения;
    - `checkout.session.expired`;
    - `charge.refunded`, `charge.dispute.*`.

    Ответить 2xx сразу после проверки подписи, остальную работу отдать в очередь: прежде чем
    вернуть клиента на сайт, Stripe ждёт ответа на `completed` до 10 с;
  - сумму и валюту, в которых заплатил покупатель, брать из `presentment_details`: сама сессия
    остаётся в USD. Хранить их для чека, поддержки и возврата;
  - `GET /v1/wallet/top-ups/:id` для «Still confirming…» (уже заложен в `AURAT-0108-005`);
  - ключ — restricted, с минимумом прав; он и секрет вебхука хранятся в секретах BFF. Вебу ключ не
    нужен;
  - TECH-DEBT #7 (append-only `ledger_entries`) уже закрыт в `AURAT-0027` (триггер в БД); на
    2026-11-11 это исправление к прежней версии этой строки. Контракты — в `@aura/contracts`.
- **Веб** (`aura-web-manor`):
  - настоящий адаптер `TopUpProvider`: `startCard` → BFF → `session.url`;
  - отдельный адаптер `wallet` не нужен: Checkout сам показывает Apple Pay и Google Pay;
  - в Checkout передаётся `locale` из i18n, для `ga` — `en`;
  - файл Apple Pay на нашем домене не нужен, пока оплата идёт на странице Stripe («Checkout
    supports Apple Pay and Google Pay with no integration changes»). Он понадобится, только если
    перейти на embedded или Elements, — тогда его отдаёт `web.aura-app.cc` (`AURAD-0020`).
- **Dashboard (sandbox, потом live):**
  - включить Adaptive Pricing;
  - методы: карты, Apple Pay, Google Pay, Link, iDEAL, Bancontact, BLIK. Остальные — только после
    отдельной проверки. SEPA Debit не включать: деньги приходят через дни, а плательщик может
    отозвать списание в течение 8 недель;
  - у iDEAL и Bancontact нет диспутов: клиент подтверждает платёж в своём банке. Срок возврата —
    до 180 и до 730 дней соответственно;
  - брендинг Checkout, публичные данные и ссылка на Terms (нужна для `consent_collection`).
- **Тест в sandbox:**
  - карты: `4242 4242 4242 4242` — успех, `4000 0025 0000 3155` — 3DS, `4000 0000 0000 9995` — отказ;
  - банковские методы: «Fail test payment» на их странице;
  - валюта покупателя: email вида `test+location_NL@example.com` — так Stripe предлагает проверять
    показ местной валюты;
  - вебхуки локально: `stripe listen --forward-to` (Stripe CLI).
- **До активации:** страницы Terms и Refund policy, дескриптор, support URL.
- **Приложение не меняется:** в сторах остаётся IAP и Play Billing (`AURAI-0006`).
- **Сверка со Stripe** — `stripe_implementation_planner`, 2026-11-11, sandbox `Silvermind OU
  sandbox`. Его вывод: Checkout на странице Stripe с переходом, плюс Link, dynamic payment methods
  и Adaptive Pricing — то же, что выше. Managed Payments отпал: Stripe не берёт услуги с участием
  человека («If your service involves human intervention (such as live 1-1 coaching), it doesn't
  qualify»).

### Вопросы владельцу

1. Stripe основным провайдером — да?
2. Валюта на вебе: EUR (продукты «€X → $Y на баланс») или USD?
3. Возврат по запросу на карту или только на баланс?
4. Оговорка про персоны в условиях — нужна ли и в какой формулировке?

### Поправки к `AURAI-0006`

- Юрлицо есть: Silvermind OÜ, Эстония.
- PayPal не подтверждён как «запрещён»: Ingenio его использует.
- У Stripe EE premium-карты ЕЭЗ стоят 2,8 %, international — 3,15 %.

## Решения владельца (2026-11-11)

1. **Stripe — основной провайдер, если Stripe примет бизнес.** Условие — активация аккаунта
   Silvermind OÜ с честным описанием (черновик ниже). Если Stripe откажет — план B из
   Recommendation (Montonio, затем high-risk).
2. **USD, как в мобайле.** В приложении баланс долларовый, а стор списывает в местной валюте
   (`CHECKOUT.md` правило 4: «Charged by Apple as CA$36.49»). На вебе то же даёт **Stripe Adaptive
   Pricing**:
   - цена в USD, покупатель в Checkout видит и платит в своей валюте (EUR, PLN …);
   - на баланс зачисляется ровно USD-цена, без пересчёта в BFF;
   - бизнес за Adaptive Pricing платит 0 %, конвертацию (2–4 %) платит покупатель — она входит в
     его местную цену, как у стора. Возврат — в валюте платежа по тому же курсу.
   Условие Stripe: USD должен быть валютой зачисления. Нужны multi-currency settlement и
   USD-счёт OÜ. Плата за зачисление в неосновной валюте — ≈1 %: так было в уведомлении для ЕЭЗ
   2023 года, с октября 2026 её берут при зачислении; точную ставку уточнить у Stripe. Без
   USD-зачисления остаётся простое списание в USD с конвертацией в EUR — **+2 %**, а покупатель
   видит в выписке доллары и платит ещё и конвертацию своего банка. Итог: USD на вебе стоит
   ≈1–2 % оборота веба сверх тарифа за карту.
3. **Возвраты — как в мобайле.** Отменённая сессия возвращается на баланс (`AURAD-0009`).
   Неистраченный баланс по запросу в support возвращается на карту через Stripe — Terms §07 уже
   обещает это для покупок в сторе. Если пойдут диспуты через Stripe — пересмотреть.
4. **Оговорка про персоны не нужна.** Персоны и «entertainment only» уже раскрыты в Terms §03, §05
   и Privacy §01 (см. «Риски»). Вопрос был задан зря: при написании исследование не сверило
   опубликованные условия. Остаётся одно — дописать в условия оплату на вебе (см. «Риски»).

### Следующие шаги

1. **Владелец:** активировать Stripe для Silvermind OÜ (KYC директора, банковский счёт); открыть
   USD-счёт, если его нет. Логин Stripe — адрес на домене компании, `billing@silvermind.cc`
   (почта `silvermind.cc` тоже на Spacemail, публичный адрес — `contact@silvermind.cc`; в брейне
   этот домен не описан). Почему не `aura-app.cc`: аккаунт принадлежит компании, домен компании
   переживёт продукт, письма о деньгах не смешиваются с ящиком поддержки, а под тем же логином
   встанут будущие аккаунты Silvermind OÜ. Платежи студии за разработку, если появятся, — отдельный
   аккаунт той же компании: другой бизнес, другие MCC и проверка. Отдельного «аккаунта компании», в
   котором потом создают проекты, в Stripe нет. Аккаунт — это и есть проект: у каждого свои сайт,
   описание, строка в выписке, проверка и выплаты, а юрлицо во всех одно. Первый аккаунт, который
   создаётся при регистрации, — сразу аккаунт Aura. Следующий создаётся через «New account» в
   переключателе аккаунтов. Объединить аккаунты можно в организацию — это общие отчёты и команда,
   платежей она не принимает. Публичная почта поддержки в
   Stripe — `support@aura-app.cc`. Сайт бизнеса в анкете — `https://aura-app.cc`, а не
   `silvermind.cc`: там студия разработки и ни слова об Aura, с описанием «чтения таро» это не
   сойдётся. `web.aura-app.cc` пока не открывается (DNS-записи нет, 2026-11-11). Связь Aura с
   компанией уже есть в Terms («Aura is provided by Silvermind OÜ»). Оба домена и ящики — на
   автопродлении, 2FA и на почте, и в Stripe.
   При регистрации: страна — Эстония (после создания не меняется), «Full name» — имя человека,
   владельца входа, а не бренд. При активации: юрлицо — Silvermind OÜ, публичное название — Aura,
   строка в выписке клиента (statement descriptor) — узнаваемая, например `AURA-APP.CC`:
   незнакомое списание клиент чаще оспаривает через банк.
   Нишу в описаниях не смягчать: узнав её позже, Stripe закроет аккаунт и может придержать выплаты.
   Короткое описание для первого шага анкеты («What does your business do?»):
   > Aura is a chat app for live tarot, astrology and psychic readings for adults (18+), for
   > entertainment only. Customers buy prepaid credits on our website as one-off top-ups and
   > spend them on chat sessions they book in advance.

   В рекомендациях после этого шага оставить «Accept online payments». Снять «Send invoices»: это
   счета клиентам со ссылкой на оплату, 0,4% с оплаченного счёта, для пополнений через Checkout
   не нужно. Снять и «Collect tax» (Stripe Tax, 0,5% с транзакции через Checkout): включать после
   шага 4.
   Первый шаг анкеты можно пройти сразу, а активацию (данные компании, документ, счёт) отправлять
   после шага 2: сейчас в Terms §06 покупки только «through the app store», и проверяющий
   сверит с этим описание.
   Черновик описания бизнеса для анкеты и вопроса в поддержку:
   > Aura is a chat app for live text readings — tarot, astrology and psychic readings — for
   > adults (18+), offered for entertainment purposes only (Terms §03). Advisors are personas
   > presented by us; readings are written by members of our advisor team (Terms §05). Customers
   > buy prepaid credits in USD (one-off top-ups) and spend them on chat sessions they book in
   > advance; unused credits are refundable on request (Terms §07). Website: aura-app.cc; card
   > top-ups will run in our web app at web.aura-app.cc. Android app on Google Play. Operated by
   > Silvermind OÜ, Estonia.
2. Обновить Terms §06–07 и Privacy под оплату на вебе — до активации. На вебе продаёт сама
   Silvermind OÜ, поэтому до покупки на сайте Aura нужны данные продавца: рег. код `17345387`,
   адрес, email и телефон (Директива 2011/83/EU ст. 6(1)(b–c); 2000/31/EC ст. 5). В копиях Terms
   и Privacy в брейне — только «Silvermind OÜ, a private limited company registered in Estonia».
   Телефон — тот же открытый вопрос, что в `AURAI-0014` §4.
3. Решение записано — `AURAD-0023`, задачи выданы 2026-11-11: BFF `AURAT-0207`
   (`aura-bff-manor`), веб `AURAT-0208` (`aura-web-manor`), условия `AURAT-0209` (`aura-app-manor`).
   Разработка идёт на sandbox до активации; live — после ворот `AURAD-0023`. Adaptive Pricing работает только с Checkout
   Session, а не с Payment Intents + Elements, и несовместим с `capture_method: manual` — это
   совпадает с `startCard → redirectUrl`.
4. **НДС на вебе в этом исследовании не разобран.** В сторах НДС с продаж в ЕС платит стор, на
   вебе — Silvermind OÜ. До запуска оплаты нужно выяснить:
   - нужна ли регистрация по НДС и OSS;
   - чья ставка — Эстонии или страны покупателя. Это зависит от того, считается ли чтение с живым
     советником электронной услугой (Регламент 282/2011 ст. 7);
   - когда начислять НДС на предоплаченные кредиты (ваучеры, Директива 2006/112/EC ст. 30a–30b);
   - что писать в чеке;
   - нужен ли Stripe Tax. Он берёт 0,5% с транзакции и начисляет налог в момент оплаты, а у
     предоплаченных кредитов НДС может возникать при трате. Если ставка одна, эстонская, он не
     нужен;
   - Stripe Managed Payments (MoR от самого Stripe, +3,5%) не подходит: он берёт только полностью
     автоматические цифровые продукты, а чтения пишут люди (Implementation Notes). Для НДС это
     подсказка, а не вывод: эталонная «электронная услуга» Stripe (`txcd_10000000`) — тоже «with
     minimal human involvement».

   На выбор PSP это не влияет: MoR-провайдеры, которые взяли бы НДС на себя, нишу или живые
   чтения не берут (§1).

## Источники (2026-11-11)

- Stripe Restricted Businesses (ред. 2026-09-22): https://stripe.com/legal/restricted-businesses
- Stripe Estonia pricing: https://stripe.com/ee/pricing ; локальные методы: https://stripe.com/en-ee/pricing/local-payment-methods
- Stripe dispute rate: https://docs.stripe.com/disputes/measuring
- Stripe Checkout locales: https://docs.stripe.com/js/appendix/supported_locales
- Stripe multi-currency settlement: https://docs.stripe.com/payouts/multi-currency-settlement
- Adyen restricted list (ред. 2025-11-13): https://www.adyen.com/legal/list-restricted-prohibited ; pricing: https://www.adyen.com/pricing
- Mollie pricing: https://www.mollie.com/pricing ; список (403): https://help.mollie.com/hc/en-us/articles/115000939369
- Montonio pricing: https://www.montonio.com/pricing ; карты через Adyen: https://help.montonio.com/en/articles/58667-how-does-card-payment-2-0-solution-work
- MakeCommerce forbidden: https://makecommerce.net/forbidden-fields/
- Revolut Business prohibited (403): https://help.revolut.com/business/help/merchant-accounts/setting-up-a-merchant-account/prohibited-and-restricted-industries-business-models-for-a-merchant-account/
- Paddle: https://paddle.com/support/what-products-am-i-not-allowed-to-sell-on-paddle/
- Worldline restricted (2015): https://docs.direct.worldline-solutions.com/global/downloads/restricted+merchant+services+and+products+list.pdf
- Corepay: https://corepay.net/industries/tarot-and-psychic-merchant-accounts/
- Kasamba privacy (PayPal / Stripe): https://www.kasamba.com/lp/privacy-policy ; Purple Garden: https://www.purplegarden.co/inapp-privacy-pg
- Viversum AGB: https://www.viversum.de/nutzungsbedingungen ; Questico AGB: https://www.questico.de/bedingungen-und-konditionen
- Apple Pay on the Web AUG: https://developer.apple.com/apple-pay/acceptable-use-guidelines-for-websites/
- Google Pay API AUP (с 2026-10-21): https://payments.developers.google.com/terms/aup
- Visa VAMP: https://www.ravelin.com/blog/visa-vamp-changes-chargeback-disputes , https://support.checkout.com/hc/en-us/articles/26990138066450
- MCC 7996: https://www.rapyd.net/blog/merchant-category-code-mcc-7996-amusement-parks-carnivals-circuses-fortune-tellers/
- e-Residency и Stripe: https://learn.e-resident.gov.ee/hc/en-gb/articles/360001119837
- Stripe Adaptive Pricing: https://docs.stripe.com/payments/currencies/localize-prices/adaptive-pricing , https://support.stripe.com/questions/adaptive-pricing
- Stripe multi-currency settlement fees: https://support.stripe.com/questions/understand-your-multi-currency-settlement-fees , https://support.stripe.com/questions/pricing-updates-for-businesses-based-in-the-european-economic-area-(eea)
- Опубликованные Terms и Privacy: `AURAT-0042-118` (снимок 2026-09-17), `AURAT-0042-119` (§06 «through the app store»), `AURAT-0202-005` (Privacy с персонами и переводом)
- Данные продавца на сайте: Директива 2011/83/EU (ред. 2019/2161), ст. 6(1)(b–c): https://eur-lex.europa.eu/eli/dir/2011/83/oj ; Директива 2000/31/EC, ст. 5: https://eur-lex.europa.eu/eli/dir/2000/31/oj
- НДС (вопросы на потом): Директива 2006/112/EC, ст. 30a–30b (ваучеры): https://eur-lex.europa.eu/eli/dir/2006/112/oj ; Регламент 282/2011, ст. 7 (электронные услуги): https://eur-lex.europa.eu/eli/reg_impl/2011/282/oj
- Stripe, несколько аккаунтов («несвязанные проекты и сайты — отдельные аккаунты»; одно юрлицо и рег. код можно указать в нескольких): https://docs.stripe.com/get-started/account/multiple-accounts ; организации: https://docs.stripe.com/get-started/account/orgs
- Stripe Tax (0,5% с транзакции, no-code; €0,45 через API) и Invoicing (0,4% с оплаченного счёта), прайс EE на 2026-11-11: https://stripe.com/en-ee/tax/pricing , https://stripe.com/en-ee/pricing
- Stripe Checkout: исполнение заказа и события — https://docs.stripe.com/checkout/fulfillment ; Checkout studio — https://docs.stripe.com/payments/checkout-studio/how-it-works ; Managed Payments, условия — https://docs.stripe.com/payments/managed-payments/eligibility ; iDEAL и Bancontact в Checkout (сроки возврата, нет диспутов) — https://docs.stripe.com/payments/ideal/accept-a-payment?payment-ui=checkout , https://docs.stripe.com/payments/bancontact/accept-a-payment?payment-ui=checkout ; тесты — https://docs.stripe.com/testing
- `silvermind.cc` (проверено 2026-11-11): NS Spaceship, MX Spacemail; на сайте — студия разработки (fullstack и React Native), контакт `contact@silvermind.cc`, Aura не упоминается

## Status

`Decided` — при условии, что Stripe активирует аккаунт (решение 1). Решение — `AURAD-0023`; задачи —
`AURAT-0207` / `AURAT-0208` / `AURAT-0209` (2026-11-11).
