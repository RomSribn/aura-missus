# AURAT-0096-007 — execute

Сделано в slave-1 (`feature/AURAT-0096-promo-first-session-broadcast`), не закоммичено.

## Файлы
- `src/modules/chatwoot/chatwoot.client.ts` — `createOutgoingMessage` (`outgoing`, `private: false`).
- `src/modules/chatwoot/chatwoot-messaging.port.ts` — `ConversationTag`; `postAdvisorMessage`,
  `ensureConversationTag`, `listConversationTags`, `tagConversation`.
- `src/modules/chatwoot/chatwoot-messaging.service.ts` — реализация (метка аккаунта — на
  сайдбаре; на диалоге — read → add → write, весь набор сохраняется).
- `src/modules/promo/` — новый модуль: `first-session-promo.ts` (текст, `::SESSION::`, метка,
  `pickConversation`), `promo-audience.repository.ts` + Prisma-реализация,
  `first-session-promo.service.ts`, `promo.module.ts`.
- `src/promo-first-session.ts` — CLI (`--dry-run` / `--only <userId>` / `--limit <n>`), npm-скрипт
  `promo:first-session`; `OperatorCliModule` + его spec; README (Operator commands).
- Тесты: client, messaging service, promo (pickConversation + текст через парсер приглашения),
  сервис (порядок «метка → отправка», пропуски, лимит, ошибки, dry-run, --only), CLI.
  `chat.service.spec.ts` — фейки порта дополнены новыми методами.
- brain: `AURAF-0017` — строка `012` (BE ✗ до проверки на dev/проде).

## Решения по ходу
- Текст — одним абзацем: при вырезании `::SESSION::` ingestion схлопывает пробелы, перенос
  строки до телефона не дошёл бы. Слова — утверждённые.
- `--dry-run` метку на аккаунте не создаёт (ничего не пишет вообще); создаёт первый
  настоящий прогон.
- Проверка оффера — по юзеру через `SessionsRepository.hasUsedFirstSessionOffer` (тот же
  предикат), а не одним запросом: field reference во вложенном фильтре в слоте не проверить.
- Ошибки: `tag` — диалог не помечен, следующий прогон повторит; `send` — помечен, смотреть
  в деске. Exit 1, если были ошибки.
- По `AURAF-0017-009` новое приложение рисует приглашение с чипом «−50%» — D1 этим и хорош.

## Проверки (slave)
`typecheck`, `lint`, `prettier --check` — чисто; `jest` — 122 suites / 1537 tests зелёные;
`nest build` → `dist/promo-first-session.js` есть.

## Дальше
Ревью → коммит → мерж в `develop` (отдельное «да») → `bff-dev` → проверка на dev (`005`).
