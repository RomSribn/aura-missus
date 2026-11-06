# AURAT-0168-009 — execute

Дата: 2026-11-06 · по `007-spec-v2.md` (одобрена, `008`)

## aura-contracts (`feature/AURAT-0168-v0.28.0`, не закоммичено)

- `src/language.ts` (новый): `LANGUAGES` (24), `Language`, `SOURCE_LANGUAGE`, `LANGUAGE_QUERY_PARAM`, `isLanguage`;
  экспорт из `index.ts`.
- `src/chat.ts`: `MESSAGE_MARKERS`, `MessageMarker`, `Message.marker: z.string().min(1).optional()`; doc у `content`
  — английские заглушки токенов, клиент при `marker` / `spread` / `sessionInvite` показывает своё слово.
- `src/app-config.ts`: `AppConfigDisabledLanguages = z.array(z.string())`,
  `AppConfigResponse.disabledLanguages: …default([])`.
- `package.json` → `0.28.0`; README — абзац `v0.28.0` и строки таблицы модулей (`language`, `chat`, `app-config`).
- `npm run typecheck && npm run build` — ок. `dist` скопирован в `node_modules/@aura/contracts` BFF только для
  проверки (в коммит не идёт).

## aura-bff (`feature/AURAT-0168-bff-i18n-lang-marker`, staged)

- `src/modules/chat/session-markers.ts` (новый): `SESSION_MARKER_CONTENT`, `markerOf(direction, content)` — тексты
  дословно прежние; `sessions.service.ts` больше не держит свою копию (`announce` берёт текст отсюда).
- `chat.service.ts` `toDto`: `marker` — только `system` + точный текст (история, сокет, ответ отправки).
- `src/config/env.schema.ts`: `DISABLED_LANGUAGES` — CSV, trim + lowercase, коды из `LANGUAGES`, `en` запрещён,
  дубли схлопнуты, порядок контракта.
- `app-config.builder.ts` / `.service.ts`: `disabledLanguages` в ответе; превью кампании в бэкофисе
  (`campaigns-admin.service.ts`) передаёт `[]` — язык не часть кампании.
- `src/contracts/`: `language.ts` (ре-экспорт), `message.ts` (`MESSAGE_MARKERS`, `MessageMarker`), `app-config.ts`
  (`AppConfigDisabledLanguages`), `openapi.ts` (`Message.marker`, `disabledLanguages` в `required`).
- `.env.example`, `README.md` — переменная и описание маркера / поля.
- Тесты: `session-markers.spec.ts`, `language.spec.ts` (новые); маркер в истории и в сокете
  (`chat.service.spec.ts`), env (`env.schema.spec.ts`), builder (поле, разбор контрактом, смена ETag), service,
  контрактные `message.spec.ts` / `app-config.spec.ts`; фикстуры трёх спеков дополнены `disabledLanguages: []`.

## Проверки

`npm run lint` — 0; `tsc --noEmit` — 0 ошибок; `npm run build` — ок; `jest` — 147 наборов, 1971 тест, все
зелёные (против локального `dist` v0.28.0).

## Не сделано / дальше

- Резолвер `?lang` — `AURAT-0171` (решение `008`).
- Пин `@aura/contracts#v0.27.0` в `package.json` ещё старый: перепин на `#v0.28.0` — после пуша тега (с одобрения
  владельца), до коммита BFF.
- AURAF-0023 строка 009: BE ✗ → ✓.
