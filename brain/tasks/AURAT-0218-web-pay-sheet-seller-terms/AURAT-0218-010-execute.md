# AURAT-0218-010 — Execute: часть A

Дата: 2026-11-18. slave-2, `feature/AURAT-0218-web-pay-sheet-seller-terms` (от develop `60bf412`).
Ничего не закоммичено, всё застейджено.

## Сделано

- **`shared/config/legal.ts`:** `LEGAL_URLS.refunds = 'https://aura-app.cc/terms/#s07'`, `SELLER =
  'Silvermind OÜ'`.
- **`shared/ui`:**
  - `Checkbox` — новый. Настоящий `<input type="checkbox">` внутри `<label>`, без `aria-checked`.
    Отмеченный — заливка `--accent-strong` с белой галочкой, неактивный — `--ink-disabled`. На
    телефоне вся строка ≥ 44px. Новый токен `--r-check: 6px`.
  - `ExternalLink` перенесён из `features/auth-by-phone/ui` (`git mv`).
  - `Button` получил `describedBy` → `aria-describedby`.
- **`features/pay`:**
  - `model/use-card-checkout.ts` — `agreed` / `agree` во view. Сессия открывается только после первой
    отметки (`everAgreed`) и не закрывается, если галочку сняли. `confirm` без галочки → `onRefused`:
    у кошелька это `paymentFailed`. `openPayment` без галочки ничего не делает.
  - `ui/terms-consent.tsx` (+ css) — `TermsConsent` (галочка и строка продавца со ссылками в новую
    вкладку) и `TermsHint`.
  - `ui/card-choice.tsx` — блок идёт первым. До отметки — неактивная «Pay $X» с подсказкой (она же
    `aria-describedby`); остальные состояния — как раньше, подсказка под ними.
  - `ui/card-elements.tsx`:
    - `TermsElement` убран из выбора и из шага оплаты;
    - на шаге оплаты тот же блок стоит над «Pay $X»;
    - если галочку сняли, ряд кошельков становится `inert` и приглушённым (`.isLocked`), а кнопки
      неактивны.
  - Строки `terms.agree` / `terms.seller` / `terms.hint` — в `en.ts` с `@sensitive legal`, плюс 23
    языка.
- **«Terms of Service» везде** (`009`):
  - Вход: `phone.legal` на английском и в 18 языках (bg, de, fi, fr и sv уже совпадали с названием
    из строки reCAPTCHA).
  - `/me`: `legal.terms`, те же языки.
  - Названия взяты из перевода «Terms of Service» в строке reCAPTCHA каждого языка, в нужном падеже.
    В pl «Regulamin» заменён на «Warunki korzystania z usług», в hu артикль «a» → «az».
- **`/me`:** «Refund & cancellation policy» → `LEGAL_URLS.refunds`.
- **Тесты:**
  - Новый `test-support/terms-consent.ts` (`agreeToTerms`).
  - Галочка проставлена в сценариях `psp`, `psp-fake`, `top-up-sheet` и `extend-card`. Шторка,
    открытая заново (возврат со страницы оплаты, bfcache), просит галочку снова.
  - Новые тесты:
    - `top-up-sheet` — блок «the consent to the Terms (AURAT-0218)», 5 тестов: до отметки нет сессии
      и кнопка с описанием; ссылки и продавец; галочку сняли — `inert` и `paymentFailed`, отметили
      снова — платит без новой сессии; галочка переживает смену суммы и сбрасывается при новом
      открытии; шаг оплаты;
    - `atoms` — `Checkbox`, 3 теста;
    - `profile` — ссылка `#s07`;
    - `psp` — оплата с баланса без галочки.
- **Документы:** `.claude/aura-web-build-rules.md` (Payments) и `AURAF-0020` (строка `/me` Privacy &
  legal).

## Проверки

`npm run typecheck`, `npm run lint` (eslint + steiger), `npx vitest run` — 126 файлов, 2032 теста,
все зелёные. `npm run build` — ок.

## Решения по ходу

- **404 на старте** (карта выключена на BFF при включённом флаге веба) теперь видна только после
  первой отметки. Раньше сессию открывали сразу, теперь — только после согласия. Тесты переписаны
  под это. В проде оба флага выключены, так что это касается только ошибки конфигурации.
- **Ссылка внутри `<label>`** не переключает галочку: так требует правило HTML, и браузеры его
  выполняют. jsdom этого не моделирует, поэтому теста на это нет — только комментарий в `Checkbox`.
- **Неактивные кнопки:** подсказка видна текстом и связана через `aria-describedby` (`007` п. 5).

## Открыто

- **Конфликт с `AURAT-0217`** (slave-1). Обе задачи правят `card-elements.tsx`: здесь убран
  `TermsElement`, там меняются шрифты элементов (`fonts`). Кто мёржит вторым, решает конфликт в этом
  месте.
- **Часть B** — после контрактов `v0.35.0` (BFF-часть `0216`): `termsConsent` в `CardTopUpRequest`
  с версией из `TERMS_CONSENT_VERSIONS`.
- **Проверка в маноре на web-dev после мёржа:**
  - Book / Top up / Extend с картой: до галочки нет кошельков, кнопка неактивна, видна подсказка;
  - после галочки — кошельки и «Other ways to pay»;
  - сняли галочку — кошельки приглушены и не нажимаются;
  - ссылки открываются в новой вкладке, Refund ведёт на `#s07`;
  - на телефоне строка галочки ≥ 44px;
  - «Terms of Service» во входе и в `/me`.
