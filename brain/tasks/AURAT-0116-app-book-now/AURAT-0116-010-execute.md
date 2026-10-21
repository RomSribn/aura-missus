# AURAT-0116-010 — Execute (guard в revalidate)

Date: 2026-10-21

Правка владельца по `009`: в `revalidateAvailability` ответ игнорируется, если
`answeredFor.current !== minutes` — длительность сменили, пока чтение летело; у смены
длительности свой запрос, и устаревший ответ не должен перезаписать сетку.

Тест: `use-booking.test` — «an answer for a block no longer chosen is ignored».
Проверки: `tsc`, `npm run lint` — чисто; `jest` — 128 suites / 949 tests passed.

Дальше: коммит в ветку `feature/AURAT-0116-app-book-now` (master) и brain — своими путями.
Merge — только с подтверждения владельца.
