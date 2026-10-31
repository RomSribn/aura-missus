# AURAT-0146-011 — merge

Дата: 2026-10-31 · Слот: slave-1 · Ветка: `feature/AURAT-0146-public-promo-codes`

Владелец одобрил ревью («одобряю»), затем отдельными ответами — выпуск контрактов и `wts-finish`
с push. Он знал, что скрипт сам пушит develop: первый вопрос об этом умалчивал, поэтому был
задан заново.

## Что сделано

1. Коммиты на ветке BFF:
   - `ed1fe6d` — публичные промокоды;
   - `d6ceac6` — `@aura/contracts` v0.26.0 (package.json + lock, pin `98c859e`).
2. aura-contracts: коммит `98c859e` на `feature/v0.26.0-public-promo-codes`, fast-forward в
   `main`, аннотированный тег `v0.26.0`, push `main` и тега. Тег на GitHub подтверждён
   (`ls-remote`).
3. `wts-finish slave-1`: merge в develop манора и push develop в origin `af00d64..6741848`.
   Idle-слоты 3–5 обновлены.
   - Missus: мёржить было нечего, step-файлы ещё в stage, их коммит будет при закрытии задачи.
     Push missus отказал: хаб манора отстаёт от origin на один коммит (push app-манора).
     **Перед `wts-release` хабу missus нужен `pull`.**

## Проверка в маноре (дальше)

- `prisma migrate deploy` на dev-базе; `migrate diff` должен показать лишним только частичный
  индекс `promo_redemptions_single_use`.
- Создать `TEST5` → погасить двумя аккаунтами → повтор `replayed: true` → отключить →
  `promo_code_disabled`.
- Одноразовые партии работают как раньше; старые партии показывают точное время срока.
- Сверить порог на форме (самая дешёвая сессия) и `SESSION_SLOT_TIMEZONE` на проде.

После проверки: approved → коммит missus → вопрос о `wts-release`. Затем 0147 перебазируется на
v0.26.0.
