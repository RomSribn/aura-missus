# AURAT-0195-007 — execute

Дата: 2026-11-07 · slave-2. **Не закоммичено**, всё застейджено (missus slave-2, клон aura-contracts). Код BFF и
приложения не менялся.

## aura-contracts (`/Volumes/Work/personal/ai-manors/aura-contracts`, ветка `feature/v0.31.0-chat-translation` от `main` `14073f1`)

По спеке `005` без отступлений; JSDoc по-английски, как во всём пакете.

- `src/chat.ts`:
  - `MessageTranslation` — discriminated union `pending | translated (content) | failed`, у всех
    `language: z.string().min(1)`; JSDoc — что значит язык и что показывать (§7 `AURAI-0012`);
  - `MessageTranslationUpdate { messageId, translation }`;
  - `Message.translation: MessageTranslation.optional().catch(undefined)` — только у советника, `content` —
    оригинал, когда поля нет;
  - `HistoryQuery.translatedFrom?`, `HistoryResponse.translations: z.array(MessageTranslationUpdate).optional()
    .catch(undefined)`;
  - `WsServerEvent` + `message.translated { advisorId, messageId, translation }`, без пуша; шапка union обновлена;
  - JSDoc `SendMessageRequest` — `?lang` отправки пишет язык чата, без выбора языка `?lang` на отправку не ставить.
- `src/chat-settings.ts` (новый): `CHAT_CONSENT_VERSION = 1`, `ChatConsent { version, givenAt }`, `ChatSettings
  { language (только чтение), translationEnabled, consent }`, `ChatSettingsPatchRequest` (`.strict()`,
  `consentVersion` 1..`CHAT_CONSENT_VERSION`, `translationEnabled`), `ChatSettingsRefusalCode`
  (`chat_consent_required`, 409). JSDoc — правила записи языка, согласия, отзыва (решения 3–6).
- `src/profile.ts`: `ProfileResponse.chat: ChatSettings.optional()` — нет поля = сервер настроек чата не знает.
- `src/language.ts`: абзац — единственный `?lang` с долгим действием — у отправки.
- `src/index.ts`: `export * from './chat-settings'`.
- `package.json` → `0.31.0`; `README.md` — абзац v0.31.0, строки «What's inside» (`chat`, `chat-settings`,
  `profile`), пометка «forward contracts до задач сервера». `package-lock.json` не трогал (там исторически 0.1.0,
  как и в v0.30.0).

## Проверки (в слоте, без стека)

1. Контракты: `npm run typecheck` — чисто; `npm run build` — чисто.
2. BFF slave-2 (`0410ed7`), в `node_modules/@aura/contracts` подложен свежий пакет (`dist`, `package.json`,
   `README.md`; до этого там был **0.28.0** при lock на `#v0.30.0`), `prisma generate`: `lint` — чисто, `typecheck`
   — чисто, `build` — чисто, `jest` — **158 наборов, 2124 теста, все зелёные**. `git status` BFF пуст — правок нет.
3. Приложение (манор `aura-app-manor` `e0ed5de`, только чтение): `tsc -p` конфигом из scratchpad, который
   наследует `tsconfig` приложения и подменяет `@aura/contracts` на копию новой сборки (`zod` — симлинк на `zod`
   приложения, 3.25.76); сборка реально в программе (`--listFilesOnly`). **exit 0**, базовый `tsc --noEmit` на
   v0.30.0 — тоже 0. В манор приложения ничего не записано (`git status` пуст).
4. Совместимость — скрипт `compat.cjs` в scratchpad, обе сборки рядом (v0.30.0 — из `node_modules` приложения):
   **23 из 23**:
   - ответы v0.30 (сообщение, история, профиль текущего BFF) разбираются в v0.31, новых полей нет;
   - сообщение / история / профиль v0.31 разбираются в v0.30 (поля отрезаются);
   - `message.translated` старой сборкой отбрасывается, новой разбирается;
   - старый `HistoryQuery` отрезает `translatedFrom`;
   - незнакомый статус — сообщение живо, `translation` `undefined`; в догонке — страница жива, `translations`
     `undefined`;
   - `translated` без `content` отклоняется; `chat: {}` → `null` / `false` / `null`; кривое согласие → `null`;
   - `ChatSettingsPatchRequest` отклоняет `consentVersion` 2 / 0 / 1.5, `language`, незнакомый ключ; `{}` принимает.

## Открыто / дальше

- Мёрж (координатор, с одобрения владельца): контракты → `main` → тег `v0.31.0` → push. BFF на `develop` можно не
  переключать сразу: переход на `#v0.31.0` — в задаче 3 (сервер) вместе с кодом; при переключении без кода BFF
  соберётся (проверено), фичи просто нет.
- Передачи — `005` §7: сервер (задача 3 — язык и согласие, задача 5 — конвейер), приложение (7), веб (8).
  Подтверждение 18+ — отдельная задача у координатора.
- `AURAF-0024` (файл фичи устарел: «исследование не запущено») — синхронизировать при мёрже.
