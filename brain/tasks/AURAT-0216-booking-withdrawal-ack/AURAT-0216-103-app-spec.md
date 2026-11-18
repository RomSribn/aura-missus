# AURAT-0216-103 — Приложение: спека

Дата: 2026-11-18 · Status: **draft — ждёт одобрения владельца**. Тип: задача, без новой фичи.
Скоуп — `004`–`006` (кнопки — `002` п. 2), решение `AURAD-0024`, контракт `@aura/contracts` v0.35.0
(`consent.ts`). Контекст — `102`. Это не юридическая консультация.

## Что увидит человек

| Поверхность | Над кнопкой (новое) | Кнопка с баланса |
|---|---|---|
| Review, слот | строка отмены + ссылка → пустая галочка `booking-v1` | «Confirm & pay {{amount}}» (без изменений) |
| Review, «сейчас» | «The session starts as soon as it's paid.» (есть) + ссылка → галочка `now-v1` | «Confirm & pay {{amount}}» |
| Быстрая бронь в чате, слот | строка отмены + ссылка → галочка `booking-v1` | «Book · $9» → **«Pay {{amount}} & book»** |
| Быстрая бронь, «сейчас» | ссылка → галочка `now-v1` | «Start now · $9» → **«Pay {{amount}} & start now»** |
| Продление | строка `sheet.note` (есть) + ссылка → галочка `extension-v1` | «Extend · $9» → **«Pay {{amount}} & extend»** |

- Галочка всегда пустая при открытии. Пока она не отмечена, кнопка оплаты неактивна: и с баланса, и
  через стор (через стор деньги уходят в стор раньше брони). «Top up to book / extend» не платит за
  сессию и остаётся активной.
- Галочка снимается сама, когда меняется её текст. Так бывает в быстрой брони: «сейчас» пропало и
  шторка предлагает слот. Снимается и при каждом новом открытии шторки, то есть у каждого продления
  своя галочка.
- Кнопки стора («Pay {{price}} & book / start now / extend») уже с «pay» и не меняются. Пилюля
  «Extend +N min» в шапке только открывает шторку и тоже не меняется.

### Тексты (английский; 24 языка, `@sensitive`)

- Галочки — дословно `SESSION_CONSENT_TEXTS` контрактов (`booking-v1`, `now-v1`, `extension-v1`).
- Строка отмены (`004` п. 2) — на Review **заменяет** нынешний `review.policy`: в нём нет половины
  после 24 ч. В быстрой брони это новая строка: «Free cancellation up to 24 hours before the start;
  after that, half the cost is kept. Rescheduling is free until 4 hours before.»
- Ссылка — **одна**: «Cancellation and withdrawal terms» → `https://aura-app.cc/terms/#s07`
  (`005`). Условия отмены уже написаны строкой выше, а §07 говорит о праве отказа и сам отсылает к
  §06. Две ссылки рядом с кнопкой — лишний шум. Ссылка стоит под всеми тремя галочками: §07 касается
  и «сейчас», и продления.
- Шторка удаления, `keptBody`: «Records of purchases and paid sessions are kept for at least seven
  years, as the law requires, without your name or phone number.» (`006`).
- Переводы — по правилам сборки: glossary, регистр, `translate.mjs scan --web`, `@max` для кнопок.
  Веб строк ещё не переводил, поэтому переводим первыми и **передаём вебу** (`aura-web-manor`
  slave-2) путь к нашим файлам.

## Что уходит на сервер

`consent: { version, language }` — **только** при отмеченной галочке. С этой сборки она отмечена при
каждом нажатии, иначе кнопка неактивна.
- `version` — тип из контрактов. Значение — литерал версии, *чей перевод показан*:
  `'booking-v1' satisfies (typeof BOOKING_CONSENT_VERSIONS)[number]`. Брать «последнюю из массива»
  нельзя: после выхода `booking-v2` в контрактах приложение слало бы v2 с переводом v1.
- `language` — язык показанного текста (`useLanguage()`, то есть `resolvedLanguage`). На iOS до
  `AURAT-0190` это `en`. Псевдоязык dev-сборок уходит как `en`.
- Повтор с тем же ключом после неизвестного исхода шлёт то же поле (сервер его не сравнивает).
- 400 `consent_invalid` / `consent_required` брони сейчас показывается как «время недоступно». Будет
  — «не получилось, попробуйте ещё раз» (`failed`), ключ сгорает. У продления 400 уже даёт `failed`.

