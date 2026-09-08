# AURAT-0067-002 — что уже есть

Дата: 2026-09-08 · slave-2 · `feature/AURAT-0067-bff-write-review`

## Где лежит 001

`001-initial` **не пишется здесь**: бриф выдан из `aura-app-manor` и лежит в его
клоне brain —
`<aura-app-manor>/project/manor/missus/brain/tasks/AURAT-0067-bff-write-review/AURAT-0067-001-initial.md`.
В `aura-missus` он ещё не запушен, поэтому в этом клоне папка задачи пустая.
Собственная нумерация начинается с `002`, как указано в задании; когда app-манор
запушит свой файл, оба сложатся в одну папку без конфликта.

## Что нашлось в этом клоне brain

| Документ | Есть здесь | Комментарий |
|---|---|---|
| `features/AURAF-0014-advisor-reviews/` | да | фаза 1: показ отзывов, три колонки-заготовки |
| `tasks/AURAT-0058-advisor-reviews-backend/` | да | серверная половина фазы 1 — сид, агрегаты, `reviews[]` в каталоге |
| `features/AURAF-0016-writing-a-review/` | **нет** | написана в app-маноре, не запушена — читал по абсолютному пути |
| `decisions/AURAD-0014-two-speed-reviews-and-counters.md` | **нет** | то же самое |
| `tasks/AURAT-0066-app-write-review/` | **нет** | то же самое; клиентская половина уже построена |
| `tasks/AURAT-0067-bff-write-review/` | пусто | эта папка, заведена сейчас |

Задача не начиналась раньше: ни ветки, ни шагов, ни строк в `advisor_reviews`
сверх засеянных 42.

## Состояние слота

`wts-start slave-2 feature/AURAT-0067-bff-write-review` отработал: обе ветки
созданы от манора (`master` @ `85806af`, `missus` @ `c2eee62`), preflight прошёл.

## Дальше

`003-understand` — что именно строим, своими словами.
