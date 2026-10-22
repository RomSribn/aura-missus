# AURAT-0121-006 — Approval

Date: 2026-10-22
Статус: **одобрено** — рекомендации 1–10 и правки владельца 1–5; правки внесены в `005` до кода.

## Правки владельца

1. **FSD:** `useGate` живёт в `features/require-auth`, из `features/ask-question` его брать нельзя
   (Steiger: feature → feature). Gate вызывает модель `pages/home`: AskHero получает `onAsk` от
   страницы (AskHero хендоффа: «The parent decides what happens next»). → `005` §1, §8.
2. **Часть 2, карточка вопроса в Book:** не «will see it when the session starts» — по
   `AURAT-0122` чаттер получает вопрос заметкой сразу при брони и ещё раз на старте. Текст по
   хендоффу: «Shared with {name}». → `005` часть 2 п. 2.
3. **«Что веб просит у 0122»** сверено с одобренной `AURAT-0122-005` / `006`: `""` / пробелы =
   вопроса нет; `Session.question: string | null`, необязательный на проводе
   (`.default(null)`). → `005` «Что даёт `AURAT-0122`»; Booked читает `Session.question`.
4. **Слой карточки и хранилища:** карточка вопроса нужна шторке Book (widget) → `QuestionCard` в
   `entities/session/ui` сразу; хранилище вопроса — из `entities/message` в `entities/session`
   (чат его больше не читает). → `005` §4, §8.
5. **Best match** — только при выбранной теме; без темы карточки без бейджа. → `005` §3, §5, тесты.

## Отмечено при сверке с 0122 (без решения владельца — вне объёма)

Строка «Question» в детали `/sessions` (`AURAT-0122-005` §1 называет её потребителем
`Session.question`) в объём `AURAT-0121` не входит — в «Вне задачи».

Next: 007-execute — часть 1.
