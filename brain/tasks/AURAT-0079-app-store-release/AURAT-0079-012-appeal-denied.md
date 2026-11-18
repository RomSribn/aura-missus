# AURAT-0079-012 — App Review Board отклонил апелляцию; iOS идёт через веб, консультация с App Review

Дата: 2026-11-16. Апелляция `APL639161` (подана 2026-11-01, `AURAT-0079-011`).

## Что пришло

Board подтвердил отказ по **4.3(b) — Design — Spam**. Дословно главное:

> We understand your clarification of the app's intended purpose as a tarot and psychic reading
> entertainment platform… However, your app was found to be **primarily a tarot card-reading app**
> which is a saturated category… new apps in this category will not be approved unless they provide
> a **unique, high-quality experience**.
>
> Our review was based **entirely on the content and functionality in your app**…
>
> We … look forward to reviewing your **revised submission**.

## Как это читать

- Обжаловать дальше негде: Board — последняя инстанция.
- Формулировка впервые не шаблонная: не «astrology, horoscopes, palm reading…», а «primarily a tarot
  card-reading app». Довод про живых людей прочитан и принят, решение — по тому, что видно в самом
  приложении, а не в карточке.
- Почему «таро»: первое, что видит ревьюер, — онбординг с картой дня и хрустальным шаром, сплеш с
  орбом, вкладка Daily Tarot среди пяти. Советники, сессии и живой ответ — дальше. Карточку мы
  переписали (`010`), продукт — нет.
- Дверь не закрыта («revised submission»), но предупреждение из `011` про повторные подачи и
  исключение из Developer Program в силе. **Подавать то же приложение — нельзя**; переименование и
  скриншоты подачей «revised» не считаются.

## Решение владельца (2026-11-16)

1. **iOS-пользователи идут в веб** — довести веб-оплату до live (ворота `AURAD-0023`).
2. **Параллельно — консультация с App Review** (Meet with App Review), до любой новой подачи.
3. Нативную iOS-сборку **не подаём**. Переделка продукта под iOS (таро вне входа и навигации) —
   только если консультация даст основание, и тогда отдельной задачей со спекой. Прятать функции на
   время ревью нельзя: это 2.3.1, хуже 4.3.

Android не затронут.

## Консультация с App Review

Официально: https://developer.apple.com/help/app-review/before-submitting-for-review/app-review-appointment

- Запись: Meet with Apple → https://developer.apple.com/events/view/upcoming-events?search=%22App%20Review%22
  (вход Apple ID аккаунта Silvermind OÜ).
- 30 минут, видео в Webex, камера по желанию; вторник и четверг, местные рабочие часы, по наличию мест.
- В заявке — Apple ID приложения из ASC (`6813629245`) и конкретные вопросы.
- Информационная: «doesn't replace, expedite, or guarantee the outcome», предодобрения нет.
- По форуму разработчиков 2026: пункт консультации виден не всем; запасной путь — Reply to App
  Review с просьбой о звонке (время и язык), звонок в 3–5 рабочих дней.

Вопросы (английский, на 30 минут — три):

1. Aura is a paid service with human advisors: users book and pay for time in a private chat, every
   reply is written by a person on our team, nothing is generated. The Board read it as "primarily a
   tarot card-reading app". If the daily tarot card leaves onboarding and the tab bar, so the app is
   advisors, chat, booked sessions and wallet — does 4.3(b) still apply to a live-advisor service as
   such?
2. What does App Review look for as a "unique, high-quality experience" in this category — which
   parts of an app would show the difference?
3. Given the warning about repeated submissions: if we change the product substantially, is a new
   version on the same app record with Review Notes on the changes the right way, and is it still
   counted as a repeated submission?

## Ворота веб-оплаты live (`AURAD-0023`), состояние на 2026-11-16

| Пункт | Состояние |
|---|---|
| Stripe активировал аккаунт Silvermind OÜ | не подтверждено в брейне — владелец |
| Terms, Privacy, данные продавца (`AURAT-0209`) | только `001-initial` |
| Вопрос НДС (`AURAI-0013` шаг 4) | открыт |
| Прод-веб на `web.aura-app.cc` (`AURAD-0020`) | DNS не резолвится (проверено 2026-11-16) |
| live-ключи и live-вебхук в прод-BFF | после активации |
| Adaptive Pricing и методы в live | после активации |
| Согласие с Terms в Elements | Terms Element закрыт для аккаунта, доступ запрошен; иначе — своё согласие |

Банковские методы (`AURAT-0214`) в ворота не входят.

## Что остаётся верным при любом исходе (из `011`)

- Время ответа советника на стойке.
- `screens/edit-profile/config/locales/en.ts:17` (ключ `note`, и во всех 24 языках) — «Your birth
  date powers your personal horoscope»: обещание несуществующей функции, убрать.
