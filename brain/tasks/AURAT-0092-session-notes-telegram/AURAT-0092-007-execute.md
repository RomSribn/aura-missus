# AURAT-0092-007 — execute

2026-10-17, slave-2, `feature/AURAT-0092-session-notes-telegram`. Не закоммичено, всё в индексе.

## Что сделано (aura-bff)

**Модель уведомлений** — `src/modules/sessions/notices/`:
- `session-notice.ts` — `SessionNotice` (факт: kind ∈ booked / rescheduled /
  cancelled / starting-soon / started, времена в epoch ms) и абстракция
  `SessionNoticeChannel { name; deliver(notice, session) }`, токен `SESSION_NOTICE_CHANNELS`.
- `desk-note.channel.ts` — `DeskNoteChannel` ('desk'): тексты из `AURAT-0084/0091`
  без изменений, `postPrivateNote(…, { mentionAssignee: true })`.
- `staff-chat.channel.ts` — `StaffChatNoticeChannel` ('staff-chat'): заголовок
  `📅 Booked · Mia · 20 min`, строка времени, ссылка «Open in desk». Только персона,
  блок и время — ничего о клиенте.
- `session-notice-channels.ts` — фабрика списка каналов: desk всегда, staff chat —
  если порт не `null`.
- `session-notifier.ts` — `SessionNotifier.notify(session, kind, previousStartsAt?)`
  → `addBulk` по задаче `notice` на канал, `jobId = notice-<channel>-<kind>-<id>-<startsAt>`;
  `deliver(data)` — канал по имени, no-op для выключенного канала / пропавшей сессии.
- `notice-time.ts` — общие `utcTime` / `utcSlot`.

**Сервис сессий** — `sessions.service.ts` больше не рендерит тексты и не знает каналов:
`book` / `reschedule` / `cancel` / `afterActivated` / `remindIfDue` зовут
`notifier.notify(...)`. `remindIfDue` сохранил свои проверки, но шлёт `starting-soon`
через каналы. `SESSION_REMINDER_LEAD_MINUTES` переехал в `session-policy.ts`.

**Адаптер Telegram** — `src/modules/telegram/` (запечатан, как `chatwoot`):
- `staff-chat.port.ts` — `StaffChatPort.post({ headline, lines, link? })` — части
  сообщения, без разметки; разметка и экранирование — дело адаптера.
- `telegram-staff-chat.ts` — Bot API `sendMessage`, HTML, без превью ссылок, таймаут
  10 с; отказ → `TelegramApiError(status, retry_after)`; токен (он в пути URL) не
  попадает ни в текст ошибки, ни в `cause`.
- `telegram.module.ts` — порт = `null`, если конфиг не задан (warn в лог).

**Chatwoot** — `ChatwootMessagingPort.deskConversationUrl(conversationId)`; URL
собирает `ChatwootClient` из `AGENT_DESK_FRAME_ANCESTOR` + account + display id (тот же
адрес, что в виджете `client/desk.ts`); `null` без публичного origin.

**Очередь/процессор** — задача `notice` → `notifier.deliver`. Задачи `desk-note`,
поставленные `AURAT-0091` до выкатки, доставляются тем же `DeskNoteChannel`
(TECH-DEBT #35 — удалить в следующем релизе).

**Конфиг** — `TELEGRAM_BOT_TOKEN` (формат токена @BotFather), `TELEGRAM_STAFF_CHAT_ID`
(число / `-100…` / `@username`); оба или ни одного (`superRefine`). В `.env.example` и
`deploy/env/bff.env.example`. README — `sessions/notices` и `telegram/`.

## Отступления от спеки
- Канал назван `StaffChatNoticeChannel` / порт `StaffChatPort`, а не «Telegram…»:
  канал говорит со «служебным чатом», Telegram — лишь адаптер за портом (заменить на
  Slack = новый адаптер, канал не трогается). Переменная — `TELEGRAM_STAFF_CHAT_ID`
  (в спеке была `TELEGRAM_SESSION_CHAT_ID`).

## Проверки
- `tsc`, `lint`, `build`; prettier по изменённым файлам — чисто.
- полный `jest`: 1498/1499; одно падение — `apple-refund.service.spec` (не тронут),
  отдельно 12/12; тот же нестабильный под параллельной нагрузкой, что в `AURAT-0084`.
- `app.module.spec` / `operator-cli.module.spec` зелёные — DI собирается, в т.ч. без Telegram.

## За владельцем до проверки в маноре
@BotFather → бот → добавить в группу → `chat_id` (напр. через `getUpdates`);
`TELEGRAM_BOT_TOKEN` / `TELEGRAM_STAFF_CHAT_ID` в env dev.

## Проверить в маноре
Бронь / перенос / отмена / за 5 мин / старт / «начать сейчас» → в Telegram-группе по
сообщению на событие со ссылкой на диалог; в Chatwoot заметки как раньше. Без
переменных — Telegram молчит, Chatwoot как раньше.
