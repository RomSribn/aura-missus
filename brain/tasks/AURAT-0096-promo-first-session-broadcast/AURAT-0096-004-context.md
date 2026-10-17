# AURAT-0096-004 — context

Проверено по коду `aura-bff` (`develop` @ `82be18d`; `main` @ `30930a2` отличается
только merge-коммитами — сверх рассылки на прод ничего не поедет).

## Доставка
- `message-normalizer.ts`: фильтра по отправителю нет — отбрасываются private,
  activity, пустые. Публичный `outgoing` от service-user пройдёт webhook → store →
  `delivery.fanOut` (FCM+WS) как ответ чатера; при потере webhook его подберёт
  reconciliation poll. Обходного push не нужно (rule 5).
- `ChatwootClient`: есть `createIncomingMessage`, `createActivityMessage`,
  `createPrivateNote`, `listConversationLabels`/`setConversationLabels` (замена
  всего набора), `listLabels`/`createLabel`. Публичного outgoing — нет.
- `chat.service.ts::toUpsert`: в advisor-сообщениях читаются токены чатера —
  `::SESSION::` превращает сообщение в карточку-приглашение на платную сессию
  (`session-invite-token.ts`, AURAF-0013); старые сборки видят просто текст.

## Аудитория
- `firstSessionOfferUsed(userId, fields)` — предикат для `Session` с field reference;
  обёрнут в `SessionsRepository.hasUsedFirstSessionOffer(userId)` (экспортируется
  из `SessionsModule`). Проверять по юзеру через него — тот же ответ, что у цены и
  кошелька; field reference внутри вложенного relation-фильтра в слоте не проверить.
- Удаление аккаунта (`AURAT-0042`) удаляет диалоги и сообщения, юзер-строка
  становится tombstone + `AccountErasure` → фильтр `erasure: null` + «есть диалог».
- `Conversation` без relation к `Advisor` (только `advisorId`); у `Advisor` есть `active`.
- Последняя активность — `max(Message.chatwootCreatedAt)`, иначе `Conversation.createdAt`.

## Цена в старой сборке
- `SessionsService.getPricing` отдаёт `creditMinor` = половина subtotal и
  `costMinor` — старая сборка уже показывает цену со скидкой (как «credit»).

## Операторские команды
- Образец: `src/desk-setup.ts`, `src/reviews-moderation.ts` — парсинг argv до импорта
  модуля, `NestFactory.createApplicationContext(OperatorCliModule)`, прод —
  `node dist/<cmd>.js` (в образе нет ts-node). README «Operator commands» описывает каждую.
- Окружения: Chatwoot один (`AURAD-0016`), прод = аккаунт 1, dev = аккаунт 2
  (`README`, `AURAT-0083`); `bff-dev` собирается из `develop` (`AURAT-0068`).

## Противоречий нет.
