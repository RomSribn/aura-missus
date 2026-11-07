# AURAT-0171-012 — merge

Дата: 2026-11-07

Сессия слота оборвалась после `011` (Mac выключился); работа была цела в stage, ветка не отставала от `develop`.
Владелец одобрил коммит, мёрж и JSDoc контрактов (AskUserQuestion).

- Ветка: `feature/AURAT-0171-bff-tarot-deck-i18n`, коммит `cdb205e` — «Колода таро на 23 языках и ?lang у карты дня,
  расклада и истории чата (AURAT-0171)».
- `wts-finish slave-2`: `develop` `c24d55c..bbc4c6c`, пуш в origin — OK; слоты 1, 3, 4, 5 обновлены.
- `aura-contracts`: `main` `3f12472` — «TarotCard.name — на языке запроса (AURAT-0171)», `src/tarot.ts:42`
  `/** Name in the request's language (\`?lang\`), e.g. "The Sun" in English. */`; без тега (решение 2 — А), пуш — OK.
- missus не закоммичен (до закрытия задачи).

Дальше — проверка в маноре: `GET /v1/tarot/daily?lang=de` — немецкая карта с тем же `imageUrl`; `?lang=mt` при
`DISABLED_LANGUAGES=mt` → английский; `POST /v1/tarot/spread/:messageId/pick?lang=fr` — карта на французском;
`GET` истории чата с `?lang=fr` / без `lang`. После — `AURAF-0023` строка 010, колонка BE — ✓.
