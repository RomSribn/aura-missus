# AURAT-0136-005 — Spec: профиль `/me` (AURAF-0020-010)

Date: 2026-10-23
Status: approved 2026-10-23 (решения — `AURAT-0136-006`)
Тип: задача (фича — `AURAF-0020`, строка 010). BFF и контракты не меняются (`v0.24.0`).

## Цель

Временная `/me` (`AURAT-0104`) заменяется профилем по веб-хендоффу §4.7 / NAVIGATION §2.10.
Человек видит свои данные и правит их (фото, имя, почта, дата рождения), видит баланс и
купон, управляет рассылкой, выбирает язык, открывает правовые страницы, удаляет аккаунт,
выходит. Поведение и валидация — как в приложении; вид — веб-хендофф.

## Что делаем

### 1. Страница `/me` (`pages/me`)

- **Desktop (≥ 761):** слева липкая колонка — карточка (фото 54, имя или «Add your name»,
  телефон, **Edit** → шторка правки) и список разделов; внизу «Log out» (коралл). Справа —
  заголовок раздела и его содержимое. Раздел — в URL: `/me?section=<id>` (по умолчанию
  `account`; неизвестное значение → `account`), парсер — в `shared/config/routes.ts`.
- **Телефон (≤ 760):** карточка + строки разделов (иконка, название, шеврон); раздел
  открывается шторкой (`Sheet`, через dialog host, вид `profile-section`); Back закрывает.
  «Log out» — строкой внизу.
- Гость — `GuestGate` (как сейчас, `AURAT-0118`).

### 2. Разделы (решения владельца — `AURAT-0136-006`)

Порядок как в хендоффе: Account, Payments & balance, Coupons, Notifications, Language,
Privacy & legal, Help. Что без данных в BFF — видно, но помечено **«Coming soon»** (серая
плашка, без действия, не кнопка).

| Раздел | Содержимое |
|---|---|
| **Account** | Строки Name / Phone / Email / Date of birth. Пустое — «Add your name» / «Add email» / «Add date of birth» серым + действие **Add**; заполненное — **Edit** / **Change**. Phone — замок, без действия. Любое действие → шторка Edit profile. Ниже: **Balance** (`GET /v1/wallet`, `formatUsdMinor`) со строкой «Top up in the Aura app» вместо кнопки (как в брони, строки 006/007) и купон (`CouponTicket`, только когда `firstSessionOffer.active`). Биллинг выключен (404) — карточки баланса нет. |
| **Payments & balance** | Balance (сумма + «Top up in the Aura app»); Default card, Apple Pay, History — «Coming soon» (PSP `AURAF-0009`, истории в BFF нет). |
| **Coupons** | Приветственный купон (когда активен; иначе строка «No coupons right now»); поле промокода и Apply — неактивны, «Coming soon». |
| **Notifications** | Тумблер `marketingOptIn` «Email updates about offers» + подпись (текст опт-ина приложения), сохраняется сразу (`PATCH /v1/me { marketingOptIn }`), при ошибке откатывается со строкой ошибки. «Session reminders» (push) — «Coming soon». |
| **Language** | 24 языка `LANGUAGES` собственными названиями (`Intl.DisplayNames` — переводить нечего), галочка у текущего. Выбор → `i18next.changeLanguage`, запоминается в браузере (`localStorage`, try/catch); `detectLanguage` сначала берёт сохранённый, потом языки браузера. На сервер не уходит (поля нет). |
| **Privacy & legal** | Terms of Use, Privacy Policy (`LEGAL_URLS`), Refund & cancellation policy → Terms (возвраты — раздел 07 Terms; отдельной страницы нет), **Delete my account** (коралл) → шторка удаления. Ссылки — новая вкладка. |
| **Help** | FAQ — 3 вопроса хендоффа с раскрывающимися ответами (`<details>`): «How do sessions work?», «How is the welcome offer applied?», «Can I reschedule or cancel?» — ответы по правилам веба/BFF (предоплаченный чат, оффер сервера, перенос до 4 ч, возврат 100 % / 50 % по 24 ч), сверяются с кодом при реализации. **Contact support** → `mailto:support@aura-app.cc` (адрес из Terms), в `shared/config/legal.ts`. |

### 3. Шторка Edit profile (`features/edit-profile`, диалог `edit`)

- Фото 64: своё фото или монограмма / орб; «Upload a photo» / «Change photo» (файл:
  `accept="image/jpeg,image/png,image/webp"`), «Remove photo», когда фото есть. Загрузка сразу
  при выборе (как в приложении — фото не ждёт Save): превью с индикатором, `PUT /v1/me/avatar`
  (multipart, одна часть `avatar`), ответ — профиль в кэш. До отправки — проверка по
  `AvatarLimits` (тип, 8 МБ) теми же фразами, что у отказов сервера; пиксели проверяет сервер.
  Отказы → фразы приложения (`avatar_too_large`, `_too_many_pixels`, `_type_not_accepted`,
  `_empty`, прочее). Кропа нет (как в приложении).
- Поля: Name (автофокус), Email + Date of birth (`DD.MM.YYYY`, маска `maskBirthDate`) в ряд,
  Phone — заблокирован с замком; подпись «Only your advisors see your name. Your phone number is
  your login and can't be changed here.»
