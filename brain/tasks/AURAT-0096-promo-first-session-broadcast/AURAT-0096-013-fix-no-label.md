# AURAT-0096-013 — fix: без метки в Chatwoot

Владелец (2026-10-17, до мержа в `main`): «я бы не ставил плашку кастомную — её потом не снять
без автоматизации, и платный реальный юзер был лишь один, не к чему оно».

## Как теперь «один раз»
Память прогона — наш store: юзер пропускается, если в любом его диалоге уже есть
`ADVISOR`-сообщение с ровно этим текстом (`FIRST_SESSION_PROMO_TEXT`). Сообщение попадает
в store через webhook ~через секунду после отправки → два прогона не должны идти
одновременно (README, комментарии). Ошибка отправки ничего не записывает → следующий прогон
повторит (стадий `tag`/`send` больше нет).

## Изменения
- Порт/адаптер: убраны `ConversationTag`, `ensureConversationTag`, `listConversationTags`,
  `tagConversation`; остался `postAdvisorMessage`. Фейки в `chat.service.spec.ts` — так же.
- `PromoAudienceRepository.listRecipients(announcement)` / `findRecipient(userId, announcement)`,
  `PromoRecipient.announced` (Prisma: `_count` сообщений `ADVISOR` с этим `content`).
- Сервис: `alreadySent` вместо `alreadyTagged`, проверка до оффера; dry-run в Chatwoot не ходит.
- CLI-отчёт, README, тесты.

typecheck / lint — чисто; `jest` 122 suites / 1534 tests — зелёные.

## Dev
На dev-аккаунте 2 остались следы прошлой версии: метка `promo-first-50` на conversation 25 (снята),
на 3 диалогах полного прогона и на уровне аккаунта — убрать при перепроверке. После выкатки
`--dry-run` должен показать `4 already sent` (по сохранённым сообщениям).
