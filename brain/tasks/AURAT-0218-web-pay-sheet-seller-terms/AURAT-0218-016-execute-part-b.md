# AURAT-0218-016 — Execute: часть B

Дата: 2026-11-18. Ветка та же. Ничего не закоммичено, всё застейджено. Коммитов будет два: тег
контрактов отдельно (правило 6).

## Сделано

1. **Контракты `v0.35.0`** — `package.json` / `package-lock.json` (`a610947`).
2. **`lib/terms-consent.ts`:** `termsConsentIn(language)` → `{ version, language }`. Версия — самая
   новая из `TERMS_CONSENT_VERSIONS` (сейчас `terms-v1`), своей константы у веба нет.
3. **Старт пополнения:**
   - `TopUpProvider.startCard` принимает `termsConsent: TermsConsent | null`;
   - `card-provider` кладёт поле в `CardTopUpRequest`, только если оно есть — без `null`; фейк его
     не читает;
   - `useCardSession` берёт текущее согласие из `latest` в момент каждого старта: новая сумма,
     повтор, повтор после 429, новая попытка после оплаты.
4. **`use-card-checkout.ts`:**
   - `everAgreed` заменён на `agreedAmount` — сумма, на которую согласились;
   - пока галочка стоит, `agreedAmount` следует за суммой. Сняли — открытая сессия остаётся, а новая
     сумма ждёт повторной отметки: сессия без согласия не открывается;
   - `termsConsent` = `termsConsentIn(language)` при галочке, иначе `null`.
5. **Ошибки:** 400 `consent_required` уходит в общий отказ старта → «That didn't go through», нажатие
   открывает новую сессию.
   - Галочку при этом не снимаю, в отличие от спеки `008` B3. Старт без согласия возможен, только
     когда галочка уже снята, — например, сработал повтор после 429 или галочку сняли в течение 300 мс
     паузы.
6. **Тесты:**
   - `config/__tests__/terms-consent-pins.test.ts` — закрепка 24 переводов `terms.agree` для
     `terms-v1`, проверка, что закреплены все версии контрактов, и `language`;
   - `card-provider.test.ts` — поле только при галочке;
   - `top-up-sheet` — сняли галочку → новая сумма ждёт, отметили → новая сессия с согласием;
   - тела стартов в `psp`, `extend-card`, `top-up-sheet` — с `termsConsent`.
7. **Документы:** `.claude/aura-web-build-rules.md` (Payments).

## Проверки

`tsc -b`, lint (eslint + steiger), vitest — 129 файлов, 2257 тестов; `npm run build` — ок.

## Открыто

- **Проверка в маноре на web-dev** после выката BFF 0216 и `STRIPE_TERMS_CONSENT=client` на bff-dev:
  - тело старта с `termsConsent`;
  - запись `CARD_TERMS` в `consents`;
  - без галочки новая сессия не открывается;
  - проверка на sandbox со ссылкой на Terms (`AURAD-0023`).
- **Порядок выката:** этот веб безопасен и до BFF 0216. BFF develop `cd0975b` валидирует тело
  `CardTopUpRequest` из контрактов `v0.34.0` — zod `object` без `.strict()`, поэтому неизвестное поле
  отбрасывается (проверено по коду: `src/contracts/card-top-up.ts`).
