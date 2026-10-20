# AURAT-0104-005 — Spec: вход по телефону, «Tell us who you are», gate с resume

Date: 2026-10-20
Type: task (строки `AURAF-0020-003`, `-004`, колонка UI). Новой фичи нет.
Status: done 2026-10-20 (`010`)

## Цель

Человек входит в aura-web по номеру телефона и SMS-коду в тот же аккаунт Firebase, что в
приложении (проект `aura-2781b`, тот же uid — чаты, кошелёк, оффер общие). Новый человек
называет себя. Любое действие гостя, которому нужен аккаунт, открывает вход и после него
продолжается с теми же данными. В шапке справа — Log in или аватар. Смена того, кто вошёл,
сбрасывает ответы API, зависящие от человека.

BFF и contracts не меняются (`004` п. 1).

## Что делаем

### 1. Окно входа — `features/auth-by-phone`, диалог `auth`

Один `Sheet` (модалка на desktop, шторка на телефоне), три шага; регистрация `auth` в
`app/config/dialogs.ts`. Параметры диалога: `reason` (`book` | `null`) и `to` — куда
продолжить (см. §4).

**Шаг «Телефон».**
- Заголовок и подзаголовок по причине: `book` — «Log in to book your session» / «Your session
  and the welcome offer are saved for you.»; `null` — «Log in or sign up» / «One account for the
  app and the web.» (`ask` придёт с задачей Home.)
- Teaser-купон (`CouponTicket`, оффер — тот же источник, что в каталоге `AURAT-0103`; у
  вошедшего купона в этом окне не бывает).
- Страна: нативный `<select>`, оформленный как кнопка «🇪🇸 +34 ▾» хендоффа; список — 35
  SMS-регионов приложения (`SMS_REGIONS`, совпадает с `allowlistOnly` Firebase), названия —
  `Intl.DisplayNames` на текущем языке, сортировка по ним. По умолчанию — регион из
  `navigator.languages`, если он в списке, иначе ES (правило приложения `AURAT-0087`).
- Номер: `inputMode="tel"`, `autocomplete="tel-national"`, формат «как набирают» по стране
  (`formatNational`), длина — по стране (лишние цифры не вводятся), плейсхолдер — пример
  номера страны. Вставка `+44 7…` сама меняет страну. Номер чужого региона (+1 Канада/США —
  по самому номеру) → «We can't text numbers from {country} yet.»
- **Send code** активна при полном номере; Enter отправляет. Во время отправки — занята.
- Сноска: «We'll text you a 6-digit code. By continuing you confirm you are 18 or older and
  agree to our Terms of Use & Privacy Policy.» — ссылки на `aura-app.cc/terms/` и
  `/privacy/` (как в приложении), в новой вкладке. Плюс строка reCAPTCHA (см. ниже).

**Шаг «Код».**
- «Enter the code» / «Sent to +34 612 34 56 78 · change»; «change» и кнопка «назад» в шапке —
  к шагу телефона (номер сохранён).
- 6 ячеек поверх одного скрытого `<input inputmode="numeric" autocomplete="one-time-code"
  maxlength=6>` — автоподстановка кода из SMS работает в Safari и Chrome.
- Проверка через 480 мс после 6-й цифры (как в приложении), «Verifying…»; ошибка — тряска
  ячеек (без неё при `prefers-reduced-motion`), код очищается, текст ошибки под ячейками.
- «Resend code in 0:48» → «Resend code» (48 с, как в приложении); повторная отправка — новый
  код на тот же номер.

**Ошибки Firebase** → понятный текст (перенос `handleAuthError` приложения, ключами i18n):
неверный номер, неверный код, код истёк, запрос кода устарел, много попыток, лимит SMS,
нет сети, аккаунт отключён, регион не разрешён, проверка reCAPTCHA/домена не прошла, прочее.
В лог ничего не пишется — ни номер, ни uid, ни код.

