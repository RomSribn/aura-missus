# AURAT-0205 — эмодзи в маркерах сессии на столе Chatwoot
Type: technical (desk UX)
Status: done
Priority: P2
Slave: slave-1, ветка `feature/AURAT-0205-bff-session-marker-emoji`

## Что

Строка-маркер сессии, которую BFF постит в Chatwoot activity-сообщением, получает
эмодзи с обеих сторон:

| Вид | В Chatwoot (стол) | Сохраняется / уходит в приложение и веб |
|---|---|---|
| старт | `🟢 Your session has started 🟢` | `Your session has started` (как было) |
| конец | `🔴 Your session has finished 🔴` | `Your session has finished` (как было) |

«Оберни» — кружок с обеих сторон (подтверждено владельцем 2026-11-09).

## Как

1. Новый чистый модуль `src/modules/sessions/session-desk-marker.ts`:
   `deskMarkerLine(marker: MessageMarker): string` — берёт текст из
   `SESSION_MARKER_CONTENT[marker]` и оборачивает эмодзи по виду
   (`session_started` → 🟢, `session_finished` → 🔴). Таблица эмодзи типизирована
   `Record<MessageMarker, string>`, так что новый вид маркера не соберётся без своего
   эмодзи, а текст стола не может разойтись с сохранённым.
2. `SessionsService.announce()`: в `postActivityMessage` — `deskMarkerLine(...)`,
   в `ingestSystemMarker` — по-прежнему `SESSION_MARKER_CONTENT[...]`.
3. Адаптер chatwoot не меняется — постит то, что дали; обновить только комментарии
   в порте / клиенте, где строка процитирована.
4. Комментарий в `session-markers.ts` уточнить: стол видит этот текст с эмодзи
   (AURAT-0205), сохраняется — без.

## Не трогаем

Сохранённый текст, `SESSION_MARKER_CONTENT`, `markerOf`, `@aura/contracts`,
приложение / веб, Telegram, приватные заметки стола. Старые строки в истории
Chatwoot остаются без эмодзи (переписывать их не будем).

## Проверки

- Слейв: unit-тесты — `announce` постит в Chatwoot текст с эмодзи, а в
  `ingestSystemMarker` отдаёт прежний (оба вида); `deskMarkerLine` для обоих видов;
  `markerOf` узнаёт сохранённый текст и **не** узнаёт текст с эмодзи. Плюс lint,
  typecheck, build.
- После мёржа, на bff-dev (develop): начать и закончить сессию с эмулятора → в
  Chatwoot `🟢 … 🟢` и `🔴 … 🔴`, в приложении разделители как раньше.

## Мёрж

Только с явного одобрения в моменте. Открыт релизный PR #11 `develop → main` из самой
ветки develop: мёрж AURAT-0205 до его мёржа означает, что эмодзи уйдут в этот релиз.
Когда мёржить — решает владелец.
