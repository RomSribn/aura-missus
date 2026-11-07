# AURAT-0197-005 — spec: перевод чата в приложении (`AURAF-0024`, задача 7 `AURAI-0012`)

Дата: 2026-11-07 · Статус: **draft — ждёт ревью координатора и одобрения владельца** · slave-3,
`feature/AURAT-0197-app-chat-translation` от `develop` `92c9694`. Факты — `004-context.md`.
Тип: задача (фича — `AURAF-0024`, при закрытии туда строки приложения).

## Что получится

Когда сервер начнёт переводить (после `AURAT-0196` и конвейера), человек в приложении:

1. видит ответ советника на языке интерфейса с подписью «Переведено ИИ · Показать оригинал»;
2. видит английский с «Переводится…», пока перевод в пути, и перевод сам встаёт на место (событие или догонка);
3. видит тот же перевод в превью Home («Continue your chat») и в списке Chats;
4. перед первым сообщением ставит галочку согласия (текст `AURAI-0012-legal.md`);
5. в профиле может выключить и включить «Переводить мой чат».

Пока сервер этого не умеет (нет `ProfileResponse.chat`, нет `Message.translation`), приложение выглядит и работает
как сегодня — это проверяется тестами и в маноре на текущем BFF.

## 1. Контракты

`npm install "@aura/contracts@github:RomSribn/aura-contracts#v0.31.0"` — `package.json` и `package-lock.json`.
Только добавления, старый BFF разбирается новой сборкой (проверено в `AURAT-0195` §6).

## 2. Перевод в сообщении — `features/chat`

- `ChatMessage.translation?: MessageTranslation` — тип контракта, не копия. `mapMessage` несёт его только у
  `direction: 'advisor'` (у человека и `system` сервер его не шлёт; если пришлёт — отбрасываем).
- Новый `lib/translation.ts` — одно правило на всё приложение, чистая функция:

  ```ts
  type TranslationView =
    | { kind: 'none' }                                   // поля нет — как сегодня
    | { kind: 'pending' }                                // английский + «Переводится…»
    | { kind: 'translated'; content: string }            // перевод на языке интерфейса
    | { kind: 'failed' }                                 // английский + «Не переведено»
    | { kind: 'elsewhere'; language: string; content: string }; // перевод на другом языке (решение 2)
  translationOf(message: ChatMessage, language: Language): TranslationView
  ```

  - `translated` и `translation.language === language` на экране → `translated`;
  - `translated` на другом языке → `elsewhere`; язык, которого нет в `LANGUAGES`, — `failed` (показать нечего
    по-человечески назвать);
  - `failed` → `failed`, `pending` → `pending`, нет поля → `none`;
  - псевдоязык dev-меню — как английский интерфейс: перевода нет.
- Смена языка интерфейса ничего не перечитывает: правило применяется при рендере, перевод на `de` после
  переключения на `de` сразу становится `translated`, после переключения на `fr` — `elsewhere`.
- **Превью** — `previewOf(message, language)`: текст и подпись вложения берутся из `translationOf` (`translated` →
  перевод, иначе `content`). `MessagePreview` берёт язык через `useLanguage()` — перерисуется при смене языка.
  Подписи «Переведено» в превью нет — одна строка, места нет.

## 3. Пузырь — `screens/chat-thread`

Мета-строка пузыря советника (сейчас — только время, 10 pt, `ink3`):

```
┌──────────────────────────────────────────┐
│ Die Karten zeigen einen neuen Anfang …   │   translated
│ Von KI übersetzt · Original anzeigen 12:04│
└──────────────────────────────────────────┘
│ The cards show a new beginning …         │   translated, показан оригинал
│ Original · Übersetzung anzeigen     12:04│
│ The cards show a new beginning …         │   pending
│ Wird übersetzt …                    12:04│
│ The cards show a new beginning …         │   failed
│ Nicht übersetzt                     12:04│
│ The cards show a new beginning …         │   elsewhere (решение 2, А)
│ Übersetzung · Français · Anzeigen   12:04│
```

- «Показать оригинал / перевод» — кнопка (`accessibilityRole="button"`), только на `translated` и `elsewhere`.
  Состояние — набор id «показан оригинал / показан другой язык» в `use-chat-thread` (экранная модель, ui
  остаётся рендером), строка получает `showingOriginal: boolean` и стабильный `onToggleTranslation` — `React.memo`
  перерисовывает только нажатую строку. Набор живёт, пока открыт экран.
