# AURAT-0157-009 — execute

Дата: 2026-11-05. Слот slave-1, ветка `feature/AURAT-0157-app-i18n-shared-layer` (от `a2350f8`). Спека —
`007-spec-revised.md`, решения — `006`, `008`. Изменения **staged, не закоммичены** — ждут ревью владельца.

## Что сделано (aura-app, 182 файла: ≈ 120 — файлы языков)

1. **Общие фразы `shared`** — `goBack`, `tryAgain`, `ok`, `connection.comeBack`, `error.generic`, `day.today` /
   `day.tomorrow`, `auth.*` (12) во всех 24 языках. Память веба (`translate.mjs scan`) дала 27 из 43 строк
   пространства; остальное переведено здесь в регистре и форме кнопки глоссария, `check` — 0 запретных форм.
   - `BackButton` (`shared/ui/back-button`, 40 / 42 → стрелка 20 / 22) вместо 13 копий в 11 экранах;
     daily-card (своя кнопка) — тот же ключ; `EDIT_PROFILE_COPY.back` удалён.
   - Удалены `RETRY_LABEL`, `HOROSCOPE_RETRY_LABEL`, `RETRY`; «Try again» ×4 и «Check your connection…» ×3 —
     ключи `shared`; в `PayNotice` — также «OK» ×3.
   - `Alert.alert` без кнопок (profile «Sign out failed», session-detail «Session cancelled») — явная кнопка
     `t('ok')`.
2. **`SegmentedControl`** — `options: { value, label }[]` (`SegmentOption`), `numberOfLines={1}` +
   `adjustsFontSizeToFit` (`minimumFontScale` 0.8). Значения: advisors `all | online | topRated`, sessions
   `upcoming | past`, home `today | tomorrow`. Подписи — новые пространства `advisors` (`@max 14`) и `sessions`
   (`@max 22`), home — `shared` `day.*` (`@max 18`). Сегмент «All» у Advisors — мужской род (все консультанты),
   не женский, как у категорий веба.
3. **`AuthError(code, cause)`**, `message` = код. `authErrorKey(error)` (`shared/api/firebase/auth-error-key.ts`)
   — код → ключ `auth.*`, прочее → `error.generic`. phone-auth и verify-otp держат ключ и переводят при рендере;
   «Could not send a new code» (не AuthError) — пока английский литерал verify-otp (шаг 3).
4. **Пуши** — пространство `push`: каналы «Messages» / «Announcements», «Your advisor», тело **«New message»**
   (решение 2). `model/channels.ts`: создание каналов ждёт `i18nReady()`; `renameChannelsWithLanguage()` —
   подписка на `languageChanged`, подключена в `subscribeToForegroundAnnouncements` (Android). Константы имён и
   тела удалены из `config/constants.ts`.
5. **SMS** — `auth().setLanguageCode(currentLanguage())` перед `verifyPhoneNumber`, внутри промиса запроса:
   смена номера во время установки языка по-прежнему отменяет старый запрос (поколение проверяется), отказ
   `setLanguageCode` код не теряет. Тело запроса вынесено в `listen()`.
6. **Таб-бар** — `accessibilityLabel` пяти вкладок из пространства `app` (`src/app/config/locales`).
7. **Реестр** `app/i18n/namespaces.ts`: `shared`, `app`, `push`, `advisors`, `sessions`.
8. **Тесты**: новые — `BackButton`, `SegmentedControl`, `auth-error-key` (все коды), SMS-язык (порядок,
   отказ), push на de / pl и переименование каналов, таб-бар на en / de, сегменты Advisors на de (подпись и
   фильтр). Помощник `test-support/language.ts` (`switchLanguage`, `backToEnglish`). Обновлены: auth.service,
   filter-advisors, AdvisorsScreen, SessionDetailScreen (кнопка «OK»), message-notification («New message»),
   announcement-notification (канал создаётся после `i18nReady`). `SAME_AS_ENGLISH` + 37 заимствований («OK»,
   «Online», «Chats», «Home», fr «Messages») — вставлены в начало списка, строка `FORBIDDEN` (0156) не тронута.
   `jest.setup.js` — `setLanguageCode` в моке auth.

## Проверка в слоте

- `npx jest --no-watchman` — 171 / 171 наборов, 1521 / 1521 тестов.
- `npm run lint` — 0 / 0. `npx tsc --noEmit` — чисто.
- `translate.mjs check` по 5 пространствам — 0 запретных форм; советы — склонения (et «toega», hr «podršci»,
  ga «Do chomhairleoir») и формулировки веба (nl «klantenservice», pl «obsługą klienta»); ga
  `connection.comeBack` уже с «Seiceáil do cheangal» — совет ложный.
- Байты: нет U+00AD, ş/ţ, U+02BC, всё NFC. U+202F в fr `offer.*` — из `AURAT-0154`, не трогал.
- Prettier — только по своим строкам: в 19 файлах, которые и до задачи не проходили prettier, чужое форматирование
  не тронуто. `shared/index.ts` — строка экспорта шрифтов оставлена как была (её может менять 0156).

## Открыто / в манор

- Проверка на устройстве (dev-меню «i18n: next language», de / fi / pl / el / псевдо): «назад» и таб-бар в
  TalkBack/VoiceOver, сегменты без обрезки (fi «Parhaat», es «Más valorados», nl «Top beoordeeld» 14 символов),
  ошибка кода, пуш «New message» в фоне (Android) и имя канала после смены языка, SMS на реальный номер.
- Тексты алертов, «Could not send a new code», остальные строки экранов — шаг 3.
