# AURAT-0216-106 — Приложение: реализация

Дата: 2026-11-18. slave-1, ветка `feature/AURAT-0216-app-withdrawal-ack`. Изменения застейджены, **не
закоммичены** — ждут просмотра владельцем. Сделано по спеке `103` с поправками `104`.

## Сделано

- **Контракты** `@aura/contracts` `v0.31.0` → `v0.35.0` (lock на `a610947`). Ломающих изменений нет.
- **`shared/ui/ConsentCard`** — общая карточка-галочка: `tone` `accent` / `teal`, `footer`, без
  `numberOfLines`. `chat-settings/ChatConsentCard` теперь на ней (бирюза, строка `failed` при нём).
- **Новый срез `features/session-consent`:**
  - `config/versions.ts` — `booking` / `now` / `extension` → литералы `booking-v1` / `now-v1` /
    `extension-v1`, проверены типами контрактов;
  - `model/use-session-consent(kind, resetKey)` — `{kind, ticked, toggle, consent}`. Сброс при смене
    вида, языка или `resetKey`, прямо в рендере, так что ни одного кадра с галочкой на новых словах;
  - `ui/SessionConsentBox` (коралл + ссылка), `ui/WithdrawalTermsLink` (`LEGAL_URLS.terms` + `#s07`),
    `ui/CancellationTerms`;
  - namespace `session-consent`, 24 языка: три галочки, строка отмены, ссылка. В `en.ts` — JSDoc,
    `@sensitive cancellation`, `@max 48` у ссылки.
- **`store-topup/use-checkout`** — опция `locked`: кнопка неактивна, `pay()` не зовёт ни стор, ни
  `charge`. Кнопка «Top up to …» остаётся активной.
- **`booking/use-booking-confirm`** — опция `consent`, поле только при отметке. 400
  `consent_invalid` / `consent_required` → `failed`, не `slotGone`.
- **`paid-session/use-paid-session`** — `charge(consent: ExtensionConsent | null)`.
- **Экраны:**
  - Review: строка отмены вместо `review.policy` (у «сейчас» — прежний `policyNow`); галочка в футере
    над кнопкой.
  - Быстрая бронь: строка отмены (только слот) и галочка над кнопкой; `resetKey` — открытие шторки;
    «сейчас» → слот снимает галочку.
  - Продление: галочка над кнопкой, своя на каждое открытие.
- **Кнопки:**
  - `chat-thread:extend.cta` → «Pay {{amount}} & extend»;
  - `quickBook.startNow` → «Pay {{amount}} & start now»;
  - `quickBook.book` → «Pay {{amount}} & book».

  24 языка — из готовых `store-topup:cta.store.*` (та же английская формулировка).
- **`account-deletion:keptBody`** — «…without your name or phone number.», 24 языка.
- **`book-session:review.policy`** удалён (24 языка): его место заняла строка `session-consent`.

## Тесты

- `pinned.test.ts`:
  - английский каждой версии равен `SESSION_CONSENT_TEXTS`;
  - sha-256 (16 hex) каждой версии × 24 языка;
  - набор версий совпадает с `box`.

  Проверен порчей: правка `de` `extension-v1` роняет тест и называет `de`. После проверки файл
  восстановлен.
- Новые тесты:
  - `use-session-consent`: пусто, версии, сброс по виду, ключу и языку;
  - `SessionConsentBox`: текст контракта, ссылка `#s07`, язык, `disabled`;
  - `ConsentCard`: без `numberOfLines`, checkbox, тон;
  - `use-checkout`: `locked` держит баланс и стор, Top Up открыт;
  - `use-booking-confirm`: поле при отметке, нет поля без неё, 400 согласия → `failed`;
  - `use-paid-session`: поле продления;
  - `use-quick-book`: кнопка держится, `now-v1` / `booking-v1`, «сейчас» → слот, новое открытие;
  - `use-extend-checkout`: `locked`, `extension-v1` + язык, `null` без галочки;
  - `use-book-review`: вид и `locked`.
- Проверки:
  - `tsc` — чисто;
  - `eslint --max-warnings 0` — чисто;
  - jest — 253 файла, 3373 теста, все зелёные;
  - steiger — нового только `namespaces.ts` → `session-consent/config/locales`, то же узаконенное
    исключение, что у каждого namespace;
  - `translate.mjs check` — 0 запрещённых форм, только ложные советы («star» в «start», «terms» —
    заголовок страницы).

## Открыто

- Строка о досрочном завершении для «сейчас» — ждёт ответа владельца через манор.
- Переводы галочек — первыми у нас. Вебу (`aura-web-manor` slave-2) передать пути:
  `src/features/session-consent/config/locales/*.ts` и `src/features/account-deletion/.../*.ts`
  (`keptBody`).
- Native review — по правилу для `@sensitive` до выхода в страну; список — `translate.mjs review`.

## Проверка в маноре (после мёржа, с BFF на bff-dev)

- Review (слот и «сейчас»), быстрая бронь, продление: кнопка неактивна до галочки, через стор тоже.
- Повторное открытие шторки → галочка пустая.
- Запись согласия на сервере у брони, «сейчас» и продления; `language` — язык экрана.
- Псевдоязык (+40 %) в шторках быстрой брони и продления: текст галочки целиком, кнопка видна.
- Ссылка открывает `aura-app.cc/terms/#s07`.
- Шторка удаления — новый текст.
