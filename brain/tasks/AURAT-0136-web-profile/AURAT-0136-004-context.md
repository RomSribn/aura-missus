# AURAT-0136-004 — Context

Date: 2026-10-23

## Источники

- Веб-хендофф: README §4.7, NAVIGATION §2.10 (desktop — левая колонка с карточкой и разделами,
  справа содержимое; телефон — карточка + строки, раздел открывается шторкой), прототип
  `web/web-sessions.jsx` → `ProfileWeb`, `web/web-modals.jsx` → `EditProfileModal`, `TopUpModal`.
- Приложение (`aura-app` develop, разбор агентом, только чтение): `screens/profile`,
  `screens/edit-profile`, `features/profile-form`, `profile-photo`, `account-deletion`,
  `sign-out`; хендофф `PROFILE_FORMS.md`; `AURAF-0015` (профиль на сервере, фото — `AURAD-0013`).
- `@aura/contracts` `v0.24.0` (веб уже на нём): `profile.ts`, `account.ts`, `wallet.ts`.
- BFF develop: `profile.controller`, `avatar.controller`, `account.controller`.
- Код веба (develop `280988a`).

## Ключевые находки

**Приложение** (поведение, которое переносим):
- Профиль: карточка (фото / орб, имя или «Add your name», телефон, Edit), Balance + Top Up,
  Terms, Privacy, Sign out, Delete account, версия. Разделы Payments, Coupons, Languages,
  Notifications, FAQ & Support **убраны** в `AURAT-0041` — за ними нет продукта / страниц.
- Edit profile: Name (2…64 после trim, ошибки нет — только серая кнопка), Email (форма адреса,
  ошибка после blur), Date of birth (маска `DD.MM.YYYY`, 1900…сегодня, «That date doesn't
  exist.»), Phone — замок, опт-ин рассылки. Save = valid && dirty, PATCH — только изменённое
  (`email: ""` / `birthDate: null` — очистка). Ошибка — одна строка «That didn't save…».
- Фото: без кропа и без проверки на клиенте; `PUT /v1/me/avatar` multipart (одна часть),
  `DELETE /v1/me/avatar`; показ — `GET /v1/avatars/:id` **с токеном** (на вебе — blob, как
  вложения `fetchBffFile`); отказы `avatar_too_large` / `_too_many_pixels` /
  `_type_not_accepted` / `_empty` — свои фразы.
- Удаление: одна шторка без ввода подтверждения: что стирается, «What we keep» (записи покупок
  7 лет), «остаток $X пропадёт», Keep it / Delete account. 409 `account_has_live_sessions` →
  фраза + кнопка «Go to Sessions». Успех 204 → выход, тост «Your account has been deleted.».
- Выход — без подтверждения.

**BFF / контракты**: всё нужное есть (`GET/PATCH /v1/me`, аватар, `DELETE /v1/me`,
`GET /v1/wallet`). Баланс при удалении **не** блокирует (пропадает). PATCH с ошибкой — 400 без
`code`. Нет: истории платежей, промокодов, настроек уведомлений (только `marketingOptIn`),
сохранённых карт, пополнения без PSP, языка в профиле.

**Сайт** `aura-app.cc`: `/terms/`, `/privacy/` — 200; `/refund/`, `/faq/`, `/support/` — 404.
Адреса поддержки нет нигде.

**Веб сейчас**:
- `pages/me` — временная: имя, телефон, Log out.
- `features/auth-by-phone/model/use-name-step.ts` уже содержит схему формы (имя, почта, дата,
  опт-ин) и сборку PATCH; `shared/lib` — `birth-date`, `email` (портированы с тестами);
  `shared/ui` — `Field`, `Toggle`, `Sheet`, `CouponTicket`, `Avatar`; `entities/user` —
  `useViewer`, `useSaveViewer`, `ViewerAvatar` (монограмма); `entities/wallet` — `useWallet`
  (баланс, оффер); `shared/api` — `fetchBffFile`, `onAccountDeleted`; `LEGAL_URLS` (terms,
  privacy).
- Диалоги: `edit` и `topup` уже объявлены в `DialogKind`, не зарегистрированы.
- Язык: `detectLanguage` — первый из языков браузера, комментарий ждёт «Profile → Language».

## Противоречия

- Веб-хендофф показывает Payments (карта, Apple Pay, история), Coupons (промокод),
  Notifications (push + email), Help, Refund policy — данных / страниц нет. Приложение их убрало.
- Веб-хендофф: опт-ина в Edit profile нет, есть тумблеры в Notifications; приложение — опт-ин в
  Edit profile.
- Хендофф: правка — шторка; приложение — отдельный экран. На вебе — шторка (README/NAVIGATION
  веба главнее для веба).
- Хендофф: телефон «Change»; задача и приложение — телефон заблокирован.