- Экранный диктор читает показанный текст и подпись; у кнопки — `accessibilityLabel` по состоянию.
- Сообщения человека, маркеры, расклады и приглашения — без изменений (перевода у них нет по контракту).
- Название языка в `elsewhere` — своё имя языка (`Français`), стоит отдельно от фразы (правило «имя не в
  падежном слоте»): `ownName` из `features/app-language` выносится в публичный API фичи.

## 4. Событие и догонка — `ChatProvider`

- **`message.translated`** → `applyTranslations(advisorId, [{ messageId, translation }])`: заменяет `translation`
  сообщения с этим id, если оно в треде и это сообщение советника; иначе ничего (придёт с историей). Порядок событий
  не важен.
- **Известное сообщение с новым переводом.** `mergeServerMessages` сейчас пропускает известные id; теперь для
  известного сообщения советника, у которого во входящем DTO `translation` другой, перевод заменяется (`message.new`,
  повторный синк, ответ отправки). Остальные поля известного сообщения по-прежнему не трогаются.
- **Догонка `translatedFrom`.** `readThread` добавляет `translatedFrom` = id самого старого серверного сообщения
  советника в треде с переводом `pending` или `failed` (по JSDoc контракта). Нет такого — параметра нет.
  `page.translations` применяется тем же `applyTranslations`, после `merge`. Полный список (`≥ TRANSLATIONS_PAGE`,
  `= DELETED_IDS_PAGE`, 200 — «предел как у `deletedIds`») — ещё раунд с `translatedFrom` = последний `messageId`,
  не больше `TRANSLATION_ROUNDS_MAX = 5`, как раунды удалений, с той же проверкой поколения (`movedOn`).
  `translations` нет (старый BFF) — ничего.
- Догонка идёт всегда, когда синк уже идёт: возврат в foreground, переподключение сокета, FCM-пинг, открытие
  треда. Отдельных запросов не добавляется.
- Подгрузка старых страниц (`loadOlder`) и `refreshSpreads` переводы приносят в составе сообщений — `mapMessage`
  их несёт; известным сообщениям `refreshSpreads` переводы тоже обновляет (тот же `applyTranslations` по странице).
- Непрочитанные (`AURAT-0176`) перевод не трогает: это не новое сообщение.

## 5. Отправка без `?lang` при выключенном выборе языка

- `bffRequest(path, { …, language: false })` и `bffUpload({ …, language: false })` — новая опция, по умолчанию
  `true` (всё остальное как сегодня).
- `sendMessage` / `sendMessageWithAttachment` (и повтор) передают `language: I18N_ENABLED`. С флагом выключенным —
  iOS до `AURAT-0190`, коммитнутые dev-цели — отправка без `?lang`: язык чата на сервере не меняется. С флагом
  (Android release / staging) — язык на экране, как сегодня.
- Флаг, а не `LANGUAGE_CHOICE_AVAILABLE` (флаг или `__DEV__`): язык из dev-меню при выключенном флаге — предпросмотр,
  он не должен писать язык чата аккаунта. Проверять перевод на dev-сборке — с `.local`, где флаг включён.
- Тесты: JSON и multipart без `lang` при выключенном флаге, с `lang` при включённом; история, профиль и прочие
  запросы — с `lang` всегда.

## 6. Настройки чата — `entities/user` + новая фича `features/chat-settings`

**`entities/user`** (единственный владелец профиля):
- `Profile.chat?: ChatSettings` — тип контракта; `toProfile` его несёт; нет поля — `undefined`.
- `profileStore.saveChatSettings(patch: ChatSettingsPatchRequest)` → `PATCH /v1/me/chat-settings` → `publish` ответа.
  Бросает `BffApiError` (как `uploadAvatar`): вызывающему нужно различить `409`, `400`, `404` и сбой сети.

