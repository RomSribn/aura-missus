# AURAT-0199-005 — spec

Дата: 2026-11-08 · Тип: задача (без фичи; фича `AURAF-0024`) · Status: draft

## Правки

1. `src/features/chat/lib/translation.ts` — `translatedFromOf`: самое старое серверное (`status === undefined`) сообщение
   советника с `translation.status === 'pending'`; `failed` не якорит. JSDoc: «the oldest server message of the advisor
   whose translation is still `pending` — the only state the server may yet fill in; `failed` is final (contracts
   `abafea0`). None, and the sync asks for no catch-up at all.»
2. `src/features/chat/api/chat-api.ts:22` — JSDoc `translatedFrom`: «the oldest advisor message whose translation is
   still `pending`» (без «or `failed`»).
3. `src/screens/chat-thread/config/locales/en.ts:107` — JSDoc `translation.failed`: «Quietly, when the translation did
   not work out and will not come; the English is shown and nothing is offered.» Строка и 23 перевода не меняются;
   `@max 22` остаётся.
4. Тесты:
   - `translation.test.ts` — `translatedFromOf`: «the oldest server reply still pending — a failed one is final»
     (`translated a`, `failed b`, `pending c` → `c`); «only failed — no catch-up» (`failed`, `failed` → `undefined`).
   - `ChatProvider.translation.test.tsx:261` — «asks from the oldest reply still pending — a failed one is final, and
     lays what comes over it»: те же m1…m4, ожидание `translatedFrom: 'm3'`; ответ кладёт перевод на m3, m2 остаётся `failed`
     (окно сервера начинается с m3).
   - `:288` «nothing unsettled» — добавить `failed` в тред: `dto('m2', failed)` → `translatedFrom` не задан.

## Не трогаем

`mergeTranslation`, контракты (пакет не поднимаем — только комментарии в `main`), подпись «Originaltext», сервер.

## Проверка

`npm run lint`, `npm run typecheck`, `npm test` в слоте. Стек не поднимается; поведение в маноре после мёржа —
синк треда с `failed`-ответом не шлёт `translatedFrom` (по желанию, через логи BFF).