- Валидация — схема «Tell us who you are» (`AURAT-0104`), выносится из
  `features/auth-by-phone` в `entities/user/model/profile-form.ts` и используется обоими:
  имя 2…64 после trim (без текста ошибки), почта — после blur «That email doesn't look right.»,
  дата — «That date doesn't exist.», неполная дата блокирует без ошибки.
- **Save changes** активна, только когда форма валидна и PATCH не пуст (вернул как было — снова
  серая). PATCH — только изменённое: очищенная почта → `null`, очищенная дата → `null`.
  Успех → шторка закрывается, профиль в кэше — ответ сервера. Ошибка — «That didn't save.
  Please try again.», введённое остаётся. Cancel / × / Esc / scrim — закрыть без сохранения.
- Фото поверх профиля видно и в шапке: `ViewerAvatar` рисует фото (blob через `fetchBffFile`,
  повтор с новым токеном там же; ошибка → монограмма). URL blob освобождается при смене фото и
  размонтировании.

### 4. Удаление аккаунта (`features/delete-account`, диалог `delete-account`)

Как в приложении, одна шторка: «Delete your account?», что стирается, карточка «What we keep»,
при балансе > 0 — «Your remaining balance of $X will be lost.», Keep it / **Delete account**.
`DELETE /v1/me`: 204 → выход (`signOut`), переход на `/` гостем, строка-уведомление «Your
account has been deleted.» (тост — если в вебе есть; иначе на Home — см. реализацию);
409 `account_has_live_sessions` → фраза приложения + кнопка «Go to Sessions» (`/sessions`);
прочее → «That didn't go through. Please try again.». Во время запроса шторку не закрыть.

### 5. Выход

Как сейчас (без подтверждения): `forgetPendingSignIn`, `signOut`, `/`. Кэш сбрасывается
`app/session` при смене личности.

### 6. FSD

- `entities/user`: `api` — `uploadAvatar`, `removeAvatar` (+ `getMe` как есть);
  `model/profile-form.ts` — схема и сборка PATCH (из `auth-by-phone`); `model/use-avatar-image.ts`;
  `ui/ViewerAvatar` — с фото.
- `features/edit-profile` — шторка правки (форма + фото); `features/delete-account` — шторка и
  `DELETE /v1/me`; `features/choose-language` — выбор и сохранение языка (`shared/i18n` читает
  сохранённое).
- `pages/me` — раскладка, разделы, `?section=`; тумблер рассылки — в `pages/me/model`.
- `shared/model/dialog.ts` — виды `delete-account`, `profile-section`; регистрация в
  `app/config/dialogs.ts`. `topup` не регистрируется (пополнения на вебе нет).
- Цвета — только токены темы (после `AURAT-0123` — её токены, конфликты — манор).

### 7. Строки

Все новые строки — в `en.ts` своих пространств (`me-page`, `edit-profile`, `delete-account`,
`choose-language` при необходимости) и в 23 языках в той же задаче. Ушедшие ключи временной
`/me` удаляются во всех языках.

### 8. Тесты (Vitest)

- `profile-form`: сборка PATCH (только изменённое, очистка → `null`), dirty после возврата.
- Edit profile: Save серая без изменений / с коротким именем; ошибка почты после blur; успех
  закрывает; ошибка — строка; отказы фото → фразы; локальная проверка типа и размера.
- Delete account: 204 → выход; 409 → «Go to Sessions»; баланс > 0 → строка.
- `/me`: пустые поля — «Add …»; Phone без действия; без купона, когда оффер неактивен; биллинг
  выключен — без баланса; `?section=` на desktop; тумблер рассылки (успех / откат).
- Язык: выбор сохраняется, `detectLanguage` берёт сохранённый.
- Существующие тесты `auth-by-phone` (name step) — зелёные после выноса схемы.

### 9. Проверка в маноре (после merge, web-dev)

Правка имени / почты / даты и очистка; фото: загрузка, замена, удаление, видно в шапке;
язык меняется и переживает reload; тумблер рассылки; Delete account — на тестовом номере (409
при брони, 204 без); Log out; телефон 390 — шторки разделов.

## Решения владельца (2026-10-23, `AURAT-0136-006`)

1. Help (FAQ, поддержка) и Privacy & legal — делаем; остальное без данных — «Coming soon».
2. Опт-ин рассылки — в Notifications, сохраняется сразу.
3. Выбор языка — делаем, 24 языка, в браузере.
4. Удаление аккаунта — как в приложении, одна шторка.
5. FAQ — в вебе (3 вопроса, 24 языка), Contact support — `mailto:support@aura-app.cc`,
   Refund policy — Terms.

## Вне задачи

Способы входа (`AURAD-0021`, `AURAT-0135`), пополнение и карты (PSP `AURAF-0009`), история
платежей и промокоды (нет в BFF — «Coming soon»; задачи — только из `aura-app-manor`), push,
кроп фото, страница FAQ на сайте.

## После задачи (brain)

`AURAF-0020-010` UI ✗ → ✓ с пометкой, что из хендоффа не показано и почему; бэклог —
по решениям 1 (если появятся строки) — ID только из `aura-app-manor`.