**`features/chat-settings`** (`model/`, `ui/`, `config/locales` — namespace `chat-settings`):
- `useChatConsent()` → `{ required, giving, failed, give() }`.
  - `required` — профиль загружен, `chat` есть, и `consent` нет или `consent.version < CHAT_CONSENT_VERSION`.
    Профиль не загружен, `unavailable`, `chat` нет — `false`: чат не блокируется ничем.
  - `give()` → `saveChatSettings({ consentVersion: CHAT_CONSENT_VERSION })`. Успех — профиль с согласием, галочка
    уходит. `400` (сервер на старой версии контрактов) или `404` — галочка уходит до конца сеанса, чат не
    блокируется, перевод остаётся выключенным (JSDoc `CHAT_CONSENT_VERSION`). Сеть / 5xx — `failed`, галочка снята,
    строка «Не удалось сохранить. Попробуй ещё раз».
- `ChatConsentCard` — карточка над полем ввода: квадратная галочка 22 pt (иконка `check`, teal — коммуникация),
  текст согласия 13 pt `ink2`, вся карточка — одна кнопка `accessibilityRole="checkbox"` с
  `accessibilityState={{ checked, busy }}`. Пока идёт запрос — галочка отмечена и неактивна.
- `useTranslationSwitch()` → `{ visible, on, pending, failed, set(on) }`.
  - `visible` — `chat` есть и согласие текущей версии есть (решение 3).
  - `set(on)` → `saveChatSettings({ translationEnabled: on })`, оптимистично; ошибка — переключатель
    возвращается, строка ошибки под ним. `409 chat_consent_required` — профиль перечитывается (согласие устарело,
    переключатель скроется, в чате снова галочка).
- Чекбокс — в фиче, не в `shared/ui`: один потребитель (правило 3 — при втором вынести).

**Где это на экранах:**
- `screens/chat-thread`: при `required` — `ChatConsentCard` между `DraftAttachmentBar` и `ChatInputBar`;
  отправка (кнопка и `onSubmitEditing`) выключена, пока галочка не сохранена (решение 1). Набирать текст и
  прикреплять файл можно — черновик не теряется.
- `screens/profile`: строка-переключатель «Переводить мой чат» в `ProfileMenu` после «Language» — новый вид строки
  (`switch`): иконка, подпись, под ней мелко «Ответы советников на твоём языке, перевод ИИ», справа `Toggle` вместо
  стрелки. Строка — не кнопка-переход: нажатие по строке переключает.

## 7. Строки (24 языка, правила «Translations»)

- `chat-thread` (существующий namespace): `translation.byAi` «Translated by AI», `translation.showOriginal`,
  `translation.showTranslation`, `translation.original` «Original», `translation.pending` «Translating…»,
  `translation.failed` «Not translated», `translation.elsewhere` «Translation · {{language}}», `translation.show`
  «Show», плюс `accessibilityLabel` кнопок. Все `@max` — мета-строка пузыря (76 % ширины, 10 pt): ≈ 26 символов на
  подпись + кнопку.
- `chat-settings` (новый namespace, в `app/i18n/namespaces.ts`):
  - `consent.text` — дословно `AURAI-0012-legal.md` (решение 6), `@sensitive legal`; вычитка носителем — до
    маркетинга в стране (`AURAI-0010`, решение владельца 7), запись в `scripts/i18n/native-review.json`;
  - `consent.failed`, `consent.label` (диктор);
  - `switch.label` «Translate my chat», `switch.hint`, `switch.failed` — `@sensitive legal` (это отзыв согласия);
- Регистр и форма кнопок — по глоссарию (`scripts/i18n/glossary.json`), `translate.mjs check`. У веба этих строк
  ещё нет (задача 8 — после Android) — переводы пишутся здесь, веб берёт их отсюда.
- «AI» / «ИИ» — по глоссарию; Anthropic и USA не переводятся (имя собственное, страна — по-своему в каждом языке).

## 8. Тесты (Jest, в слоте)

- `map-message`: перевод у советника несётся, у человека и `system` — нет.
- `translation.ts`: все пять видов, язык вне `LANGUAGES`, псевдоязык.
- `preview`: перевод в превью текста и подписи вложения; английский при `pending` / `failed` / другом языке.
- `ChatProvider`: `message.translated` заменяет перевод; незнакомый id и сообщение человека — ничего; повторный
  `message.new` известного сообщения обновляет перевод; `translatedFrom` = самое старое `pending|failed`; без них
  параметра нет; `translations` применяются; раунды при полном списке и предел; старый ответ без `translations`.
