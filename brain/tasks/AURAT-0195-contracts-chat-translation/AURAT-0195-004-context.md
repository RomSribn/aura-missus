# AURAT-0195-004 — context

Источники: `AURAI-0012` (+ legal), `aura-contracts` `main` `14073f1` (`src/chat.ts`, `profile.ts`, `language.ts`,
`README.md`), BFF slave-2 `0410ed7`, приложение — манор `aura-app-manor` `e0ed5de` (только чтение).

## Факты из кода

- `Message` (`chat.ts:104-204`): новые поля добавлялись как `.optional()` (`spread`, `sessionInvite`, `marker`) —
  «absent, not null»; ответные поля — без строгих форматов (асимметрия v0.8.2). `HistoryQuery.deletedFrom` →
  `HistoryResponse.deletedIds` (`.default([])`) — образец догонки. `WsServerEvent` — discriminated union,
  `message.deleted` добавлен в v0.22.0 тем же способом.
- `ProfileResponse` / `ProfilePatchRequest` (`profile.ts`): `PATCH /v1/me` — `.strict()`; аватар-маршруты отвечают
  тем же `ProfileResponse` (одна проекция `toProfileResponse`).
- Языковые поля ответа — простые строки (`copyLanguage: z.string().min(1).default('en')`, v0.30.0).
- **BFF строит ответы по выходному типу** (`z.infer`): `getHistory` возвращает `{ messages, deletedIds }`
  (`chat.service.ts:122-147`), `toProfileResponse` — шесть полей (`profile-response.ts`). Новое поле с
  `.default(...)` в ответе делает ключ обязательным в типе → **BFF без правки кода не соберётся**. С `.optional()`
  — соберётся.
- BFF `ZodValidationPipe(historyQuerySchema)` — объект не строгий: незнакомый `translatedFrom` от нового клиента
  молча отрезается, догонка просто пустая.
- `PATCH /v1/me` строгий, но поле, объявленное в контракте и не реализованное сервером, пройдёт валидацию и
  **молча ничего не запишет** — ровно то, от чего `.strict()` защищает. Довод за отдельный маршрут для согласия.
- Приложение: `WsServerEvent.safeParse` + `switch` без `never`-проверки (`ChatProvider.tsx:662-697`) — новый тип
  события не ломает ни сборку, ни старые сборки (незнакомое событие отбрасывается). `HistoryResponse.parse`,
  `ProfileResponse.parse` — новые необязательные поля проходят.
- В слоте BFF `node_modules/@aura/contracts` — **0.28.0**, хотя `package.json` / lock на `#v0.30.0`
  (preflight `npm install` его не обновил). Для проверки всё равно подкладывается свежий `dist`.

## Требования (AURAI-0012 §8 шаг 2, решения)

- `Message.translation?` — `pending | translated (content) | failed`, с `language`; `content` советника — английский
  оригинал, `content` человека — его оригинал; перевод сообщений человека на `en` приложению не отдаётся.
- `HistoryQuery.translatedFrom` → `HistoryResponse.translations: { messageId, translation }[]`.
- WS `message.translated`; пуша нет.
- Язык — у пользователя, пишет только отправка с `?lang`, отсутствующий `?lang` не перезаписывает (решение 5);
  при `en` — без перевода (решение 4); ответ на языке интерфейса (решение 3).
- Согласие — галочка перед первым сообщением, версия и время, переключатель в профиле; после галочки перевод
  включён; отзыв = выключить перевод, чат целиком — удаление аккаунта (решение 6, legal).
- Старые клиенты поле игнорируют.

## Противоречий нет

Одно уточнение к исследованию: в `AURAI-0012` §2 данные названы `chatTranslationConsent*`, а по legal галочка —
согласие на чувствительные данные в чате **вместе** с переводом, поэтому в контракте — `consent` у настроек чата,
а не «согласие на перевод». Имена колонок — дело задачи 3.
