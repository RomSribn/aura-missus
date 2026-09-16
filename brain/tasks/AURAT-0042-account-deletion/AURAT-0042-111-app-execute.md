# AURAT-0042-111 — Часть A исполнена

Дата: 2026-09-16
Пишет: `aura-app-manor` / `slave-0`
Ветка: `feature/AURAT-0042-account-deletion` в `aura-app`, **не закоммичено,
застейджено** для просмотра в IDE.

## Проверка в слоте

`npx tsc --noEmit` — чисто. `npm run lint` — чисто. `jest` — **816 тестов,
117 наборов, все зелёные** (было 786 / 112). На устройстве не запускалось —
правило слота.

## Контракт

К началу исполнения половина BFF уже влита (`014-merge`, `aura-bff` `develop`
= `6698f1e`, деплой на `bff-dev`), а `@aura/contracts` **`v0.19.0`
опубликован** (`4d6a4ef`, тег в origin). Поэтому вызов написан сразу по
выпущенному контракту, а не отложен (как допускал порядок в `105`):
`package.json` → `#v0.19.0`, `AccountDeletionRefusalCode` и `ACCOUNT_DELETED`
импортируются из пакета.

## Что сделано

| Слой | Файлы | Что |
|---|---|---|
| `shared/api/bff` | `account-deleted.ts` (новый) | сигнал «аккаунт удалён»: `onAccountDeleted` / `reportAccountDeleted` |
| | `refusal-code.ts` (новый) | единый разбор `ApiError.code` из тела ошибки — раньше только в `upload.ts` |
| | `http-client.ts` | `bffRequest` несёт `code` отказа; `401 account_deleted` сообщается и **не** ретраится с обновлённым токеном |
| | `upload.ts` | то же для multipart |
| | `ws-client.ts` | закрытие сокета с reason `account_deleted` сообщается |
| | `attachment-cache.ts` | `clearAttachmentCache()` — снести `CacheDir/aura-attachments` |
| `shared/api/firebase` | `auth.service.ts` | `isIdentityGone()` через `currentUser.reload()` → `auth/user-not-found` |
| `shared/lib` | `navigation.ts` | `leaveApp` принимает всё, что умеет `reset` — экранный навигатор или container ref |
| `features/sign-out` (новый) | `model/sign-out-locally.ts` | общий локальный выход: `signOut` (если есть пользователь) + сброс `profileStore`/`horoscopeStore` + по флагу кеш вложений; безопасен при повторе |
| `features/account-deletion` (новый) | `api/account-api.ts`, `model/use-account-deletion.ts`, `lib/refusal.ts`, `config/copy.ts`, `ui/DeleteAccountSheet.tsx` | `DELETE /v1/me`; состояния `idle / deleting / live-sessions / failed`; один запрос на сколько угодно нажатий; `401` без кода + `isIdentityGone` = удалён; лист по образцу Cancel session |
| `screens/profile` | `model/types.ts`, `model/use-profile.ts`, `ui/ProfileScreen.tsx` | тихая строка **Delete account** под `Sign out`; лист; успех → выход с очисткой кеша → тост → вход; `409` → «Go to Sessions» — переход **после** закрытия листа; лист не закрывается, пока идёт запрос; `Sign out` переведён на `features/sign-out` |
| `app` | `providers/AccountDeletedBootstrap.tsx`, `index.tsx` | второе устройство: `onAccountDeleted` → локальный выход с очисткой кеша → тост → `leaveApp(navigationRef)`; несколько отказов разом — один выход |
| `screens/create-account` | `model/use-create-account.ts` | согласие на маркетинг **выключено** по умолчанию (`108` #11, отменяет `AURAT-0062` D3) |
| `screens/phone-auth` | `ui/PhoneAuthScreen.tsx` | «By continuing you confirm you are 18 or older and agree to our Terms of Use & Privacy Policy.» (`108` #14) |

Тесты: новые — `sign-out-locally`, `use-account-deletion`,
`DeleteAccountSheet`, `ProfileDeleteAccount` (экран целиком: строка → лист →
удаление → вход + тост; `409` → Sessions после dismiss модалки),
`AccountDeletedBootstrap` (через настоящий `bffRequest`); дополнены —
`http-client`, `upload`, `ws-client`, `attachment-cache`,
`CreateAccountScreen` (опт-ин выключен, включается только человеком).

## Решения по ходу

- **Слайс назван `features/sign-out`, а не `session-end`**, как в спеке:
  «session» в этом продукте — оплаченная консультация, имя путало бы.
- **`unregisterCurrentDevice` остаётся только в `Sign out`** — в
  `features/sign-out` его нет: фича не может импортировать другую фичу
  (`features/push`), а удалению он и не нужен.
- **`bffRequest` теперь несёт коды отказа для всех маршрутов.** Побочно это
  включило разбор `SendRefusalCode` для текстовых сообщений в
  `ChatProvider`: раньше код там читался только у сообщений с вложением.
  Поведение для текстовых отправок меняется ровно в том, что задумывалось
  контрактом.
- **Подпись «What we keep» выровнена с политикой**: «at least seven years»,
  как в брифе, а не «seven years» из черновика `105`.
- **Если локальный `signOut` падает после удалённого на сервере аккаунта**,
  экран всё равно уходит на вход: оставаться в аккаунте, который ничего не
  загружает, хуже; следующий запрос получит `401 account_deleted`, и
  `AccountDeletedBootstrap` повторит выход.

## Известное, в объём не входит

- **Копии исходящих файлов** (фото с камеры и из галереи, выбранные и
  вставленные файлы) лежат в кеше приложения вне `aura-attachments` и при
  удалении не чистятся (сверка `107`, раздел D). Отдельной строкой в
  `TECH-DEBT`, если владелец решит.
- **Кеш картинок RN** (аватар, фото советников) — на усмотрение платформы.
- **«Only your advisors see your name»** в Edit Profile — см. `108`.

## Проверка в маноре после мёржа (сборка `staging`, `bff-dev`)

1. Profile → Delete account → лист: текст, сумма баланса при ненулевом
   остатке.
2. Удаление тестового аккаунта с перепиской и вложением → экран входа, тост;
   вход тем же номером → Create Account, пустой профиль, опт-ин выключен.
3. Забронированная сессия → лист говорит про сессию → Go to Sessions.
4. Два телефона на одном аккаунте: удалить на первом → второй при первом же
   запросе (или переподключении чата) выходит на вход с тостом.
5. Экран входа показывает строку про 18+.

Дальше: просмотр владельцем в IDE → коммит → мёрж (гейт).
