# AURAT-0199-007 — execute

Дата: 2026-11-08 · slave-0, `feature/AURAT-0199-app-translation-catchup-pending` (без коммитов, всё застейджено)

## Файлы

- `src/features/chat/lib/translation.ts` — `translatedFromOf` берёт самое старое серверное сообщение советника с
  `pending`; `failed` не якорит. JSDoc: `failed` окончателен (`AURAT-0198`), якорь на нём рос бы вечно.
- `src/features/chat/api/chat-api.ts` — JSDoc `HistoryParams.translatedFrom`: «still `pending` (`failed` is final)».
- `src/screens/chat-thread/config/locales/en.ts` — JSDoc `translation.failed`: «did not work out and will not come; the
  English is shown and nothing is offered». Строка, 23 перевода, `@max 22` — без изменений.
- `src/features/chat/lib/__tests__/translation.test.ts` — (translated a, failed b, pending c) → `c`; только `failed` →
  `undefined`.
- `src/features/chat/model/__tests__/ChatProvider.translation.test.tsx`:
  - «asks from the oldest reply still pending — a failed one is final — and lays what comes over it»: якорь `m3`, m2
    остаётся `failed`, m3 → `translated`; **второй синк без `translatedFrom`** (замечание координатора, регрессия на
    «вечный якорь»);
  - новый «a pending reply the catch-up brings back failed anchors no more»: `pending` m1 → догонка приносит `failed` →
    следующий синк без `translatedFrom` (вариант «по желанию»);
  - «nothing unsettled» — в треде теперь и `failed`.

## Проверка

- Новые тесты на старой `translatedFromOf` — 5 падений; на новой — зелёные.
- `npm run lint` — 0 (`--max-warnings 0`); `npx tsc --noEmit` — 0 (скрипта `typecheck` в `package.json` нет);
  `jest --no-watchman` — 245 сьютов, 3285 тестов, всё зелёное.
- Стек не поднимался. В маноре после мёржа: синк треда с `failed`-ответом и без `pending` не шлёт `translatedFrom`.

## Прочее

`mergeTranslation` и контракты не тронуты. В слоте был `npm ci` (устаревший `node_modules`, contracts 0.30.0).
