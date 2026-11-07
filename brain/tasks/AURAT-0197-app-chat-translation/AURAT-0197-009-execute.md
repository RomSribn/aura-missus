# AURAT-0197-009 — execute

Дата: 2026-11-08 · slave-3, `feature/AURAT-0197-app-chat-translation` (от `develop` `92c9694`). Всё застейджено,
**коммитов нет**. Спека — `005` + `007-spec-v2`, решения 1–3 = А (`008`).

## Проверки (в слоте)
- `npm run lint` (`--max-warnings 0`) — чисто.
- `npx tsc --noEmit` — чисто (скрипта `typecheck` в `package.json` нет; это тот же `tsc`).
- `npx jest --no-watchman` — **243 набора, 3265 тестов, все зелёные** (в том числе тест namespace'ов,
  `@max`, глоссарий, `SAME_AS_ENGLISH`, шрифты).
- `translate.mjs check` по `chat-settings` и `chat-thread` — **0 запрещённых форм**; советы — ложные: слово
  «language» в имени переменной `{{language}}` и падежные формы («jazyce», «phróifíl»).
- `translate.mjs review` — `chat-settings` (5 строк × 23 языка, `@sensitive legal`) в списке на вычитку носителем;
  записей в `native-review.json` нет (их добавляют после вычитки).

## Что сделано
- **Контракты** `#v0.31.0` (`package.json`, `package-lock.json` — только эта зависимость).
- **`shared/api/bff`**: опция `language: false` у `bffRequest` и `bffUpload`, по умолчанию `?lang` как прежде.
- **`features/chat`**:
  - `ChatMessage.translation` (тип контракта), `mapMessage` несёт его только у советника;
  - новый `lib/translation.ts`: `translationOf` (none / pending / translated / failed / elsewhere), `shownTextOf`,
    монотонный `mergeTranslation` (`007`), `applyTranslations`, `translatedFromOf`;
  - `previewOf(message, language)` и `MessagePreview` (`useLanguage`);
  - `chat-api`: отправка JSON и multipart передаёт `language: I18N_ENABLED`; `fetchHistory` принимает `translatedFrom`;
  - `ChatProvider`: WS `message.translated`; у уже известного сообщения из `message.new`, синка или ответа
    перевод обновляется, а не пропускается; догонка `translatedFrom` + `translations` с раундами
    (`TRANSLATIONS_PAGE = 200`, `TRANSLATION_ROUNDS_MAX = 5`, проверка поколения); `refreshSpreads` тоже обновляет
    переводы по прочитанной странице.
- **`screens/chat-thread`**: `TranslationNote` (подпись + кнопка в мета-строке пузыря советника), `MessageBubble`
  показывает текст по правилу; набор «перевёрнутых» id — в `use-chat-thread`; карточка согласия над полем, отправка
  (кнопка и `onSubmitEditing`) выключена, пока согласие не сохранено.
- **`entities/user`**: `Profile.chat`, `patchChatSettings` (`PATCH /v1/me/chat-settings`),
  `profileStore.saveChatSettings` (бросает `BffApiError`, публикует ответ).
- **`features/chat-settings`** (новая): `useChatConsent` (400/404 → галочка уходит до перезапуска, сеть → «не
  удалось»), `useTranslationSwitch` (виден только при согласии текущей версии, оптимистично; 409 → перечитать
  профиль), `ChatConsentCard` (`accessibilityRole="checkbox"`), `lib/settings-failure.ts`, `config/constants.ts`.
- **`screens/profile`**: вид строки `toggle` в `ProfileMenu` (подпись + пояснение + `Toggle`, вся строка —
  `switch`), строка «Translate my chat» после Language.
- **`features/app-language`**: `ownName` в публичном API (название языка в подписи «Перевод · Deutsch»).
- **Строки**: `chat-thread.translation.*` (8 ключей) и новый namespace `chat-settings` (текст согласия — по
  `AURAI-0012-legal.md`, `@sensitive legal` на весь namespace) — 24 языка, регистр и форма кнопок — по глоссарию;
  namespace добавлен в `app/i18n/namespaces.ts`.
- **Тесты** (новые): `translation.test.ts`, `ChatProvider.translation.test.tsx` (в том числе гонка «событие
  раньше истории»), `send-language.test.ts`, `profile-store-chat.test.ts`, `use-chat-consent.test.tsx`,
  `use-translation-switch.test.tsx`, `MessageBubble.translation.test.tsx`, `ChatThreadScreen.consent.test.tsx`,
  `ProfileTranslationSwitch.test.tsx`; дополнены `map-message`, `preview`, `chat-api`, `profile-api`,
  `http-client`, `upload`; `test-support/profile` — `chat` в `seedProfile`.

## Решения по ходу
- Подпись «другого языка» с кнопкой: «Перевод · Français · Показать», после нажатия — «Переведено ИИ · Показать
  оригинал» (метка ИИ — всегда рядом с машинным текстом).
- `@max` у `translation.elsewhere` поднят до 16: шведское «Översättning · » — 15 знаков.
- В профиле переключатель внутри строки скрыт от экранного диктора; строка сама — `switch` с `checked`.
- `prettier` трогает в репозитории и чужие файлы — они откачены, в диффе только строки задачи.

## Открытое
- Событие `message.translated` для сообщения, которого тред ещё не держит, отбрасывается: сообщение придёт с
  синком в текущем состоянии сервера, а потерянное событие догонит следующий `translatedFrom`. На одном сокете
  `message.new` всегда приходит раньше — отдельного буфера не делал.
- Вычитка носителем текста согласия — до маркетинга в стране (`AURAI-0010`, решение 7).
- iOS: нативного кода нет; отправка без `?lang` (флаг выключен), галочка и переключатель есть — проверка в конце
  (§9 п. 10 `005`).

## Проверка в маноре
По `005` §9: A — сразу после мёржа на текущем BFF (`npm ci` в маноре — контракты v0.31.0), B — после
`AURAT-0196`, C — после конвейера.
