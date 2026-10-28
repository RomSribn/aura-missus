# AURAT-0145-005 — Spec (draft, ждёт владельца)

Date: 2026-10-28
Тип: task — UI веба строк `AURAF-0021-005`, `-006`, `-007`. Новой фичи нет.
Сервер — `AURAT-0143` (bff-dev `af00d64`), контракт `@aura/contracts` `v0.25.0`.

## 1. Что увидит человек (`/me` → Coupons; desktop — панель, телефон — шторка)

Как в хендоффе: купон оффера (или «No coupons right now.»), под ним карточка —
иконка `tag`, поле «Enter a promo code», кнопка **Apply** (ghost). «Coming soon»
уходит.

| Состояние | Что |
|---|---|
| Пусто / одни пробелы | Apply неактивна |
| Отправка | Apply неактивна, поле только для чтения, `aria-busy`; Enter и второй клик — ничего |
| Успех | Поле очищается; под карточкой teal: **«+$10.00 added to your balance»** (сумма — `creditedMinor`, `Intl` в языке человека); баланс — `balanceMinor` из ответа сразу в кэш кошелька → шапка (`BalanceChip`) и `BalanceCard` |
| Повтор (`replayed: true`) | Поле очищается; **«This code is already on your balance.»**; баланс из ответа |
| Отказ | Текст остаётся в поле (поправить опечатку), под карточкой текст ошибки (`--error`), у поля `aria-invalid`; любой ввод снимает ошибку |
| Биллинг выключен (кошелёк 404) | Карточки с полем нет; купон / «No coupons» — как сейчас |
| Кошелёк ещё читается | Карточки нет (не мигает «есть → нет» на окружении без биллинга) |

Текст под карточкой — живой регион: успех `role="status"`, ошибка `role="alert"`.
Поле: `autocomplete="off"`, `autocapitalize="characters"`, `spellcheck=false`,
`enterkeyhint="done"`, `maxLength` из контракта (64). Отправляется как набрано —
нормализует сервер; клиент проверяет только «не пусто после trim».

## 2. Тексты отказов (en; переводятся на все 24 языка в этой же задаче)

| `code` / случай | Текст |
|---|---|
| `promo_code_not_found` | We couldn’t find that code. Check it and try again. |
| `promo_code_already_used` | This code has already been used. |
| `promo_code_expired` | This code has expired. |
| `promo_code_disabled` | This code is no longer active. |
| `promo_code_campaign_used` | You’ve already used a code from this offer. |
| `promo_code_too_many_attempts` + `Retry-After` | Too many tries. Try again in {{count}} min. (плюрали; минуты = ⌈сек / 60⌉, минимум 1) |
| 429 без `Retry-After` | Too many tries. Please try again later. |
| 404 при отправке (биллинг выключили) | общий текст ниже + перечитать кошелёк → поле уйдёт |
| сеть / 400 / 5xx / прочее | That didn’t go through. Please try again. |

Обратного отсчёта и блокировки кнопки после 429 нет: повтор раньше срока просто
получит новый 429 с новым `Retry-After`.

## 3. Как устроено (FSD)

- **Контракты** `v0.24.0` → `v0.25.0` — отдельный коммит (правило 6).
- **`shared/api/base-query.ts`** — `BffError.retryAfterSeconds?: number`: только у
  429, из заголовка `Retry-After` (секунды; дата HTTP или мусор → не задан). Тело
  по-прежнему не копируется. Тест в `base-query.test.ts`.
- **`features/redeem-promo-code/`** (новый слайс):
  - `api/promo-code-api.ts` — `redeemPromoCode` (`injectEndpoints`, `POST
    /v1/wallet/promo-codes/redeem`, тело `RedeemPromoCodeRequest.parse`, ответ
    `RedeemPromoCodeResponse.parse`). Тег `Wallet` не инвалидирует — баланс
    кладётся из ответа (`walletBalanceUpdated`), как у брони.
  - `model/use-redeem-promo-code.ts` — значение поля, отправка, исход
    (`credited` / `replayed` / отказ по `code`), минуты из `retryAfterSeconds`,
    404 → `wallet.refresh()`. Код никуда, кроме тела, не пишется (нет `console`,
    нет `sessionStorage`).
  - `lib/` — `minutesUntil(retryAfterSeconds)` (чисто, с тестом).
  - `ui/promo-code-field.tsx` + `.module.css` — карточка из хендоффа (`<form>`,
    Apply = `Button type="submit" variant="ghost"`), только рендер.
  - `config/locales/` — неймспейс `redeem-promo-code`, 24 языка;
    в `I18N_NAMESPACES` и `vitest.setup.ts`.
- **`pages/me`** — `Coupons` рендерит `<PromoCodeField />` при `wallet.status`
  `ready` / `error`; ключи `coupons.promo`, `coupons.promoPlaceholder` переезжают
  в фичу (удаляются из 24 файлов `me-page`); CSS `.promo*` — в фичу.
- Тест фичи (Vitest + Testing Library, BFF замокан): успех — сумма и баланс в
  кэше; повтор; каждый отказ — свой текст; 429 → минуты; 404 → поле пропадает;
  двойной Enter — один запрос; пустое поле — Apply неактивна.

## 4. Не в задаче
- Поле промокода в Account, в чекауте или при недостаче баланса.
- История промо-зачислений (Payments → History — по-прежнему «Coming soon»).
- Живая проверка — манор после мёржа: web-dev против bff-dev, тестовый номер,
  коды владельца из бэкофиса bff-dev.

## Решения владельца
1. Тексты §2 и успеха / повтора — так?
2. Поле только в Coupons (как хендофф), без кнопки-шортката с Account — так?