- `http-client` / `upload` / `chat-api`: `?lang` на отправке по флагу, на остальном — всегда.
- `profile-store`: `chat` несётся и отсутствует; `saveChatSettings` публикует ответ, бросает `BffApiError`.
- `use-chat-consent`, `use-translation-switch`: `required` / `visible` по таблице; `400` / `404` / `409` / сеть.
- Экраны: `MessageBubble` — подпись и кнопка по видам, переключение; `ChatThreadScreen` — нет `chat` → нет
  карточки, отправка как сегодня; есть `chat` без согласия → карточка, отправка выключена до успеха;
  `ProfileScreen` — строка-переключатель по `visible`.
- Переводы: тест namespace'ов (новый `chat-settings` на диске и в списке), `@max`, глоссарий, `SAME_AS_ENGLISH`.
- `npm run lint` (`--max-warnings 0`), `npm run typecheck`, `npm test` — целиком.

## 9. Проверка в маноре (после мёржа; расписано для координатора)

**A. Сразу, на текущем BFF (без `chat`):** `npm ci` в маноре (контракты v0.31.0), Android debug.
1. Чат, отправка текста и файла, история, превью Home / Chats — как до задачи. Ни галочки, ни переключателя.
2. Логи BFF: отправка с dev-сборки без флага — без `lang` в query; сборка с `.local` (`AURA_I18N_ENABLED=true`) —
   `lang=<язык>`. История и профиль — с `lang` в обоих случаях.

**B. После `AURAT-0196` (язык и согласие на сервере):**
3. Новый пользователь: в треде — карточка согласия, отправка выключена; галочка → `PATCH` → карточка уходит, в
   ответе `consent.version = 1`, `translationEnabled = true`. Другой тред — карточки нет.
4. Профиль: строка «Переводить мой чат» включена; выключить → `translationEnabled = false`; включить снова.
5. Сервер на контрактах старше клиента — эмулировать нельзя без правки; закрыто тестом.

**C. После конвейера (задача 5), язык `de`, флаг включён:**
6. Ответ стола: сначала английский + «Wird übersetzt…», затем немецкий + «Von KI übersetzt · Original anzeigen»;
   «Original anzeigen» → английский; снова — немецкий.
7. Превью Home и Chats — немецкий текст.
8. Приложение в фоне, ответ стола, возврат — перевод на месте (догонка `translatedFrom`).
9. Сменить язык приложения на `fr` — тот же ответ: английский и подпись на французском «Traduction · Deutsch ·
   Afficher» (по кнопке — немецкий текст).
10. iOS (флаг выключен) — в конце: отправка без `lang`, галочка и переключатель есть (они от `chat`, не от языка).

## 10. Не здесь

Сервер (`AURAT-0196`, конвейер), веб (задача 8), подтверждение 18+ при входе (решение 10 — отдельная задача),
перевод при чтении (смена языка не переводит старое заново), повтор неудавшегося перевода по кнопке (сервер
дозаполняет сам), пуши (не меняются).

## 11. Решения (рекомендация первой)

1. **Галочка блокирует отправку?**
   - **А (рекомендую).** Да: пока согласие не сохранено, отправить нельзя; набирать и прикреплять — можно. Явное
     согласие закрывает и дыру 1 legal («сам написал» — не согласие), а сообщение без галочки — именно то, что дыра 1
     описывает. Старые сборки чат не теряют: сервер отправку без согласия не отклоняет.
   - Б. Нет: галочка над полем, можно отправить и без неё — тогда без перевода. Мягче, но дыра 1 для такого
     человека остаётся открытой.
2. **Перевод на другом языке (язык чата ≠ язык интерфейса):**
   - **А (рекомендую).** Английский + тихая подпись «Перевод · Deutsch · Показать» — по кнопке тот же пузырь
     показывает немецкий (`AURAI-0012` §2: «переключатель работает»).
   - Б. Английский + «Не переведено», перевод не показывается вовсе (§7, проще, но перевод есть и спрятан).
3. **Когда виден переключатель в профиле:**
   - **А (рекомендую).** Только при согласии текущей версии. Без согласия переключать нечего (сервер ответит `409`),
     а согласие собирает чат.
   - Б. Всегда при `chat`; включение без согласия открывает текст согласия в листе на профиле. Вторая точка сбора
     согласия — больше UI и строк.
