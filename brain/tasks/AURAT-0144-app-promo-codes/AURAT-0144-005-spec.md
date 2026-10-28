# AURAT-0144-005 — Spec (draft, ждёт владельца)

Дата: 2026-10-28
Тип: task — UI приложения для строк `AURAF-0021-004`, `-006`, `-007`. Новой фичи нет; строки
фичи отмечаются ✓ при закрытии.

## 1. Что видит человек

**Профиль.** В меню первой строкой возвращается «Coupons & Promo Codes» — по прототипу: иконка
`tag`, плитка `#F3D08A`. Строка есть, только когда кошелёк жив (`useWallet().enabled`: клиентский
флаг `BILLING_ENABLED` и BFF не ответил 404). При выключенном биллинге меню прежнее — две строки.
Нажатие открывает шторку (а не браузер, как остальные строки).

**Шторка «Coupons & Promo Codes»** (из готовых атомов, без дизайнера):

```
Coupons & Promo Codes                     ← заголовок, как у других шторок
[ купон оффера «50% OFF First Session» ]  ← CouponTicket (тизер), если оффер активен
  или «No coupons right now.»             ← ink-3, если нет
PROMO CODE                                ← FormField: метка-бровь, иконка tag справа
[ K7QM-9XRT            🏷 ]                  заглавные при наборе, без автокоррекции, ≤ 64
<текст отказа>                            ← строка ошибки поля (коралловая рамка)
[            Apply            ]           ← primary, disabled пока поле пустое; loading
```

- Клиент проверяет только «не пусто» (после trim); код уходит **как набран** — нормализует
  сервер. Клавиатура: `autoCapitalize="characters"`, Return = Apply.
- Пока запрос в пути — Apply в loading, шторка не закрывается (ответ должен куда-то прийти).
- Каждое открытие — пустое поле, без ошибки.

**Успех (200).** Баланс публикуется сразу из ответа (`walletStore.setBalance(balanceMinor)` —
карточка профиля и шторки брони видят его без перезапроса), шторка закрывается, тост:
- `replayed: false` → «+$10.00 added to your balance» (сумма из `creditedMinor`, `formatUsdMinor`);
- `replayed: true` → «This code is already on your balance».

**Отказы** — текст под полем, шторка остаётся, введённый код не стирается:

| Ответ | Текст |
|---|---|
| 409 `promo_code_not_found` | We couldn't find that code. Check it and try again. |
| 409 `promo_code_already_used` | This code has already been used. |
| 409 `promo_code_expired` | This code has expired. |
| 409 `promo_code_disabled` | This code is no longer active. |
| 409 `promo_code_campaign_used` | You've already used a code from this promotion. |
| 429 `promo_code_too_many_attempts` | Too many tries. Try again in N min. (N = ⌈Retry-After / 60⌉, не меньше 1; без заголовка — «Try again later.») |
| 404 без кода (биллинг выключен на BFF) | Promo codes aren't available right now. + кошелёк перечитывается → `disabled`, строка уходит из меню |
| сеть / 5xx / неизвестный код | Couldn't apply the code. Please try again. |

Коды сверяются строками, а не импортом enum — как в `profile-photo/lib/refusal-copy.ts`: сервер на
версию впереди может прислать незнакомый код, честный ответ на него — «try again».

**Тексты не намекают на покупку кодов** (коды бесплатные; Apple 3.1.1). Строка для Review Notes
в App Store Connect — за владельцем.

## 2. Код (FSD)

- `@aura/contracts` `v0.22.0` → `v0.25.0` (`package.json` + lock; `v0.23`/`v0.24` — только
  добавления, `question` на проводе необязателен).
- **shared**
  - `api/bff/http-client.ts`: `BffApiError.retryAfterSeconds?: number` — из заголовка
    `Retry-After` (секунды) у неуспешного ответа; формат даты HTTP не разбираем (сервер шлёт
    секунды). Тело по-прежнему не читается дальше `code`.
  - `ui/form-field/FormField.tsx`: `autoCapitalize` + `'characters'`; `returnKeyType`,
    `onSubmitEditing` — пробрасываются в `TextInput`.
- **features/promo-code** (новый слайс):
  - `api/promo-code-api.ts` — `redeemPromoCode(code)` → `RedeemPromoCodeResponse.parse`.
  - `lib/refusal-copy.ts` — текст по ошибке (таблица выше) + минуты из `Retry-After`.
  - `config/copy.ts` — все строки.
  - `model/use-promo-code.ts` — значение поля, статус (`idle | redeeming | refused`), текст
    отказа, `apply`; на успех — `walletStore.setBalance`, тост, `onRedeemed` (закрыть шторку);
    на 404 — `walletStore.load()`.
  - `ui/PromoCodeSheet.tsx` — только рендер.
  - `index.ts` — `PromoCodeSheet`, `usePromoCode`, `PROMO_CODES_LABEL`.
- **screens/profile**
  - `config/constants.ts`: строка меню — дискриминированный тип (`url` | `sheet: 'promo'`);
    коммент об `AURAT-0041` поправить (строка вернулась в `AURAT-0144`).
  - `model/use-profile.ts`: `ProfileSheetKey` + `'promo'`; строки меню фильтруются по
    `wallet.enabled`; нажатие: `url` → браузер, `sheet` → `openSheet`.
  - `ui/ProfileMenu.tsx` получает строки пропсом; `ProfileScreen.tsx` рендерит `PromoCodeSheet`.
- Код **не пишется в логи** и не попадает в `BffApiError` (там только `status`, `code`,
  `retryAfterSeconds`).

## 3. Тесты (слот: lint, typecheck, jest)

- `refusal-copy`: каждый код, 429 с/без `Retry-After` (90 с → «2 min»), 404, сеть.
- `use-promo-code`: пустое поле не шлёт; успех → `setBalance` + тост с суммой; `replayed` → свой
  тост; отказ → текст, поле не стёрто; повторный тап во время запроса не шлёт второй.
- `http-client`: `retryAfterSeconds` из заголовка; без заголовка — `undefined`.
- `ProfileScreen`: строка есть при `enabled`, нет при выключенном биллинге (вместо теста «строки
  нет» из `AURAT-0041`).

## 4. Проверка вживую (манор + владелец, после мёржа)

bff-dev, тестовый номер; коды — в бэкофисе bff-dev (`/backoffice` → «Промокоды»):
годный код → тост и баланс; тот же код ещё раз → «already on your balance»; второй код той же
партии → «from this promotion»; код с другого аккаунта → «already been used»; отключённый;
набор `k7qm 9xrt` строчными с пробелом; 10 неверных → «Try again in N min».

## 5. Вне задачи

- Список купонов/истории промокодов (в контракте нет), Payments и прочие убранные строки.
- Деплинк/ссылка с кодом (`AURAF-0021` NOT in scope).
- Подъём versionCode и сборка — отдельно, по решению владельца.
