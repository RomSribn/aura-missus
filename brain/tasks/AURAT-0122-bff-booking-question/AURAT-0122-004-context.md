# AURAT-0122-004 — Context

Date: 2026-10-22
Код: `aura-bff` `develop` @ `215896b`; `@aura/contracts` `v0.23.0` (`main`, чисто).

Хендофф веба (`aura_web/design_handoff_aura_web`, advisory):
- вопрос ≤ 250 символов (`NAVIGATION.md` §Ask, README §4.1); на `/match` редактируем;
  в Book — карточка «will be shared with the advisor»; Booked — «{Advisor} has your
  question and will prepare…»;
- вопрос виден человеку и потом: Upcoming-карточка и деталь сессии `/sessions` — строка
  «Question» (README §4.3) → вопрос нужен в `Session` ответа;
- хендофф рисует `POST /checkout {…, question, …}` — у нас оплаты картой нет (`AURAD-0009`),
  её место — `POST /v1/advisors/:advisorId/sessions`.

Contracts (`src/session.ts`): `BookSessionRequest` — `z.object({ startsAt?, startNow?,
minutes, idempotencyKey }).refine(…)`, неизвестные ключи срезаются (старый BFF молча
выбросит `question`). `Session` — 11 полей, `question` нет. Правило повтора (`AURAT-0109`):
тот же ключ → исходная сессия, тело не сравнивается.

BFF:
- `SessionsService.book` (`sessions.service.ts:262`): повтор отвечается до проверок; новая
  запланированная бронь → `notifier.notify(session, 'booked')`; моментальная (`startNow`,
  рождается `ACTIVE`) → `afterActivated` → только `'started'`, без `'booked'`.
- Заметки о сессии (`AURAT-0091/0092`): `SessionNotifier` → по джобе на канал;
  `SessionNotice` в джобе — только факты (id, времена), сессию канал **перечитывает из
  базы** при доставке (`findByIdWithContext`). Каналы: `DeskNoteChannel` (приватная заметка
  в разговоре Chatwoot с упоминанием назначенного агента; человек её не видит) и
  `StaffChatNoticeChannel` (Telegram, третья сторона — «never the client»).
- Prisma `Session` — колонки вопроса нет; `toDto` — `sessions.service.ts:859`.
- Удаление аккаунта (`prisma-account-erasure.repository.ts:213`): сессии остаются (деньги),
  `conversationId → null`; текст вопроса — личные данные человека, его придётся стирать там же.
- Виджет «Агентский стол» (`agent-desk`): списки сессий клиента (`DeskClientSession`) без
  вопроса.
- Логи: тела запросов не пишутся (`http-logger.options.ts` — только url); `ZodValidationPipe`
  отдаёт `issue.message` — у `max` значение не попадает.

Противоречий нет. Открытые решения — в спеке (005).

Next: 005-spec.
