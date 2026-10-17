# AURAT-0096-021 — откат кода

Владелец (2026-10-17): «всё разослалось, теперь нужно откатить эти изменения, они нам не нужны».

Код возвращён к дереву `82be18d` (до задачи) — проверено `git diff --cached --quiet 82be18d`:
удалены `src/modules/promo/`, `src/promo-first-session*.ts`, npm-скрипт `promo:first-session`,
`ChatwootClient.createOutgoingMessage`, `ChatwootMessagingPort.postAdvisorMessage` (+ реализация,
фейки, тесты), `PromoModule` в `OperatorCliModule`, раздел README. Миграций и данных откат не
касается: отправленные сообщения остаются в тредах и в store.

typecheck / lint — чисто; `jest` 119 suites / 1505 tests — зелёные.
История рассылки — в шагах `009`–`020`; строка `AURAF-0017-012` помечена «выполнено, команда удалена».

## Merge
С подтверждения владельца — **только `develop`**: `d213ee3` → `develop` @ `3cab10c`, запушено →
`bff-dev`. `main` (`7ae4228`) пока содержит команду — уйдёт со следующим обычным релизом
`develop` → `main` (решение владельца: прод отдельно не перевыкатывать).