**reCAPTCHA.** Невидимая (`RecaptchaVerifier`, `size: 'invisible'`), создаётся на попытку
отправки и очищается при закрытии окна. Плавающий значок Google скрыт (он перекрывает
таб-бар на телефоне); вместо него в сноске обязательная по правилам Google строка «This
site is protected by reCAPTCHA and the Google Privacy Policy and Terms of Service apply.»
со ссылками. SMS приходит на языке интерфейса (`auth.languageCode`).

**Тестовый режим** (как `AUTH_TEST_MODE` приложения): `VITE_FIREBASE_AUTH_TEST_MODE=true`
включает `appVerificationDisabledForTesting` — reCAPTCHA не спрашивается, работают только
тестовые номера Firebase. Читается только в dev-сборке; в production игнорируется. Нужен
для Playwright в маноре.

Firebase SDK по-прежнему живёт только в `shared/api/firebase.ts`: добавляется
`startPhoneSignIn(e164) → { confirm(code) }`, код ошибки Firebase наружу — строкой-кодом,
без сообщения SDK. Без Web App (`env.firebase = null`) входа нет: Log in и CTA GuestGate не
рисуются, gated-ссылки работают как обычные ссылки (как сейчас).

### 2. «Tell us who you are» — шаг 3 того же окна

- Правило приложения: после кода — `GET /v1/me` заново; ответ есть и `displayName` пуст →
  этот шаг; иначе окно закрывается и действие продолжается. Ошибка чтения профиля → тоже
  продолжаем (никогда не блокируем, как приложение).
- Эйбрау «Step 2 of 2», «Tell us who you are», «Your advisors greet you by name — the rest
  you can add whenever you like.»
- Поля (React Hook Form + Zod, константы и `ProfilePatchRequest` — из `@aura/contracts`):
  **Name** (обязательно, 2–64 после trim, как приложение и BFF; плейсхолдер «How should we
  call you?»); **Email — optional** (форма как в контракте, ошибка после ухода с поля);
  **Date of birth** `DD.MM.YYYY` — маска и проверка приложения (`maskBirthDate`,
  `toIsoBirthDate`: реальный день, ≥ 1900, не в будущем); **опт-ин** на рассылку —
  **выключен по умолчанию**, согласие отправляется всегда явно (как приложение, GDPR
  `AURAT-0042-108`; хендофф веба говорит «on» — здесь следуем приложению).
- CTA по причине: `book` — «Continue to booking», `null` — «Continue». `PATCH /v1/me`;
  ошибка → «That didn't save. Please try again.», введённое не теряется.
- Пропустить шаг нельзя (решение 1, как приложение `AURAT-0062`): кнопки Skip нет. × / Esc /
  Back закрывают окно — человек уже вошёл, но действие не продолжается; следующий gate (и
  «Add your name» на `/me`) снова открывает шаг имени.

### 3. Данные человека — `entities/user`

- `api`: `getMe` (`GET /v1/me`, `ProfileResponse.parse`) и `updateMe` (`PATCH /v1/me`, тело —
  `ProfilePatchRequest.parse`, ответ — `ProfileResponse.parse`, кладётся в кэш `getMe`).
- `model`: `useViewer()` — `displayName` (или пусто), `needsName`; гостю ничего не
  запрашивает.
- `ui`: `ViewerAvatar` — монограмма имени (без имени — иконка `user`); фото — с задачей `/me`
  (оно отдаётся только с токеном).
- Порт: `shared/lib/{phone,email,birth-date}.ts` — копией с тестами, шапка
  `// Ported from aura-app <path> (<ID>)`; `features/auth-by-phone/config/sms-regions.ts`,
  `OTP_LENGTH`, задержки, `LEGAL_URLS` в `shared/config`. Таблица стран приложения (245 строк
  с английскими названиями) не переносится — dial-код даёт `libphonenumber-js`, название —
  `Intl.DisplayNames` (отличие по правилам веба, как с форматтерами в `AURAT-0103`).
