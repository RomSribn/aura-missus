# AURAT-0144-007 — execute

Дата: 2026-10-28. Ветка `feature/AURAT-0144-app-promo-codes` (от `develop` @ `47eb9ba`), не закоммичено —
всё застейджено на ревью.

## Что сделано

- `@aura/contracts` `v0.22.0` → `v0.25.0` (`package.json`, lock → `9848a02`). В `v0.24.0`
  `Session.question` после разбора — `string | null`: пять тестовых фикстур получили
  `question: null` (код приложения не менялся).
- **shared**
  - `api/bff/http-client.ts` — `BffApiError.retryAfterSeconds` из `Retry-After` (только секунды).
  - `ui/form-field/FormField.tsx` — `autoCapitalize: 'characters'`, `returnKeyType`,
    `onSubmitEditing`; строка ошибки — `accessibilityLiveRegion="polite"` (правка 3 владельца;
    для всех полей формы, не только промокода).
- **features/promo-code** (новый слайс): `api/promo-code-api.ts`, `config/copy.ts` (тексты по
  правке 1, апострофы ’), `lib/refusal-copy.ts` (+ `isBillingOff`), `model/use-promo-code.ts`,
  `ui/PromoCodeSheet.tsx`, `index.ts`.
- **screens/profile**: строка меню — дискриминированный тип (`url` | `sheet: 'promo'`), строка
  «Coupons & Promo Codes» первой (`tag`, `#F3D08A`); строки с шторкой фильтруются по
  `useWallet().enabled`; `ProfileMenu` получает строки пропсом; `ProfileScreen` рендерит
  `PromoCodeSheet`; `ProfileSheetKey` + `'promo'`.

## Решения по ходу

- Закрытие во время запроса (правка 2): каждое открытие увеличивает счётчик; ответ применяет
  кредит всегда (баланс + тост), а закрывает шторку / показывает отказ — только если открыта
  та же шторка.
- Ввод кода снимает текст отказа (он отвечал на прежний код); отказ код не стирает.
- Тост суммы — `formatUsdMinorCompact`: «+$10 added to your balance», с центами — «+$2.50».
- 404 без кода → текст «not available» + `walletStore.load()` → `disabled`, строка уходит.
- Без автофокуса поля: клавиатура сразу закрыла бы купон оффера.

## Проверки в слоте

`tsc --noEmit` — чисто; `eslint src` — 0 проблем; `jest` — 136 сьютов / 1018 тестов.
Новые: `refusal-copy.test.ts`, `use-promo-code.test.tsx`, `ProfilePromoCode.test.tsx`
(строка при биллинге, шторка, баланс на карточке после кредита, отказ, 404 убирает строку),
два теста `Retry-After` в `http-client.test.ts`.

## Открыто

- Живая проверка — манор/владелец после мёржа (bff-dev, спека §4). После мёржа в маноре —
  `npm ci` (контракты в lock поменялись).
- Строки `AURAF-0021-004/006/007` (UI ✗ → ✓) — при закрытии: файл фичи только в origin brain,
  клон манора ещё на коммит позади.
- Review Notes для Apple (коды бесплатные) — владелец.
