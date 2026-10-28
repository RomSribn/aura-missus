# AURAT-0144-004 — context

Источники: `AURAF-0021` и `AURAT-0143-005` §1 (origin brain), `@aura/contracts` `v0.25.0`
(`src/promo.ts`, README), handoff README §10 и `prototype/settings-chat.jsx`, `OFFER.md`, код
`aura-app` `develop` @ `47eb9ba`.

- Контракт: `RedeemPromoCodeRequest {code: 1..64}`, `RedeemPromoCodeResponse`,
  `PromoCodeRefusalCode` (5 × 409 + 429 c `Retry-After`). Приложение на `v0.22.0`; `v0.23.0`
  (сессия по id) и `v0.24.0` (`question` в брони, на проводе необязателен) — только добавления.
- Прототип: строка `{icon:'tag', label:'Coupons & Promo Codes', tint:'#F3D08A'}` — первая в меню.
  Экрана/шторки промокода в хендоффе нет.
- `screens/profile/config/constants.ts`: строки меню — только ссылки (`url`), нажатие = открыть
  браузер. Коммент о пяти убранных строках (`AURAT-0041`). Тест `ProfileScreen.test.tsx:76`
  проверяет, что строки «Coupons & Promo Codes» нет.
- `entities/wallet`: `useWallet().enabled` (клиентский флаг + BFF не ответил 404),
  `walletStore.setBalance` — публикует баланс из ответа (так делает top-up), `useFirstSessionOffer`.
- `shared/api/bff/http-client.ts`: `BffApiError {status, code}` — заголовков ответа (Retry-After)
  не несёт; нужен новый необязательный `retryAfterSeconds`.
- Образцы: `features/profile-photo/lib/refusal-copy.ts` (тексты по коду строками, неизвестный
  код → «try again»), `features/account-deletion` (шторка + хук статуса), `BirthDateSheet`
  (ввод в шторке), `FormField` (нет `autoCapitalize="characters"` и `onSubmitEditing` — добавить),
  `CouponTicket` (тизер оффера), `useToast`.
- Иконка `tag` в `AuraIcon` есть.