- Новые зависимости: `libphonenumber-js` (та же, что в приложении), `react-hook-form`,
  `@hookform/resolvers` (стек веба).

### 4. Gate с resume — `features/require-auth`

- `useRequireAuth()` → `gate({ reason, to })`: вошедший — сразу идёт в `to`; гость —
  открывается окно входа с этой причиной; после успеха (и шага имени) — переход в `to`, без
  `to` (Log in) — остаётся на месте.
- Ссылки остаются настоящими ссылками (`href`, открыть в новой вкладке работает): у гостя
  клик перехватывается и открывает вход. Подключаем к:
  - плитка и строка каталога: **Chat free** (`null` → `/chats/:id`), **Book** (`book` →
    `?book=1`);
  - профиль: слоты (`book` → `?book=1&slot=…`), **All dates**, **Book session** (`book`),
    **Free chat** (`null` → `/chats/:id`); то же в action bar телефона;
  - навигация: **Chats**, **Sessions** у гостя (`null` → страница) — NAVIGATION §1.1;
  - GuestGate: **Log in** (`null`, остаёмся — страница сама откроется после входа).
- Прямой заход гостя по ссылке `/advisors/:id?book=1[&slot=]` (например, из новой вкладки)
  один раз открывает вход с причиной `book`; × оставляет на профиле, повторно не открывается.
  После входа URL уже несёт данные — Book sheet по нему откроет задача брони.
- `DialogHost` получает «закрыть и перейти»: запись диалога в истории заменяется на `to`
  (Back с неё ведёт на исходную страницу, а не обратно в окно).
- **Намерение переживает перезагрузку (решение 3, `sessionStorage`).** Ключ `aura.auth` —
  одна запись на вкладку: `{ reason, to, step, savedAt }`, а на шаге кода ещё
  `verificationId`, номер E.164 и время отправки (для таймера повтора). После перезагрузки
  запись младше 15 минут снова открывает окно на том же шаге: код подтверждается
  `PhoneAuthProvider.credential(verificationId, code)` + `signInWithCredential` (тот же вход,
  что `ConfirmationResult.confirm`); на шаге имени — шаг имени. Запись удаляется при успехе,
  при закрытии окна (× / Esc / Back), при выходе и по истечении срока; битая — игнорируется.
  Хранилище вкладки — не лог: номер не уходит ни в логи, ни в аналитику, а живёт до закрытия
  вкладки или конца попытки. Чтение и запись — в try/catch (приватный режим): без хранилища
  всё работает, только без восстановления.

### 5. Шапка справа

- Гость: **Log in** (ghost-кнопка) → окно входа, причина `null`, остаёмся на странице.
- Вошедший: аватар-монограмма → `/me`, `aria-label` «Profile». Баланс «· Top up» — задача
  кошелька; колокольчик — v2; бейдж чатов — задача чата.
- Пока Firebase не ответил, кто это, — правая часть пустая (без мигания Log in → аватар).
- На телефоне — в той же 58-px шапке, тап ≥ 44 px.
- **Get started** не рисуется до задачи Home (решение 2) — у гостя только Log in.

### 5а. Временная `/me` (решение 4)

`pages/me` (за `PrivateRoute`): имя — или «Add your name» → окно на шаге имени; телефон
(только чтение, `formatPhoneNumber`); **Log out** → `signOut`, запись `aura.auth` удаляется,
переход на `/`. Этап 2 (`AURAF-0020-010`) заменит её полной страницей.

### 6. Смена человека сбрасывает ответы

- `shared/api/firebase.ts` замечает любую смену uid (вход, выход, другой аккаунт в соседней
  вкладке), uid наружу не отдаёт. На каждую смену — `resetApiState()`: открытые экраны
  переспрашивают каталог, цену (с оффером уже этого человека) и слоты от нового лица.
  Восстановление сессии при загрузке страницы сменой не считается.
- Остаётся как есть: `ACCOUNT_DELETED` → выход (`AURAT-0042`).

