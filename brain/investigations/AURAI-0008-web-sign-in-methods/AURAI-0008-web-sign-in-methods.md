# AURAI-0008 — Способы входа на вебе: почта, Google, Apple, Facebook рядом с SMS

Дата: 2026-10-23
Статус: **Research** — владелец 2026-10-23 одобрил модель B (раздел 3), оффер «как есть +
метрика», почту «ссылка и код, выбор на экране» по обновлённому хендоффу, ссылку «впускает
только свой браузер», код из 6 цифр (раздел 4), шаг имени без Skip, приложение — отдельной фичей
(раздел 7); Facebook — рекомендация в разделе 5, ждёт подтверждения (раздел 12). ID решения и
задач выдаются в `aura-app-manor/active-work.md` после одобрения
Связано: `AURAD-0019` (веб, тот же Firebase-проект), `AURAF-0020` (спека веба), `AURAT-0104`
(вход по телефону на вебе), `AURAT-0043` / `AURAT-0087` (SMS, allowlist регионов), `AURAS-0004`
(стоимость, Resend, Blaze), `AURAI-0005` (реклама Meta, US + CA), `AURAT-0124` (nginx, CSP)

## Decision (проект)

Один аккаунт = один Firebase uid, к которому привязываются способы входа; на вебе по умолчанию
почта — одно письмо со ссылкой и кодом, выдаёт и проверяет BFF, вход — Firebase custom token;
рядом Apple, Google, Facebook и SMS, набор и порядок по браузеру (во встроенных браузерах
Facebook / Instagram нет Google); новый аккаунт не-телефонным способом сначала спрашивает
«у вас уже есть Aura в приложении?»; приложение получает те же способы отдельной фичей позже.

## Context

- Сейчас вход везде только по SMS. На вебе — `src/features/auth-by-phone` (шаги phone → code →
  name), на приложении — `@react-native-firebase/auth`, `verifyPhoneNumber`.
- Владелец (2026-10-23): узнать, что стоит авторизация; добавить на вебе почту (ссылка или код),
  Apple, Google, Facebook — «оттуда много людей идёт»; SMS остаётся.
- Окно входа веба обещает «One account for the app and the web»
  (`auth-by-phone/config/locales/en.ts:12`). Сейчас это правда только потому, что способ один.

## 1. Деньги — измерено 2026-10-23

Чтение конфигурации и метрик проекта `aura-2781b` (`identitytoolkit admin/v2 …/config`,
Cloud Monitoring `identitytoolkit.googleapis.com/usage/*`), только чтение.

### Как устроен проект

| Что | Значение |
|---|---|
| Продукт | `subtype: FIREBASE_AUTH` — **стандартный Firebase Auth, не Identity Platform** |
| План | Blaze, платёжный аккаунт привязан (`billingEnabled: true`), кредит $300 до ~2026-11-26 |
| Включённые способы | только `phoneNumber` (+ тестовый номер); `defaultSupportedIdpConfigs` пуст — ни Google, ни Apple, ни Facebook, ни почты |
| SMS-регионы | `allowlistOnly`, 35 регионов (EU-27 + CH, GB, IS, LI, NO, UA, CA, US) |
| Authorized domains | `localhost`, `aura-2781b.firebaseapp.com`, `aura-2781b.web.app`, `web-dev.aura-app.cc`, `web.aura-app.cc` |
| Защита от перечисления почт | включена (`emailPrivacyConfig.enableImprovedEmailPrivacy: true`) |
| Свой домен для писем Firebase | не настроен (`customDomainState: NOT_STARTED`), письма идут с `noreply@aura-2781b.firebaseapp.com` |
| App Check | нет ни в приложении, ни на вебе |

### Что тарифицируется

- **Платим только за SMS** — за каждое отправленное, по стране получателя; повторная отправка —
  ещё одна SMS. По прайсу Identity Platform (Firebase ссылается на него): «The first ten SMS that
  you send per day are not billed». Распространяется ли это на `FIREBASE_AUTH`-проект — видно
  только в Cloud Billing → Reports (смотрит владелец).
- Цены за SMS (2026-10-23): US $0.01, CA $0.01, PL $0.02, CY $0.03, ES $0.04, GB $0.04,
  DK $0.05, IT $0.05, CZ / HU / IE / IS $0.06, FR $0.07, FI $0.08, DE $0.10, HR $0.10, UA $0.15.
- Почта, телефон, анонимные, соцсети (Google, Apple, Facebook) — Tier 1, **$0 до 50 000 MAU**.
  SAML / OIDC — $0 до 50 MAU (нам не нужны).
- Потолок: у стандартного Firebase Auth — **3 000 SMS в сутки** на проект; у Identity Platform
  потолка нет. На IP — 150 запросов на верификацию в час, 100 новых аккаунтов в час.
  Письма для входа по ссылке на Blaze — 25 000 в сутки. Custom token — 45 000 входов в минуту.
- Бюджет-алерт $25/мес только предупреждает; жёсткого лимита расхода на SMS в Google Cloud нет
  (`AURAT-0043-003`). Защита от SMS-pumping — allowlist регионов; App Check нет.

### Фактические отправки

За 30 дней (2026-09-23 … 2026-10-23), `usage/sent_sms_count`:

