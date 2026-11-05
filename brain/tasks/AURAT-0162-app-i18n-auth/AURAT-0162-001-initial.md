# AURAT-0162-001 — initial

Дата: 2026-11-05. Выдана по просьбе владельца: «продолжим по переводам», выбор — «entities + вход». Запуск — slave-1
(`wts-run`), от `develop` @ `307bb14`.

Шаг 3 фичи `AURAF-0023` — перенос строк. Это задача «вход (+ названия стран)» из плана `AURAI-0010` § Recommendation,
п. 3. Основа уже в develop: i18n, глоссарий, шрифты, shared-слой, форматтеры CLDR, лист языка (`AURAT-0154`…`0159`).

Что входит; границы уточнить в спеке:
- **Экраны входа:** `screens/phone-auth`, `screens/verify-otp`, `screens/onboarding-slider`, `screens/splash` (если там
  есть текст). `screens/create-account` — решить в спеке, сюда или в «профиль и аккаунт».
- **Названия стран** в выборе кода телефона (`CountryPickerSheet`) — на языке интерфейса, поиск без учёта диакритики
  (`AURAF-0023-005`). На Hermes нет `Intl.DisplayNames`: таблицы статические, сгенерированные из CLDR (как таблицы
  `0159` и автонимы `0158`). 245 названий × 24 языка — подумать о размере бандла и загрузке только активного языка.
- **Склейки из фрагментов** (`AURAI-0010-evidence.json`):
  - юридическая строка «By continuing … agree to our Terms of Use & Privacy Policy» → `<Trans>` со ссылками-компонентами
    и `@sensitive legal`;
  - «Sent to {phone} · change»;
  - «Resend code in {time}».
- **Ошибки входа** — `AuthError` по коду (`0157`): проверить, что все коды переведены.
- **Вёрстка горячих мест** входа (длинные языки: de, fi, hu, el), проверка псевдоязыком.

Лист выбора страны — общий `BottomSheet` с `scrollable`. Тяга со списком исправлена в `AURAT-0158`
(`develop` @ `307bb14`), здесь её не трогать.

Правила — раздел «Translations» в `.claude/aura-build-rules.md`:
- все 24 языка в этой же задаче;
- глоссарий: `translate.mjs scan … --web <aura-web>`, на вебе уже есть переводы стран и входа;
- `@max`, `@sensitive`;
- `i18next/no-literal-string` на `error` для перенесённых путей.

Параллельно в slave-0 идёт `AURAT-0161` (entities). Общие файлы (`app/i18n/namespaces.ts`, `.eslintrc.js`) трогают обе
задачи — конфликт решается при мёрже второй.