### 7. Строки

Новые namespace: `auth-by-phone`, `require-auth` (если будут свои строки), `user`;
дополнения `app` (Log in, Profile, …) и `shared`. Всё — английский и сразу 23 языка ЕС
(правило 9), плюралы — где нужны. Названия стран — `Intl.DisplayNames`, без переводов.

## Тесты

- Порты: `phone`, `email`, `birth-date` (тесты приложения на Vitest), SMS-регионы.
- Ошибки Firebase → ключ текста; страна по умолчанию из `navigator.languages`.
- Окно входа (Firebase замокан): Send code только при полном номере; вставка `+44…` меняет
  страну; чужой регион — текст; код из 6 цифр → проверка; неверный код — очистка и текст;
  таймер повтора; «change» — назад с номером.
- Шаг имени: нет `displayName` → шаг; есть → закрытие и resume; ошибка `/v1/me` → resume;
  валидация имени/email/даты; опт-ин по умолчанию выключен и уходит в PATCH; ошибка PATCH.
- Gate: гость — клик открывает вход, вошедший — переход; после входа — переход в `to`;
  Log in — остаёмся; прямой заход `?book=1` — вход один раз; × на шаге имени — без перехода.
- Намерение: запись в `sessionStorage`, восстановление на шаге кода и имени, истечение срока,
  удаление при закрытии / успехе / выходе, битая запись и недоступное хранилище.
- `/me`: имя / «Add your name», Log out.
- `DialogHost`: «закрыть и перейти» — Back ведёт на исходную страницу.
- Смена uid → `resetApiState`; восстановление при загрузке — нет.
- Шапка: гость — Log in; вошедший — аватар → `/me`; loading — пусто.

Зелёные `npm run lint && npm run typecheck && npm test && npm run build`.

## Проверка в маноре (после merge) — нужно от владельца

1. **Firebase Web App** в `aura-2781b`: Console → Project settings → Your apps → Add app →
   Web. `apiKey` и `appId` → `VITE_FIREBASE_API_KEY` и `VITE_FIREBASE_APP_ID` в `.env.local`
   манора (`project/manor/master/aura-web/.env.local`). Ключ веба — не секрет, но в Google
   Cloud → Credentials его стоит ограничить HTTP-рефералами (`localhost:5173`, будущий домен).
2. **Тестовые номера** (Authentication → Sign-in method → Phone → Phone numbers for
   testing), чтобы проверять без SMS, например:
   - `+34 600 000 001` / `123456` — существующий аккаунт с именем (войти и сразу продолжить);
   - `+34 600 000 002` / `654321` — новый (шаг «Tell us who you are»).
   Плюс `VITE_FIREBASE_AUTH_TEST_MODE=true` в `.env.local` для headless Chrome.
3. **Authorized domains**: `localhost` есть по умолчанию; будущий домен веба — при деплое.
4. `WEB_ALLOWED_ORIGINS` у bff-dev включает `http://localhost:5173` (сделано в `AURAT-0102`;
   проверю в маноре).

## Вне задачи

Home, Ask и `/match` (причина `ask`, Get started), Book sheet и оплата, чат и его бейдж,
кошелёк и баланс в шапке, фото профиля, полная страница `/me` и правка профиля (этап 2), удаление аккаунта,
веб-push, аналитика (`auth_*` — нет инфраструктуры аналитики).

## После задачи (brain)

`AURAF-0020`: UI ✗ → ✓ в 003 (убрать «или пропускает» — решение 1) и 004.

## Решения владельца (2026-10-20, `006`)

1. «Skip for now» — **нет**, как в приложении (`AURAT-0062`); × закрывает окно без resume.
2. Get started — **не рисовать** до задачи Home.
3. Намерение resume — **в `sessionStorage`** (вместе с шагом кода), см. §4.
4. Выход — **временная `/me`** (имя / «Add your name», телефон, Log out), см. §5а.
