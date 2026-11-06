# AURAT-0163-007 — execute

Дата: 2026-11-06. slave-0, `feature/AURAT-0163-app-i18n-profile-account`. Не закоммичено — всё в stage для ревью.

## Сделано

### Строки — 6 namespace × 24 языка
- `features/profile-form` → `profile-form` (решение 1): все поля обеих форм. `ProfileFields` сам зовёт
  `useTranslation`; проп `copy` и тип `ProfileFieldsCopy` удалены, вместо них `variant: 'create' | 'edit'` (create —
  «Email — optional» и плейсхолдер имени; edit — строка Phone). Согласие и его a11y — `@sensitive legal` (решение 3).
- `screens/create-account` → `create-account`: Step 2 of 2 (el — капсом), заголовок, подзаголовок, Continue, ошибка
  сохранения. `config/copy.ts` удалён.
- `screens/edit-profile` → `edit-profile`: заголовок, примечание, Save changes, ошибка. `config/copy.ts` удалён.
- `features/profile-photo` → `profile-photo`: лист (заголовок, 3 строки), 6 ошибок. `lib/refusal-copy.ts` →
  `lib/refusal-key.ts` (`refusalKey` → `PhotoErrorKey`); в state — ключ, хук отдаёт текст через `t` — ошибка на экране
  переводится при смене языка. Неиспользуемый `isRetryable` удалён (ноль потребителей).
- `features/account-deletion` → `account-deletion` (`@sensitive account-deletion` на весь namespace): лист, a11y,
  `balanceLost` — интерполяция `{{amount}}`. `config/copy.ts` удалён. Новое: `DeleteAccountLink` (строка под Sign out —
  стили переехали из профиля), `useAccountDeletedToast` — тост показывает фича (решение 2): `useAccountDeletion`
  после `onDeleted`, и `app/providers/AccountDeletedBootstrap` (второй телефон) — через тот же хук.
- `screens/profile` → `profile`: заголовок, «Add your name», Edit + a11y, Balance (el капсом), Top Up, Sign out,
  «Sign out failed», Terms / Privacy (меню отдаёт `labelKey`), `Aura · version {{version}}` (`APP_VERSION`).
  `config/name.ts` удалён (его объяснение — комментарием у карточки). Строка промокодов — по-прежнему
  `PROMO_CODES_LABEL` (задача «деньги»).
- `app/i18n/namespaces.ts` +6; `.eslintrc.js` — `i18next/no-literal-string` на `error` для шести слайсов.

### Переводы
- С веба, где английский совпал (`translate.mjs scan`): `delete-account` (кроме a11y), фото и его ошибки,
  `user.fields`, Tell us who you are / подзаголовок / Continue / согласие (`auth-by-phone`), `me-page` (Add your name,
  Edit, Balance, Terms, Privacy). «Keep it» — из `delete-account:keep` (сканер предлагал `cancel-session`).
- Свои, по глоссарию и регистру: Top Up, Sign out, Sign out failed, версия, первое предложение примечания (второе —
  с веба), 3 строки листа фото + подсказки, a11y подтверждения удаления. bg «Редактирай» — форма кнопки глоссария
  (на вебе — существительное).
- `SAME_AS_ENGLISH` +10 с причиной: de Name, el / it / mt Email, bg / el пример адреса латиницей (как на вебе),
  nl Camera, da / fr / sv version.

### Ширины — замер по метрикам шрифтов (fontTools, 360 pt)
- Кнопки листа удаления — по ~112 pt текста; «Delete account» = 109. Отдельный ключ `confirm` для кнопки (`action` —
  строка в профиле, на всю ширину): bg / el / es / fr / ga / it / nl — голый глагол («Supprimer»), a11y говорит
  «…permanently». «Go to Sessions» — короче в 12 языках («Aux séances», «Do Sesji», hu / mt — имя вкладки).
- Top Up — el «Προσθήκη» вместо «Προσθήκη χρημάτων» (153 pt не влезает рядом с балансом).
- Заголовок Edit profile — bg «Редакция на профила» (281 → 243 pt из 262).
- `@max` выставлены по замеру, в JSDoc en.ts — бюджет в pt.

### Тесты
- Новые: `ProfileFields.test.tsx` (pl: общие слова, разница вариантов, ошибки валидации), профиль на de, Create
  account и Edit profile на pl, лист удаления на de / fr (сумма в фразе, короткий confirm и его a11y), ошибка фото
  переводится при смене языка.
- Обновлён: `CreateAccountScreen.test` — eyebrow «Step 2 of 2» (капс — стилем). Тост удаления в
  `ProfileDeleteAccount.test` проходит без изменений.
- `tsc` — 0, `eslint .` — 0, Jest — 188 наборов / 2234 теста. `translate.mjs check` — 0 запретных форм, 129 советов
  (ложные «zodiac-sign» на «Sign out», «Profilbild» без «Foto» и т. п. — формы веба). `translate.mjs review` —
  `account-deletion` и `profile-form` × 23 ждут носителя.

## Не сделано / проверить в маноре
- Вёрстка на устройстве: псевдоязык и de / fi / hu / el / ga — кнопки листа удаления, Top Up рядом с балансом,
  заголовок Create account (`maxWidth: 260`), строки меню, лист фото.
- «Coupons & Promo Codes», TopUpSheet — задача «деньги».
- Системные запросы камеры / фото — шаг 4.
- Общие файлы с `AURAT-0164`: `namespaces.ts`, `.eslintrc.js`, `translations.test.ts` (`SAME_AS_ENGLISH`).
