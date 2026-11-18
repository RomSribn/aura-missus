# AURAT-0218-012 — Execute: правки по ревью кода манора (`011`)

Дата: 2026-11-18. Ничего не закоммичено, всё застейджено.

1. **Имена.**
   - `ui/terms-consent.tsx` (+ css) → `ui/terms-agreement.tsx` (`git mv`).
   - Компонент `TermsConsent` → `TermsAgreement`, `TermsHint` → `AgreementHint`.
   - Помощник тестов `test-support/terms-consent.ts` → `terms-agreement.ts`.
   - Имя `TermsConsent` в фиче теперь свободно для типа из `@aura/contracts` (часть B).
2. **`card-choice.tsx`:** IIFE заменена компонентом `ChoiceState` — переключатель по состоянию сессии.
   `CardChoice` собирает: соглашение → `ChoiceState` → подсказка.
3. **Хук `model/use-agreement-lock.ts`:** `useAgreementLock(agreed)` → `{ locked, hintId, describedBy }`.
   - `CardChoice` создаёт его и передаёт в `ChoiceState` и `ChoiceBody` (кошельки);
   - `PaymentBody` создаёт свой;
   - `AgreementHint` получает `lock` и рисуется только при `locked`.

Поведение не менялось. `typecheck`, `lint`, vitest (126 файлов, 2032 теста), `build` — зелёные.
