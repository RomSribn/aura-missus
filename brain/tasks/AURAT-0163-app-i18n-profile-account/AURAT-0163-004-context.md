# AURAT-0163-004 — context

Дата: 2026-11-06. Код — slave-0 `feature/AURAT-0163-app-i18n-profile-account` (= `develop` @ `7f58117`).

## Строки по слайсам (сейчас — литералы)
- `screens/profile`: Profile, «Add your name» (`config/name.ts`), Edit / a11y «Edit profile», Balance, Top Up,
  Sign out, «Sign out failed» (Alert в `use-profile`; тело уже `shared:auth.*`), Terms of Use, Privacy Policy,
  «Aura · version 1.0.0».
- `screens/edit-profile/config/copy.ts` и `screens/create-account/config/copy.ts` — два объекта `COPY`; общие с
  одинаковым текстом: name, emailPlaceholder, dob, optIn, optInLabel, emailInvalid, dobImpossible, failed.
  Разные: email («Email» / «Email — optional»), только create: eyebrow «STEP 2 OF 2», title, body, namePlaceholder,
  Continue; только edit: title, phone, note, «Save changes».
- `features/profile-form/ui/ProfileFields` получает `copy` пропом; валидация в модели — булевы флаги (`emailInvalid`,
  `dobImpossible`), текст — в config экранов. Строк самого слайса нет.
- `features/profile-photo`: лист (заголовок, 3 строки × label + hint), ошибки — английские строки прямо в state
  модели (`refusalCopy`, «could not be read», «could not be removed»). Язык сменится — ошибка останется английской.
- `features/account-deletion/config/copy.ts`: 11 строк, `balanceLost(amount)` — шаблон; a11y «Delete your account
  permanently»; `DELETED_TOAST` экспортируется и показывается из `screens/profile` (`showToast`).
- `features/sign-out` — строк нет.
- Строка «Coupons & Promo Codes» в меню — `features/promo-code` (`PROMO_CODES_LABEL`), задача «деньги»; TopUpSheet —
  `store-topup`, тоже «деньги».

## Уже сделано раньше (из заглушки — проверено, закрыто)
- `Edit ${label.toLowerCase()}` и a11y даты — в `shared/ui/form-field/DobField` уже `t('dob.edit', { label })` с
  `{{label, lowercase}}` (`AURAT-0157`). Плейсхолдер даты — `shared:dob.placeholder`.
- «Change photo» — `user:changePhoto` (`AURAT-0161`).

## aura-web (переводы во всех 23)
- `edit-profile`: title, photo.title / change / remove, все 6 ошибок фото — английский совпадает с приложением,
  `failed`, `save` («Save changes»). `note` — другой текст.
- `delete-account`: все строки листа совпадают (title, text, kept.*, balance `{{amount}}`, keep, delete, live,
  sessions, failed, deleted) — апостроф ’ вместо '.
- `user.fields`: name, namePlaceholder, email, emailOptional, emailPlaceholder, dob, phone, emailInvalid,
  dobImpossible — совпадают.
- `auth-by-phone`: «Tell us who you are», optIn-текст. `me-page`: «Add your name», Edit, Balance, Terms of Use,
  Privacy Policy, «Your profile» (у нас «Profile»), «Log out» (у нас «Sign out»).

## Наблюдения
- Ни один слайс не читает чужой namespace фичи/entity — только свой и `shared`. Значит тост удаления не должен
  читаться экраном из `account-deletion`.
- ToastProvider — над навигацией (`app/index.tsx`), тост переживает уход из профиля.
- `@sensitive`: удаление аккаунта — да (правило). Текст согласия на рассылку (optIn) — юридический по сути (GDPR,
  `AURAT-0042-108`) — кандидат на `@sensitive legal`.
