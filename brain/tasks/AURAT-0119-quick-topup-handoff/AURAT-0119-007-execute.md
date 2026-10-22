# AURAT-0119-007 — Execute

Date: 2026-10-22
Slave: `slave-1`, ветка `feature/AURAT-0119-quick-topup-handoff` (не закоммичено, в stage).

## Изменено (aura-app)
- `shared/ui/bottom-sheet/BottomSheet.tsx` (+ `index.ts`, `shared/ui/index.ts`,
  `shared/index.ts`) — `SHEET_HANDOFF_WAITS_FOR_CLOSE = isIOS`: ждать `onClosed` перед
  следующей модалкой нужно только iOS (`AURAT-0020`). Внутренняя проверка `isIOS` в самом
  `BottomSheet` (какой сигнал считать закрытием) не тронута — это другое правило.
- `screens/chat-thread/model/use-quick-book.ts` — `goTopUp()` вынесен; `onTopUp`: iOS — как было
  (`leavingFor 'topUp'` → `closed`), Android — `goTopUp()` сразу.
- `features/paid-session/model/use-paid-session.ts` — `goTopUp`: Android — `onTopUp` сразу,
  iOS — через `sheetClosed` как было.

Тесты: `use-paid-session.test` (+1: Android — сразу и один раз), новый
`screens/chat-thread/model/__tests__/use-quick-book.test.tsx` (2: iOS ждёт `closed`, Android —
сразу и один раз). Jest-пресет RN — iOS, Android подменяется геттером константы.

Проверки: `tsc`, `npm run lint` — чисто; `jest` — 129 suites / 953 tests passed.

## Открытое
- Как выглядит вживую — только на устройстве после merge (staging-APK, SM-A505FN):
  Quick book → Top Up и Extend → Top Up.
