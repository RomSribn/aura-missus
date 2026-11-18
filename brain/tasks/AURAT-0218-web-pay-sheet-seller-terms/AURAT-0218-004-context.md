# AURAT-0218-004 — Контекст

Дата: 2026-11-18. aura-web develop `60bf412`, aura-bff develop `cd0975b`, контракты `v0.34.0`.

## Brain

- `AURAD-0023`, ворота live: «согласие с Terms в Elements… Stripe открыл аккаунту Terms Element
  … или своё согласие (веб + BFF). Затем — проверка на sandbox со ссылкой на Terms». 2026-11-13:
  «You cannot use the Terms Element without being gated» — при `consent_collection.terms_of_service:
  'required'` согласие в Elements собрать нечем, в live оплата не пройдёт.
- `AURAD-0023`, 2026-11-11: «в live галочка обязательна» (`AURAT-0207-011`).
- `AURAT-0209-011` (+ `013`, `015`): тексты Terms одобрены, на сайте не опубликованы. §07 «Buying on
  the web… you buy credits directly from Silvermind OÜ», «Refunds and your right of withdrawal»,
  «Booked sessions». Таблица Stripe: Refund policy = `/terms/#s07`. «В `ui_mode: 'elements'` Stripe не
  показывает в шторке policies и контакты — это `AURAT-0218`».
- `AURAT-0209-006` п. 2: Refund policy — `https://aura-app.cc/terms/#s07`.
- `AURAT-0216-004`/`005`: при брони, «сейчас» и продлении — пустая галочка признания, кнопка
  неактивна до отметки, на сервер — версия текста, время, id брони / продления; ссылки на §06 и §07;
  надписи «Pay {{amount}} & start now» / «Pay {{amount}} & extend». Шторку оплаты 0216 не трогает.
- BFF-часть `0216` в aura-bff-manor slave-1: ветка есть, спеки ещё нет (в папке только 001–006).
  Формат записи согласия пока не определён.

## Код веба

- Карта есть в трёх шторках, все через `features/pay`: Book (`PayActions` → `CardChoice` / `PayStep`),
  Top up (`TopUpSheet`), Extend (`CardTopUpChoice`). Выбор — `card-elements.tsx` `ChoiceBody`
  (валюта → `TermsElement` → кошельки → «Other ways to pay» / «Pay $X»); шаг оплаты — `PaymentBody`
  (сумма → валюта → email → `PaymentElement` → `TermsElement` → кнопка → «Secure payment by Stripe»).
- `TermsElement` стоит в обоих местах с `onLoadError={termsOff}` — у аккаунта он не грузится.
- `ExpressCheckoutElement` в `@stripe/react-stripe-js/checkout` **не принимает `onClick`** (тип
  `Omit<…, 'onClick'>`) — отклонить нажатие на кошелёк нельзя. Остаётся не давать нажать
  (неактивный ряд) и проверка в `onConfirm` (`paymentFailed`).
- `shared/config/legal.ts`: `LEGAL_URLS = { terms, privacy }`. Потребители: `auth-by-phone`
  (`phone.legal`), `pages/me` (`me-sections.tsx:265` — «Refund & cancellation policy» → `terms` без
  якоря).
- `ExternalLink` (новая вкладка) — в `features/auth-by-phone/ui`; второй потребитель → поднять в
  `shared/ui` (правило 3/4). Чекбокса в `shared/ui` нет; он нужен и этой задаче, и `0216`.
- `@sensitive` в вебе пока нет; в приложении — JSDoc `@sensitive <class>` в `en.ts` (`payment`,
  `refund`, `legal`, `cancellation`…).
- В дизайн-хендоффах чекбокса нет (CHECKOUT.md выбрал toggle для «Use my balance» — это настройка,
  не согласие).

## BFF

- `STRIPE_TERMS_CONSENT: 'required' | 'none'`, по умолчанию `required`; `none` с live-ключом —
  ошибка старта (`env.schema.ts:683`). `required` → `consent_collection.terms_of_service` в сессии.
- Значит, своё согласие в live **требует правки BFF**: сессия без `consent_collection` при live-ключе.
  Без неё live не работает ни с `required` (Terms Element закрыт), ни с `none` (запрещено).

## Противоречия

Нет. Вопрос маршрутизации: правка BFF (режим согласия + запись) — вне брифа «свою BFF-часть не
заводи»; решает владелец / координатор.