| Страна | SMS | Цена | Сумма по прайсу |
|---|---:|---:|---:|
| US | 355 | $0.01 | $3.55 |
| CA | 43 | $0.01 | $0.43 |
| ES | 34 | $0.04 | $1.36 |
| GB | 4 | $0.04 | $0.16 |
| IE | 3 | $0.06 | $0.18 |
| DE | 1 | $0.10 | $0.10 |
| PL | 1 | $0.02 | $0.02 |
| **Всего** | **441** | | **≈ $5.80** (минус бесплатные 10 в сутки, если применимы — ≈ $4.5–5) |

По дням: до 2026-10-15 — 0–8 SMS в сутки; **с 2026-10-16 (старт рекламы `AURAI-0005`, US + CA)
— 30–78 в сутки**, в среднем ≈ 53, из них ≈ 80 % — США. Активные пользователи за месяц
(`monthly_new_signin_count`) — 340 (сентябрь — 24).

Заблокировано allowlist'ом (`blocked_sms_count`): в сентябре — AD 12, FI 8, AF 7, AR 6, AL 4,
AW 4, DZ 4, US 10, UA 1 (до расширения списка в `AURAT-0087`); в октябре — CA 7, PK 1. Попытки
из AD / AF / AL / AW / DZ похожи на пробы SMS-pumping — allowlist их отрезал.

### Прогноз

- При текущих $20/день рекламы на US + CA: ≈ 50–60 SMS в сутки × $0.01 ≈ **$15–20 в месяц**.
  До ~2026-11-26 это покрывает кредит; дальше — реальный счёт.
- Европа дороже в 4–10 раз: та же воронка на DE / FR стоила бы $3–6 в сутки.
- Каждый вход через Google / Apple / Facebook / почту вместо SMS — минус одна-две SMS.
  Новые способы снижают расход, а не повышают.
- Код на почту — это наши письма через Resend: бесплатно 3 000 в месяц **и 100 в сутки**, и этот
  лимит уже делят письма Chatwoot (`AURAS-0004`). При > ~80 входов почтой в сутки — Resend Pro,
  $20/мес за 50 000 писем без суточного лимита.
- Переход на Identity Platform снимает потолок 3 000 SMS/сутки и даёт blocking functions;
  цены за MAU и SMS те же. Сейчас не нужен: мы в 50 раз ниже потолка.

## 2. Что есть сейчас

### Веб (`aura-web` `develop` @ `280988a`)

- `src/shared/api/firebase.ts`: `initializeAuth` с `browserLocalPersistence` **без
  `popupRedirectResolver`** — popup / redirect сейчас невозможны; невидимый `RecaptchaVerifier`
  на каждую попытку; `signInWithPhoneNumber` → `verificationId` (переживает reload),
  `signInWithCredential`. Статус наружу — только `guest | signed-in`, ни uid, ни телефона.
- `features/auth-by-phone`: `use-auth-dialog.ts` — шаги `phone → code → name`, попытка в
  `sessionStorage` (`aura.auth`, 15 мин), resume через `require-auth`. Шаг `name` — общий для
  любого способа, его можно оставить.
- `deploy/web/headers.conf`: CSP рассчитан на одну reCAPTCHA — нет `apis.google.com`, нет
  `frame-src` для `authDomain`, `frame-ancestors 'none'` на всех путях.
- `deploy/web/nginx.conf`: SPA-fallback; путей `/__/auth/` нет.
- `env.ts`: `VITE_FIREBASE_AUTH_DOMAIN` уже переменная окружения — подставить свой домен можно
  без кода.

### BFF (`aura-bff` manor master)

- Аккаунт — по `firebaseUid` (`prisma/schema.prisma:16`, `@unique`); `phoneE164` и `email`
  необязательные и не уникальные (`:17`, `:22-25` — «contact detail, not a login»).
- `FirebaseAuthGuard` (`src/common/guards/firebase-auth.guard.ts:96-99`) читает только `uid` и
  `phone_number`; токен без телефона **не отвергается** — `phoneE164` = `null`. `email`,
  `email_verified`, `firebase.sign_in_provider` не читаются. `ensureUser` — upsert по uid на
  каждом запросе (`users.service.ts:19-24`), телефон не затирается `null`. То же в WS-шлюзе
  (`chat.gateway.ts:62-75`).
- Chatwoot: `identifier` = uid, телефон — только если валидный E.164
  (`provisioning.service.ts:151-160`); почта в Chatwoot не уходит. Без телефона контакт
  создаётся без номера — работает.
- Профиль: `GET / PATCH /v1/me`, `phoneE164` nullable; почту можно поставить `PATCH`ем
  (lower-case, **не проверяется**); телефон через `PATCH` — 400.
- Удаление: `DELETE /v1/me` → Admin `deleteUser(uid)` — работает для любого способа. Операторский
  CLI ищет аккаунт по телефону (`src/account-erasure.ts`), **`--email` нет** — безтелефонный
  аккаунт стирается только по `--user`.
- Firebase Admin: `verifyIdToken`, `deleteUser`, `messaging()`. `createCustomToken`,
  `getUserByEmail`, `createUser`, `updateUser` не используются; `createCustomToken` подписывает
  локально ключом того же сервис-аккаунта — новых прав не надо.