## Код (FSD)

- **Новый срез `features/session-consent`** — галочка и строки перед оплатой сессии:
  - `ui/SessionConsentBox` — карточка-галочка по образцу `ChatConsentCard`, коралловая (это оплата):
    вся карточка — `checkbox`, рядом ссылка;
  - `ui/CancellationTerms` — строка отмены;
  - `model/use-session-consent(kind, resetKey)` — `{ ticked, toggle, consent }`; `consent` равен
    `SessionConsent | null`, сброс — при смене `kind` или `resetKey` (открытие шторки);
  - `config/versions.ts` — `kind → версия` (литералы, проверенные типами контрактов);
  - `config/locales` — namespace `session-consent`: тексты галочек ключами версий
    (`box.booking-v1` …), строка отмены, ссылка. Регистрация — в `app/i18n/namespaces.ts`.
- `features/booking/use-booking-confirm` — опция `consent` уходит в тело `bookSession`; ответ 400 с
  кодом согласия даёт `failed`.
- `features/paid-session/use-paid-session` — `charge(consent)` уходит в `extendSession`.
- `features/store-topup/use-checkout` — новая опция `held` (галочка не отмечена): кнопка неактивна,
  `pay()` ничего не делает. Срез не знает, *почему* кнопка держится.
- Экраны собирают всё вместе (features друг друга не импортируют):
  - `screens/booking/use-book-review` + `BookReviewScreen` — футер: строка отмены, ссылка, галочка,
    кнопка;
  - `screens/chat-thread/use-quick-book` / `use-extend-checkout` + `ChatThreadScreen` — галочка в
    слоте `action` шторок, строка отмены в быструю бронь (тоже слот `payment` / `action`);
  - кнопки — `chat-thread:quickBook.book / startNow`, `extend.cta`: тексты с «Pay», плейсхолдер
    `{{amount}}`. Переводы берутся из готовых `store-topup:cta.store.*` с той же английской
    формулировкой.
- `account-deletion` — `keptBody` в 24 языках.
- Контракты: `package.json` → `#v0.35.0`, `npm install`, lockfile.

## Тесты

- **Закреплённые переводы** (`session-consent/config/locales/__tests__/pinned.test.ts`):
  `en` каждой версии совпадает с `SESSION_CONSENT_TEXTS`. Для каждой версии × 24 языка хранится
  sha-256 (16 hex) текста. Любая правка перевода без новой версии роняет тест с подсказкой «новый
  текст — новая версия в контрактах». Набор версий в тесте совпадает с ключами `box.*`.
- `use-session-consent`: пусто при старте, `consent` — `null` → `{version, language}`; сброс при
  смене `kind` / `resetKey`.
- `use-booking-confirm`: `consent` в теле при отметке и отсутствует без неё; 400 `consent_invalid` →
  `failed`.
- `use-paid-session`: `consent` в теле продления.
- `use-checkout`: `held` → кнопка неактивна, `pay` не вызывает ни стор, ни `charge`.
- UI: Review / быстрая бронь / продление — кнопка неактивна до отметки, отметка её включает, повторное
  открытие шторки снова пустое; «сейчас» → слот снимает галочку; ссылка открывает `#s07`.
- Обычный набор: `typecheck`, `lint` (`--max-warnings 0`, строки без перевода), steiger, `jest`
  (переводы, glossary, `@max`, шрифты).

## Вне задачи

- Перенос брони (`PATCH`) — без галочки (BFF, решение 8).
- Android-релиз — отдельно, с владельцем (`aura-release`).
- Живая проверка — в маноре после мёржа, на bff-dev с BFF-частью: запись согласия у брони,
  «сейчас» и продления.

## Решения владельца

1. **Ссылка одна** — «Cancellation and withdrawal terms» → `#s07`, под каждой галочкой. Рекомендую.
   Иначе — две ссылки (§06 и §07) у брони.
2. **Строка отмены на Review заменяет нынешнюю** (в нынешней нет «половины после 24 ч»). Рекомендую.
3. **Кнопки быстрой брони тоже с «Pay»** («Pay {{amount}} & book», «Pay {{amount}} & start now»),
   хотя в таблице `002` их не было: та же ст. 8(2). Рекомендую.
