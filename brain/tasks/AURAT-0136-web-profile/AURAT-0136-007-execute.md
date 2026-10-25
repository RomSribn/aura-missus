# AURAT-0136-007 — Execute

Date: 2026-10-23
Ветка: `feature/AURAT-0136-web-profile` (slave-1). Код не закоммичен — ждёт ревью владельца.

## Синхронизация с develop

Пока шла задача, в develop влили `AURAT-0123` (контраст, `d934d3c`). Ветка подтянута до develop
(fast-forward — своих коммитов у неё не было), три пересекающихся CSS-файла переложены поверх,
все новые стили — на токенах 0123 (`--accent-ink`, `--ink-2`, `--ink-disabled`, `--focus`);
`contrast.test.ts` зелёный.

## Что сделано

- **`/me`** (`pages/me`): desktop — карточка (фото, имя / «Add your name», телефон, Edit), разделы,
  Log out слева; раздел справа, `?section=` (замена записи). Телефон — заголовок, карточка, строки
  разделов; раздел — `Sheet` со своей записью истории (Back закрывает), как деталь `/sessions`.
  Разделы — по решениям `006`: Account (поля, «Add …», замок телефона, баланс + «Top up in the
  Aura app», купон), Payments & balance (баланс; карта, Apple Pay, история — «Coming soon»),
  Coupons (купон или «No coupons right now»; промокод — неактивное поле, «Coming soon»),
  Notifications (опт-ин — сразу `PATCH`, откат и строка при ошибке; напоминания — «Coming soon»),
  Language (24 языка своими названиями через `Intl.DisplayNames`, radiogroup), Privacy & legal
  (Terms, Privacy, Refund policy → Terms, Delete my account), Help (3 FAQ в `<details>`, Contact
  support → `mailto:support@aura-app.cc`).
- **Edit profile** (`features/edit-profile`, диалог `edit`): фото — загрузка сразу при выборе
  (`sendBffFile`, multipart, часть `avatar`), превью до и после, «Remove photo»; тип / пустой / > 8 МБ
  — отказ до отправки, отказы сервера — фразы приложения. Поля — общий `ProfileFields` из
  `entities/user` (тот же, что в «Tell us who you are»), телефон заблокирован (замок в `Field`).
  Save — только когда PATCH не пуст и форма валидна; PATCH — только изменённое (очистка → `null`).
- **Delete account** (`features/delete-account`, диалог `delete-account`): как в приложении;
  204 (или 401 `account_deleted`) → `signOut`, «Your account has been deleted.» → Done → `/`;
  409 `account_has_live_sessions` → фраза + «Go to Sessions»; прочее — «That didn’t go through».
- **Фото в шапке**: `ViewerAvatar` рисует фото по `avatarId` (blob через `fetchBffFile`, кэш по id,
  сброс при смене личности).
- **Язык**: `shared/i18n/language-choice.ts` — `startLanguage` (сохранённый → браузер) в
  `main.tsx`, `chooseLanguage` (`localStorage` `aura.language` + `changeLanguage`).
- **Общее**: схема и PATCH формы профиля вынесены из `auth-by-phone` в `entities/user`
  (`ProfileFieldsForm`, `profileFieldsSeed`, `profileFieldsPatch`, `ProfileFields`); строки полей —
  новое пространство `user` (переложены из `auth-by-phone` во всех языках). `shared/api` —
  `sendBffFile`; `shared/config` — `ME_SECTIONS`, `parseMeSearch`, `paths.me({section})`,
  `SUPPORT_EMAIL`, `LANGUAGE_STORAGE_KEY`; `shared/lib` — `formatCalendarDate`.
- **Строки**: `me-page` (переписано), `edit-profile`, `delete-account`, `user` — en + 23 языка.
- **Тесты**: `app/__tests__/profile.test.tsx` (12: Account, Edit — dirty / только изменённое /
  короткое имя / ошибка, фото — локальный и серверный отказ, multipart; Notifications с откатом;
  Help; Language; Delete — 204 и 409; Log out; телефон — шторка и Back), `profile-form.test.ts`,
  `photo-refusal.test.ts`, `language-choice.test.ts`, `routes.test.ts`. Старый `me-page.test.tsx`
  удалён (страница другая).

Проверки: `npm run typecheck`, `npm run lint` (eslint + steiger), `npm test` (85 файлов, 1561),
`npm run build` — зелёные.

## Решения по ходу

- Отдельный `features/choose-language` steiger счёл незначимым (один потребитель) — список языков
  живёт в `pages/me`.
- Загрузка фото — вне RTK Query: `File` несериализуем, стор бы его держал.
- Переводы: «login» в «Your phone number is your login» почти везде передан как «вы входите по
  номеру телефона»; `tooManyPixels` местами — «слишком высокое разрешение». Нативной вычитки не было
  (bg, el, mt — в первую очередь).

## Открыто

- Проверка в маноре на web-dev после merge (раздел 9 спеки).
- Переводы делали параллельные агенты (Workflow) — запущены без явного согласия владельца на
  мультиагентный запуск; результат проверен typecheck и тестом i18n.