- Почты нет вовсе (ни Resend, ни SMTP). Rate limit — один глобальный `@fastify/rate-limit`
  120/мин на IP в памяти; есть глобальный Redis (`REDIS_CLIENT`) — хватит под коды с TTL и
  счётчики попыток.
- Склейки аккаунтов нет и сознательно не делалась (`provisioning.service.ts:136-146`,
  `TECH-DEBT.md` #34).
- Оффер первой сессии — по `userId` (`first-session-offer.query.ts:13-21`): **новый способ =
  новый аккаунт = новый оффер**.
- Контракты `v0.24.0`: `ProfileResponse.phoneE164` nullable (`aura-contracts/src/profile.ts:136`),
  но комментарии (`:7-10`, `:133-135`) говорят «телефон есть всегда и это ключ аккаунта» —
  устареют.

### Приложение

- Только SMS: `auth.service.ts` (`verifyPhoneNumber`, `signInWithCredential`), OTP 6, повтор 48 с,
  allowlist как у Firebase, App Check нет, тестовый режим выключен во всех `.env`.
- `user.phoneNumber` из Firebase не читается; телефон и почта — из профиля BFF; без телефона —
  пустая строка, не падение.
- Линковки нет (`linkWithCredential`, `providerData` не встречаются). Sign in with Apple — нет
  в entitlements; Google Sign-In — нет пакета, `oauth_client` в `google-services.json` пустой;
  Facebook SDK `react-native-fbsdk-next` — только Android, только события атрибуции, на iOS
  исключён намеренно (правила трекинга App Store). Meta App ID `4422398391357112`.
- Правило App Store 4.8 в репо не упоминается; пока приложение только с телефоном — не действует.

## 3. Главная проблема: один аккаунт

Firebase склеивает способы только по **почте**, и только для «доверенных» провайдеров (Google для
своих адресов, Apple для своих). У телефонного аккаунта почты в Firebase нет. Значит:

> Человек зарегистрировался в приложении по номеру, пришёл на веб и нажал «Google» → **новый uid**
> → новый пустой аккаунт: без баланса, сессий, чатов, и с ещё одним оффером первой сессии.

Обратное тоже верно: зарегистрировался на вебе через Google → в приложении (только SMS) — новый
аккаунт по номеру.

Объединить два uid задним числом нельзя без склейки данных в BFF (кошелёк, сессии, чаты,
Chatwoot-контакт, отзывы) — это та самая «O5», которую не ратифицировали. Её и не делаем:
вместо склейки — **не допускать второго аккаунта** и **привязывать способы к одному uid**.

### Варианты модели

| | Как | Плюсы | Минусы |
|---|---|---|---|
| A. Каждый способ — свой аккаунт | ничего не делать | ноль работы | ломает обещание «один аккаунт»; люди из приложения теряют баланс на вебе |
| **B. Один uid, привязка способов** | Firebase `linkWithCredential` / `linkWithPopup`; почта — через BFF; при первом входе новым способом — вопрос «уже есть Aura?» | честный «один аккаунт»; без склейки данных | интерстишел на первом входе; работа в вебе и BFF |
| C. Склейка двух аккаунтов в BFF | перенос кошелька, сессий, чатов | исправляет уже случившееся | дорого и рискованно (деньги, Chatwoot); `O5` не ратифицирована |

**Рекомендация — B.** C — только если реальные дубли появятся в заметном числе.

### Как работает B

1. **Первый вход новым способом** (Google / Apple / Facebook / почта) — `isNewUser` у Firebase
   (или 404/пустой профиль у BFF) → до любого запроса к BFF, создающего строку, экран:
   «Новый в Aura? → Продолжить» / «Уже пользуюсь Aura в приложении → Войти по номеру».
   Во втором случае веб сохраняет полученный credential (`GoogleAuthProvider.credentialFromResult`
   и т. п.), удаляет только что созданного пустого Firebase-пользователя (`user.delete()` — вход
   свежий, повторная аутентификация не нужна), проводит вход по SMS и делает
   `linkWithCredential(phoneUser, credential)`. Итог: один uid, два способа.
   - `ensureUser` срабатывает на первом же запросе к BFF — поэтому интерстишел стоит **до**
     `readViewer()`. Иначе остаётся пустая строка `User` (вреда нет, но мусор и лишний
     Chatwoot-контакт при первом сообщении).
   - Если credential не переиспользуется (истёк, провайдер не позволил) — после SMS-входа
     просим нажать кнопку провайдера ещё раз → `linkWithPopup` / `linkWithRedirect`.
2. **Привязка из профиля** (`/me` → «Способы входа»): список привязанных, «Добавить Google /
   Apple / Facebook / почту / телефон», «Отвязать» (кроме последнего). `auth/credential-already-
   in-use` → «Этот Google уже вход в другой аккаунт Aura» — без склейки.
3. **Телефон для приложения.** Пока приложение только по SMS, человек с веба без телефона в
   приложение своим аккаунтом не войдёт. На `/me` и на Booked — «Пользуетесь приложением?
   Добавьте номер» (`linkWithPhoneNumber`, одна SMS). Это снимается, когда приложение получит
   те же способы.
4. **Почта не склеивает сама.** Защита от перечисления включена — `fetchSignInMethodsForEmail`
   ничего не скажет; на `auth/account-exists-with-different-credential` (Facebook с почтой,
   которая уже у Google-аккаунта) — «Войдите способом, которым входили раньше, и привяжите
   Facebook в профиле». Как Firebase поведёт себя, если почта у пользователя — поле custom-token
   аккаунта, а не провайдер, **проверить на web-dev** в задаче веба.

### Оффер первой сессии

Телефон был естественным ограничителем «один человек — один оффер» (SMS стоит денег, номер не
бесплатен). Почта бесплатна → завести десять аккаунтов и получить десять офферов дёшево.
Варианты: (а) принять риск — оффер только скидка на первую **оплаченную** сессию, баланс всё
равно пополняется деньгами; (б) оффер только после привязанного телефона; (в) лимит по
устройству / платёжному методу позже. **Владелец 2026-10-23: (а) + метрика доли офферов у
аккаунтов без телефона**; при злоупотреблении — (б).

## 4. Почта: ссылка и код в одном письме

### Хендофф (обновлён 2026-10-23, только окно входа)

Новый `design_handoff_aura_web/README.md` §4.4 (`/Volumes/Work/personal/design_handoff_aura_web`,
`Aura-web.zip`; остальное и `src/` хендоффа не менялись):

1. **По умолчанию — почта.** Заголовок по причине («Join now or log in» / «Log in to send your
   question» / «Log in to book your session»), купон, поле почты + **Continue with email**.
   Без пароля: письмо со **ссылкой и кодом**.
2. Под «or continue with» — **Apple · Google · Phone**, равные кнопки, официальные знаки. На шаге
   телефона третья кнопка становится **Email**.
3. **Сначала ссылка.** «Check your inbox»: «We sent a login link to … tap **Log in to Aura**»;
   **Open Gmail / Open Outlook**; ghost **Enter code instead** («On another device? The email also
   has a 4-digit code»); повтор через 0:48 · спам · сменить почту. **Вкладка ждёт (poll / WebSocket)
   и входит, когда ссылку открыли — даже на другом устройстве.** «Enter code instead» — 4 ячейки,
   авто-проверка, «← Use the login link instead».
4. Apple / Google — popup; подтверждённая почта (у Apple — возможно релей), у Google — имя.
5. Сервер отвечает `isNew`. Новый → «Tell us who you are»: имя (обязательно, из Google), **почта
   заблокирована + «Verified»** для почты / Apple / Google, для телефона — редактируемая «for
   receipts»; дата рождения; рассылка (письма — только на подтверждённую почту). Skippable.
6. «Accounts are linked by verified email (Google / Apple / email с одним адресом = один
   пользователь)». API хендоффа — `POST /auth/email`, `/auth/email/verify {code | token}`,
   `/auth/oauth/{apple|google}` → `{ token, isNew, profile? }`.

Это совпадает с моделью B и с выбором владельца: **ссылка и код, выбор на экране** — оба в
одном письме, одна попытка.

### Почему не ссылка Firebase

`sendSignInLinkToEmail` даёт только ссылку (кода нет), письмо — шаблон Firebase с отправителем
`firebaseapp.com`, без 24 языков; вход случается **в том браузере, где открыли ссылку**, а
ждущая вкладка про это не узнает. Ссылка и код в одном письме, ожидание во вкладке, свой шаблон —
это свой механизм: **BFF выдаёт попытку, письмо через Resend, вход — custom token.**
Email-провайдер Firebase не включаем.

| | Ссылка | Код |
|---|---|---|
| Тот же браузер (почта в соседней вкладке) | вход во вкладке ссылки; ждущая вкладка подхватит его сама — Firebase синхронизирует вход между вкладками одного origin (`browserLocalPersistence`) | вводится в той же вкладке |
| Webview Instagram / Facebook, телефон → компьютер | ссылка откроется в другом браузере → вход ждущей вкладки — только через подтверждение (ниже) | работает без оговорок |
| Сканеры ссылок (Outlook Safe Links и т. п.) | ссылка не входит по GET — страница с кнопкой «Log in to Aura» | нет |

### Вход ждущей вкладки по ссылке с другого устройства — риск

Если ссылка, открытая где угодно, впускает **ждущую вкладку**, то злоумышленник вводит чужую
почту у себя, жертва получает настоящее письмо Aura и жмёт «Log in to Aura» — и вход получает
вкладка злоумышленника (классический фишинг «approve on another device»). Код этим не страдает:
его вводит тот, кто читает письмо.

Варианты:

| | Как | Оценка |
|---|---|---|
| **A. Ссылка впускает только себя** | вкладка ссылки входит; ждущая — только если это тот же браузер (синхронизация Firebase); на другом устройстве — «вы вошли здесь; на том устройстве введите код» | безопасно, просто; «даже на другом устройстве» из хендоффа — через код |
| **B. Подтверждение на странице ссылки** | вкладка ссылки входит сама **и** показывает «Войти также в Chrome на Windows, Мадрид, 18:42? — Да / Это не я»; ждущая вкладка входит после «Да» | ближе к хендоффу; фишинг сужен до невнимательного «Да»; больше работы (описание устройства, ожидание во вкладке) |
| C. Как в хендоффе без подтверждения | открыли ссылку → ждущая вкладка вошла | **не делать** |

**Владелец 2026-10-23: A** (по рекомендации), B — отдельной строкой, если метрика покажет, что люди открывают
ссылку на другом устройстве и не доходят до кода. Ожидание во вкладке нужно в обоих случаях —
в A для того же браузера его даёт сам Firebase, без опроса BFF.

### Код: 6 цифр, а не 4

Хендофф рисует 4 ячейки. Для аккаунта с деньгами 4 цифры мало: при 5 попытках на код и 5 кодах
в час на почту перебор — ≈ 0,25 % в час на выбранную почту, ≈ 6 % за сутки. 6 цифр — 0,0025 %
в час. SMS уже 6 цифр (Firebase), одна длина везде проще. **Владелец 2026-10-23: 6** (как с
SMS-кодом против 4 ячеек хендоффа, `AURAI-0007`).

### BFF

- `POST /v1/auth/email` `@Public` `{ email, language }` → `202 { attemptId }`, ответ одинаковый
  для любой почты (без перечисления). Попытка в Redis: хэш кода (6 цифр), хэш токена ссылки
  (32 байта), TTL 15 мин; новая попытка гасит старую.
- Письмо (Resend, отправитель на `send.aura-app.cc`, 24 языка): кнопка «Log in to Aura» →
  `https://<веб>/auth/email?t=<token>` и код крупно; код в теме для автозаполнения.
- `POST /v1/auth/email/verify` `@Public` `{ email, code }` **или** `{ token }` → `{ customToken,
  isNew }`: `getUserByEmail` → нет — `createUser({ email, emailVerified: true })` →
  `createCustomToken(uid)`. Веб: `signInWithCustomToken`. Страница `/auth/email` вызывает его по
  кнопке, не на загрузке (сканеры).
- Привязка из профиля — те же два шага с токеном: `POST /v1/me/email`, `/v1/me/email/verify` →
  Admin `updateUser(uid, { email, emailVerified: true })`; почта у другого uid → `409 email_in_use`.
- Лимиты (Redis): на почту — 1 письмо в 60 с (UI — 48 с, как SMS), 5 в час; на IP — 20 в час;
  5 неверных кодов гасят попытку; 3 сожжённые попытки — пауза 15 мин. Сравнение за постоянное
  время. Капча — не на запуске; при mail-bombing — Turnstile перед отправкой.
- Нормализация: trim + lower-case; точки и `+` у Gmail не трогаем. Почта, код и токен — не в логи.

### Google / Apple с той же почтой

Хендофф: «один адрес = один пользователь». У Firebase («Link accounts that use the same email»)
Google / Apple с почтой, которая уже есть у другого uid, дают
`auth/account-exists-with-different-credential` — Firebase сам такие способы не склеивает (кроме
случаев, когда Google вытесняет неподтверждённую почту). Что делаем:

- веб отправляет ID token провайдера из ошибки в BFF: `POST /v1/auth/oauth/link-by-email
  { providerIdToken }`; BFF проверяет его (Google — `oauth2.googleapis.com` JWKS, Apple —
  `appleid.apple.com` JWKS, аудитория — наш client / Services ID, `email_verified`), находит uid по
  почте, отдаёт `customToken`;
- веб входит custom token'ом и делает `linkWithCredential(credential)` — дальше Google входит в
  этот uid напрямую;
- Facebook почту не подтверждает — для него только «войдите прежним способом и привяжите Facebook
  в профиле».

Точное поведение Firebase при почте у custom-token-пользователя — **проверить на web-dev** первым
шагом задачи веба: если Firebase сам впустит Google в существующий uid, эндпоинт BFF не нужен.

### Расхождения хендоффа с ранее принятым — решить

| Хендофф | Сейчас | Предложение |
|---|---|---|
| Код 4 цифры | SMS 6 (Firebase) | **6 и для почты** (владелец 2026-10-23) |
| Провайдеры Apple · Google · Phone | владелец хочет и Facebook | Apple · Google · Facebook · Phone; по браузеру (раздел 5) |
| «Tell us who you are» — Skippable | без Skip (владелец, `AURAT-0104-006`, как приложение `AURAT-0062`) | **без Skip** (владелец 2026-10-23): шаг пропустить нельзя, выход — только закрыть окно; вход при этом состоялся, но действие не продолжается, и следующий gate снова спросит имя |
| Профиль: «Phone (locked, it is the login)» | — | «Способы входа» в `/me`; телефон и почта — по тому, что привязано |
| Интерстишел «уже есть Aura в приложении?» | — | в хендоффе нет — нужен экран от дизайнера (до «Tell us who you are») |
| API `/auth/oauth/{apple\|google} {idToken}` для любого входа | Firebase-провайдеры на клиенте (`AURAD-0019`) | OAuth — Firebase на клиенте; BFF — только почта и `link-by-email` |

## 5. Кнопки по браузеру

Google блокирует OAuth во встроенных браузерах (`disallowed_useragent`) — в webview Facebook /
Instagram кнопка Google только сломается. Почта — по умолчанию везде (хендофф); меняется ряд
«or continue with».

| Окружение | Признак (UA) | Ряд «or continue with» |
|---|---|---|
| Webview Facebook / Instagram | `FBAN` / `FBAV` / `FB_IAB` / `Instagram` | **Facebook** · Apple · Phone; Google **нет** (+ строка «Открыть в браузере — вход через Google») |
| Прочие webview (TikTok, LinkedIn, Line, …) | `musical_ly` / `BytedanceWebview` / `LinkedInApp` / `Line/` / Android `; wv)` | Apple · Phone · Facebook; Google нет |
| iOS / macOS Safari | Apple-платформа | **Apple** · Google · Phone · Facebook |
| Остальные браузеры | — | **Google** · Apple · Phone · Facebook |

- Popup — на desktop (не теряет состояние SPA); **redirect** — на телефонах и во всех webview
  (popup там либо блокируется, либо открывается без `opener`). `getRedirectResult` на старте;
  попытка и resume — тот же `sessionStorage` (`aura.auth`), что и сейчас.
- Во webview Meta письмо со ссылкой откроется вне webview — экран «Check your inbox» там сразу
  предлагает код (кнопка «Enter code» основная, не ghost).
- Распознавание — чистая функция в `shared/lib` с тестами на набор реальных UA; ложное «это
  webview» прячет Google — терпимо, ложное «не webview» показывает сломанную кнопку — поэтому
  список признаков широкий.

### Facebook: нужен ли и где

Владелец спросил «а как лучше?» (2026-10-23). Разбор:

| За | Против |
|---|---|
| Реклама идёт в Facebook / Instagram (`AURAI-0005`); во webview Meta Google не работает, а Facebook — один-два тапа (во webview Facebook человек уже залогинен) | Почты нередко нет (аккаунты Facebook по номеру) → аккаунт Aura без почты, чеки и рассылка — только если человек добавит её сам |
| Для Firebase — $0, Tier 1 | Почту Facebook Firebase не считает подтверждённой — сам с Google / почтой не склеит; привязка только из профиля |
| Кода на вебе почти нет сверх Google / Apple — тот же `signInWithPopup` / `Redirect` | Настройка Meta: Live-режим, privacy, удаление данных; для `email` / `public_profile` у бизнес-приложений может понадобиться Advanced Access и **Business Verification** (источники расходятся — проверить в консоли) |

**Рекомендация:** Facebook — **да**, но не равной четвёртой кнопкой везде, а по месту:
**первой кнопкой во webview Facebook / Instagram** (там это лучший путь после почты), в обычных
браузерах — последней в ряду или за «More options», чтобы ряд хендоффа «Apple · Google · Phone»
не разрастался. Instagram-webview: у человека может не быть сессии Facebook — тогда откроется
форма входа Facebook, это нормально.

**В каком Meta App — в существующем** `4422398391357112` (тот, что для событий Android): один
App ID на продукт — так задумано у Meta; privacy / удаление данных / Live / верификация бизнеса
делаются один раз; события рекламы и вход видят одного и того же человека. Отдельное приложение
имеет смысл только если боимся, что ограничение Login зацепит атрибуцию рекламы, — для
`public_profile` + `email` риск низкий. App Secret этого приложения уходит в Firebase — он и так
не должен лежать в клиенте; в приложении используется только client token.

## 6. `authDomain`, nginx, CSP

Redirect-вход с `authDomain = aura-2781b.firebaseapp.com` ломается в Safari и при блокировке
сторонних кук (хранилище чужого домена). Вариант из «Best practices for using signInWithRedirect»
Firebase — **проксировать `/__/auth/` через наш nginx** и сделать `authDomain` своим доменом:

- `nginx.conf`: `location /__/auth/` и `location = /__/firebase/init.json` → `proxy_pass
  https://aura-2781b.firebaseapp.com` с `proxy_ssl_server_name on` и `Host` проекта. Без
  SPA-fallback и без `Cache-Control: no-cache` от SPA.
- Для этих путей **не** включать наш `headers.conf`: handler грузится в iframe нашей же
  страницы, а `frame-ancestors 'none'` его запретит. Минимум — `frame-ancestors 'self'`.
- `VITE_FIREBASE_AUTH_DOMAIN` = `web-dev.aura-app.cc` / `web.aura-app.cc` по окружению
  (`deploy/web/build.sh` уже требует переменную).
- `firebase.ts`: `initializeAuth(…, { persistence, popupRedirectResolver:
  browserPopupRedirectResolver })` — подгружается лениво вместе с диалогом входа.
- CSP главной страницы: `script-src` + `https://apis.google.com`; `frame-src` + `'self'`
  (handler на нашем домене); `connect-src` + `https://www.googleapis.com` (по факту проверить
  в консоли браузера на web-dev); `form-action` — Apple в web-флоу делает `form_post` на
  handler (`'self'`) — проверить.
- Redirect URI у провайдеров — на **каждое** окружение: `https://web-dev.aura-app.cc/__/auth/handler`,
  `https://web.aura-app.cc/__/auth/handler` (+ `https://aura-2781b.firebaseapp.com/__/auth/handler`
  для локальной разработки).
- Маршрут `/auth/email` (страница ссылки из письма) — обычный маршрут SPA.

## 7. Паритет с приложением

- **Сейчас** — только веб. Приложение остаётся на SMS; мостик — «Добавьте номер для приложения»
  (раздел 3, п. 3).
- **Следом** (владелец 2026-10-23: отдельной фичей) — для приложения: Google, Apple, почта (код; ссылка — через universal
  links, решить там) + Facebook на Android; на iOS FBSDK исключён намеренно — Facebook там или
  через Limited Login, или не нужен. На iOS при любом стороннем входе **обязателен** Sign in with
  Apple или аналог (App Store 4.8) — Apple в наборе есть. Плюс экран «Способы входа» и тот же
  интерстишел «уже есть аккаунт?».
- Пока паритета нет, на вебе честнее строка: «One account for the app and the web — the app
  signs in with your phone» → после паритета вернуть короткую.

## 8. Рекомендация (сводно)

1. Модель B: один uid, привязка способов, без склейки данных; интерстишел на первом входе
   (**одобрено**).
2. Почта по умолчанию — одно письмо со **ссылкой и кодом**, выбор на экране (**одобрено**,
   хендофф); BFF + custom token; ссылка впускает только свой браузер (вариант A); код 6 цифр.
3. Ряд провайдеров: Apple · Google · Phone (хендофф); Facebook — первым во webview Meta, в
   обычных браузерах — последним; наличие Google — по браузеру. Шаг имени — без Skip
   (**одобрено**).
4. `authDomain` — наш домен, прокси `/__/auth/` в nginx; popup на desktop, redirect на телефонах.
5. BFF: почта из токена (`email` при `email_verified`), попытки почты, Resend, лимиты в Redis,
   `link-by-email` (если Firebase сам не впустит), `--email` в CLI удаления.
6. Оффер первой сессии — как есть + метрика (**одобрено**).
7. Приложение — позже, своей фичей (**одобрено**); до того — привязка телефона с веба.
8. Деньги: SMS ≈ $15–20/мес при текущей рекламе после кредита; новые способы $0 и снижают SMS;
   Resend Pro $20/мес — когда входов почтой станет > ~80 в сутки. Identity Platform не нужен.

## 9. Проект решения (AURAD — ID после одобрения)

- **Р1. Один аккаунт** (одобрено 2026-10-23). Аккаунт Aura = Firebase uid; способы входа
  привязываются к нему. Данные двух uid не склеиваются (O5 остаётся не ратифицированной). Второй
  аккаунт предотвращается: интерстишел при первом входе новым способом,
  `credential-already-in-use` — отказ с объяснением; один подтверждённый адрес = один uid.
- **Р2. Способы на вебе:** почта по умолчанию; Apple, Google, SMS; Facebook — первым во webview
  Meta, в обычных браузерах последним (ждёт подтверждения), в существующем Meta App. Google скрыт
  во встроенных браузерах.
- **Р3. Почта** (одобрено 2026-10-23: ссылка и код, выбор на экране; код 6 цифр; ссылка — только
  свой браузер). Одно письмо — ссылка и код из 6 цифр; выдаёт и проверяет BFF, вход — Firebase custom token. Email-провайдер Firebase не
  используется. Ссылка впускает только браузер, в котором открыта; другое устройство — кодом.
- **Р4. authDomain — домен веба** с прокси `/__/auth/`; popup на desktop, redirect на телефоне и
  в webview.
- **Р5. Почта в профиле.** `email` в BFF — подтверждённая (токен с `email_verified`, код /
  ссылка); у пользователя по телефону — редактируемое поле «for receipts» до подтверждения
  (хендофф); письма рассылки — только на подтверждённую.
- **Р6. Оффер первой сессии** (одобрено 2026-10-23) — как есть (по аккаунту) + метрика доли у
  аккаунтов без телефона; ужесточение — по данным.
- **Р7. Приложение** (одобрено 2026-10-23) — способы позже отдельной фичей; до неё — привязка
  телефона с веба и уточнённая строка «One account…».
- **Р8. Шаг имени без Skip** (одобрено 2026-10-23, подтверждает `AURAT-0104-006`) для любого
  способа: пропустить нельзя, выход — только закрыть окно; действие не продолжается, следующий
  gate снова спрашивает имя. Имя из Google / Apple подставляется, но шаг всё равно показывается,
  если имени нет.

## 10. Задачи по репозиториям (ID после одобрения, в `aura-app-manor`)

| # | Репо | Что | Зависит от |
|---|---|---|---|
| 1 | консоли (владелец) | Google, Apple, Meta, Firebase — чек-лист раздела 11 | — |
| 2 | дизайн (владелец / дизайнер) | интерстишел «уже есть Aura в приложении?»; «Способы входа» в `/me`; Facebook (первым во webview Meta, последним в ряду иначе); 6 ячеек кода; шаг имени без «Skip for now» | — |
| 3 | `aura-contracts` | `EmailStartRequest` / `EmailStartResponse { attemptId }` / `EmailVerifyRequest { email, code } \| { token }` / `CustomTokenResponse { customToken, isNew }`, `LinkByEmailRequest`; отказы (`email_code_invalid`, `email_attempt_expired`, `email_rate_limited`, `email_in_use`); `ProfileResponse` — `emailVerified`; комментарии про телефон-ключ | — |
| 4 | `aura-bff` (`…-bff-email-sign-in`) | попытки почты (код + ссылка), Resend (env, шаблоны на 24 языках), Redis-лимиты, Admin `createCustomToken` / `getUserByEmail` / `createUser` / `updateUser`, привязка почты из профиля | 3 |
| 5 | `aura-bff` (`…-bff-identity-email`) | guard и WS: `email` / `email_verified` / `sign_in_provider`; upsert подтверждённой почты; `link-by-email` (если нужен после проверки на web-dev); `--email` в CLI удаления | 3 |
| 6 | `aura-web` (`…-web-sign-in-providers`) | синхронизировать хендофф в `.claude/design_handoff_aura_web`; nginx-прокси `/__/auth/`, CSP, `authDomain`; `popupRedirectResolver`; Google / Apple / Facebook (popup / redirect); распознавание webview и ряд кнопок; интерстишел + привязка после SMS; строки на 24 языках | 1, 2 |
| 7 | `aura-web` (`…-web-email-sign-in`) | почта по умолчанию: «Continue with email» → «Check your inbox» (Open Gmail / Outlook, Enter code instead, повтор 0:48) → код; страница `/auth/email`; `signInWithCustomToken`; «Tell us who you are» с заблокированной «Verified» почтой | 4, 6 |
| 8 | `aura-web` (`…-web-sign-in-methods`) | `/me` → «Способы входа»: список, привязать / отвязать, «Добавьте номер для приложения» | 6, 7 |
| 9 | `aura-app` (позже, фича) | Google, Apple, почта, экран способов, интерстишел; Facebook на Android | 4, 5 |

Порядок: 1, 2, 3 параллельно → 4, 5 и 6 → 7 → 8. Задача 6 без 4 уже даёт Google / Apple /
Facebook. Проверка — только в маноре на web-dev (redirect, webview Instagram на реальном
телефоне, Safari с блокировкой кук, письмо в Gmail / Outlook с Safe Links).

## 11. Чек-листы консолей

### Firebase (`aura-2781b`)

- [ ] Authentication → Sign-in method: включить **Google**, **Apple**, **Facebook**. «Email/
      Password» и «Email link» **не** включать (почта идёт через custom token).
- [ ] Settings → User account linking: «Link accounts that use the same email» (по умолчанию).
- [ ] Authorized domains — `web-dev.aura-app.cc`, `web.aura-app.cc` уже есть.
- [ ] Сервис-аккаунт BFF — тот, что в `FIREBASE_CLIENT_EMAIL`, из проекта `aura-2781b` (нужен для
      `createCustomToken`; отдельной роли не требует, подпись локальная).
- [ ] Бюджет-алерт: добавить порог $10 рядом с $25 — первый реальный счёт за SMS придёт после
      ~2026-11-26.

### Google Cloud (OAuth)

- [ ] OAuth consent screen: имя «Aura», логотип, privacy и terms на `aura-app.cc`, authorized
      domain `aura-app.cc`; scopes `openid email profile` (не чувствительные — без проверки,
      кроме brand verification при логотипе); статус **In production**.
- [ ] Web client (создаётся Firebase при включении Google): Authorized JavaScript origins —
      `https://web-dev.aura-app.cc`, `https://web.aura-app.cc`; redirect URIs — `…/__/auth/handler`
      для каждого + `https://aura-2781b.firebaseapp.com/__/auth/handler`.

### Apple Developer

- [ ] Identifiers → **Services ID** (например `cc.aura-app.web`), включить Sign in with Apple,
      Primary App ID — iOS-приложение; Domains — `web-dev.aura-app.cc`, `web.aura-app.cc`,
      `aura-2781b.firebaseapp.com`; Return URLs — `…/__/auth/handler` для каждого.
- [ ] Keys → ключ с Sign in with Apple → Team ID, Key ID, `.p8` → в Firebase (провайдер Apple:
      Services ID, Team ID, Key ID, приватный ключ).
- [ ] Services → **Sign in with Apple for Email Communication**: зарегистрировать отправителей
      (`send.aura-app.cc` / адрес отправителя писем входа и Chatwoot) с SPF — иначе письма на
      `@privaterelay.appleid.com` не дойдут.
- [ ] Учесть: имя Apple отдаёт только при первом входе — шаг `name` его подхватывает или спрашивает.

### Meta (Facebook Login)

- [ ] Тот же Meta App `4422398391357112` (рекомендация, раздел 5): добавить продукт **Facebook
      Login**; Valid OAuth Redirect URIs — `…/__/auth/handler` для обоих доменов и firebaseapp.
- [ ] Права `public_profile`, `email`: проверить уровень доступа в App Review → Permissions — если
      стоит Standard, войти смогут только роли приложения; Advanced Access может потребовать
      **Business Verification** (Review → Verification).
- [ ] Basic: Privacy Policy URL, Terms URL, **User data deletion** (URL инструкции или callback),
      иконка, категория; App ID и App Secret → в Firebase (провайдер Facebook).
- [ ] Режим **Live** (в Development войти смогут только роли приложения).
- [ ] Учесть: у Facebook-аккаунтов, заведённых по номеру, почты нет — аккаунт Aura будет без почты.

### Resend

- [ ] Отправитель писем входа на `send.aura-app.cc` (домен уже подтверждён); лимит free — 100
      писем в сутки вместе с Chatwoot → Pro ($20/мес) до запуска рекламы на веб.

## 12. Вопросы владельцу

Решено 2026-10-23: модель B; почта — ссылка и код, выбор на экране (хендофф); оффер — как есть
+ метрика; ссылка впускает только свой браузер (A); код почты — 6 цифр; шаг имени без Skip,
выход — только закрытием окна; приложение — отдельной фичей.

Открыто:

1. Facebook — по рекомендации раздела 5 (первым во webview Meta, последним в обычных браузерах,
   в существующем Meta App)?

## Status

`Research`
