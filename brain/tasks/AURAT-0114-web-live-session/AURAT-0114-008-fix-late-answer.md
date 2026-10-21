# AURAT-0114-008 — Fix: поздний ответ закрывает чужой диалог

Date: 2026-10-21

## Ревью владельца

1. Поздний ответ продления закрывает чужой диалог: `finish()` в `use-extend-session.ts` (успех и
   ветка 409/404) зовёт `onClose` → `closeDialog()` без проверки, что шторка ещё открыта. Нажать
   «Extend · $X», пока запрос идёт — «End session early»: ответ продления закроет «End this
   session?». То же в `use-finish-session.ts` (`.then(onDone)` после размонтирования).
   Исправить: `mounted` в `finish()` обоих хуков, «End session early» выключен на время `sending`
   и `checking`, тест.
2. Узкое окно второго списания при «Choose another block» — принято для v1, записано в «Открыто»
   007.

## Сделано

- `features/extend-session/model/use-extend-session.ts` — `finish()` ничего не делает после
  размонтирования (`!mounted.current`); в виде — `busy` (`sending || checking`).
- `features/extend-session/ui/extend-sheet.tsx` (+ css) — «End session early» `disabled={busy}`.
- `features/finish-session/model/use-finish-session.ts` — `mounted`: ответ после размонтирования
  не закрывает диалог и не ставит ошибку.
- `app/__tests__/live-session.test.tsx` — сценарий: продление в полёте → «End session early»
  выключен; шторку закрыли, открыли снова, перешли в «End this session?»; поздний 201 продления
  обновляет баннер (40 min), а «End this session?» остаётся открытым. Без защиты в `finish()` тест
  падает (проверено).

## Проверки

lint, typecheck — чисто; test — 74 файла, 1295 тестов, зелёные; build — собран. Всё
проиндексировано в master и missus, не закоммичено.
