# AURAT-0163-005 — spec: профиль и аккаунт на 24 языках

Тип: задача фичи `AURAF-0023` (шаг 3), строка `AURAF-0023-003` (частично — профиль и аккаунт).
Status: done 2026-11-06 (`develop` @ `b0f6e90`).

## Что получится

Человек с телефоном на любом из 24 языков видит на своём языке вкладку Profile, Edit profile, Create account (шаг 2
входа), лист «Profile photo» с его ошибками, лист удаления аккаунта, тост «аккаунт удалён» и ошибку выхода. Смена
языка в профиле сразу перерисовывает и уже показанную ошибку фото. До шага 4 — только в dev (`AURA_I18N_ENABLED`).

## Объём

| Слайс | Namespace | Что |
|---|---|---|
| `screens/profile` | `profile` | Profile, «Add your name», Edit + a11y, Balance, Top Up, Sign out, «Sign out failed», Terms of Use, Privacy Policy, «Aura · version {{version}}» |
| `screens/create-account` | `create-account` | Step 2 of 2, Tell us who you are, подзаголовок, Continue |
| `screens/edit-profile` | `edit-profile` | Edit profile, примечание под полями, Save changes |
| `features/profile-form` | `profile-form` | **общие поля** обеих форм: Name, «How should we call you?», Email / «Email — optional», you@example.com, Date of birth, Phone, текст согласия + его a11y, две ошибки валидации, «That didn't save» |
| `features/profile-photo` | `profile-photo` | заголовок листа, 3 строки (label + hint), 6 ошибок |
| `features/account-deletion` | `account-deletion` | весь лист, a11y кнопки, тост; `@sensitive account-deletion` на namespace |

Не здесь: строка Language и её лист (`AURAT-0158`), «Coupons & Promo Codes» и лист промокода (`promo-code`),
TopUpSheet (`store-topup`) — задача «деньги». `features/sign-out` строк не имеет. Склейки из заглушки
(`Edit ${label.toLowerCase()}`, a11y даты) уже закрыты в `shared` (`AURAT-0157`), «Change photo» — `user`
(`AURAT-0161`).

## Как

- **Один источник полей.** `ProfileFields` сам зовёт `useTranslation('profile-form')`; проп `copy` уходит, вместо
  него `variant: 'create' | 'edit'` (create — «Email — optional» и плейсхолдер имени, edit — строка Phone). У экранов
  в config остаются только свои строки. `ProfileFieldsCopy` удаляется.
- **Ошибки — ключом, текст — при рендере.** `profile-photo`: `refusalCopy` → `refusalKey` (код → ключ), в state
  модели — ключ, хук отдаёт `error` уже через `t` (перерисовка на смену языка). Валидация `profile-form` остаётся
  булевой — текст выбирает `ProfileFields`.
- **Тост удаления — у фичи.** `useAccountDeletion` сам показывает `t('deleted')` после `onDeleted`; экран больше не
  импортирует `DELETED_TOAST` и не читает чужой namespace. Порядок меняется на «выход → тост» — ToastProvider над
  навигацией, тост переживает уход с экрана.
- **Склейки:** `balanceLost(amount)` → `Your remaining balance of {{amount}} will be lost.`; версия —
  `Aura · version {{version}}` (номер — константа, как сейчас); меню отдаёт ключ строки, label — при рендере.
- Eyebrow «Step 2 of 2» рисуется `uppercase` — в el пишется заглавными без тонов.
- Переводы: из веба, где английский совпал (`translate.mjs scan … --web`: `delete-account` целиком, `edit-profile`
  фото и ошибки, `user.fields`, «Tell us who you are», текст согласия, `me-page`), остальное — по глоссарию и регистру
  языка. `@max` — кнопки (Top Up, Save changes, Continue, Keep it, Delete account, Go to Sessions), Edit, заголовки
  экранов и листов, eyebrow.
- `app/i18n/namespaces.ts` +6; `.eslintrc.js` — `i18next/no-literal-string` на `error` для шести слайсов.
- Тесты: существующие на английском остаются; добавлю de/pl рендер для профиля, обеих форм, листа фото и листа
  удаления (сумма в балансе, тост), перерисовку ошибки фото на смену языка.
- Вёрстка: псевдоязык и длинные языки (de, fi, hu, el, ga) — Top Up, строки меню, две кнопки листа удаления в ряд,
  заголовок Create account (`maxWidth: 260`). Проверка — тестами в слейве, на устройстве — в маноре после мёржа.

## Решения владельца
1. **Поля обеих форм — в `profile-form`** (рекомендую): общий namespace у компонента, который их рисует; экраны
   держат только свои слова. Альтернатива — копии в двух namespace экранов (24 × 2 одинаковых перевода).
2. **Тост «Your account has been deleted.» показывает фича** (рекомендую), а не экран — иначе экран читает чужой
   namespace. Тост встаёт после выхода, а не перед ним — заметной разницы нет.
3. **Текст согласия на рассылку — `@sensitive legal`** (рекомендую): по GDPR это формулировка согласия
   (`AURAT-0042-108`), в `translate.mjs review` попадёт к носителю вместе с удалением аккаунта.

## Не в объёме
- promo-code, store-topup, Language-лист.
- Системные запросы камеры / фото (`AURAF-0023-007`) — нативные строки, шаг 4.
- Включение флага — шаг 4.

## Общие файлы с AURAT-0164
`app/i18n/namespaces.ts`, `.eslintrc.js` — конфликт решает та, что мёржит второй.
