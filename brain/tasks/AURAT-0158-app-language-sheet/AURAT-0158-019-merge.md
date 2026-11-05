# AURAT-0158-019 — merge (фикс падения: обратно на legacy-API)

Дата: 2026-11-05. Владелец одобрил коммит, мёрж и правило в build rules (`AskUserQuestion`).

- Коммит `cc322eb`; `wts-finish slave-1` → develop `35e0572..248c7db`, push прошёл, slave-0 обновлён.
- Манор @ `248c7db`: `npx tsc --noEmit` — чисто; `npx jest --no-watchman` — 179 наборов, 1741 тест, зелёные.
- Workspace: `.claude/aura-build-rules.md`, React Native Guidelines п. 7 — gesture-handler только legacy-API, пока
  RN < 0.86.2 (gesture-handler #4241); коммит `86db8b1` — только эта строка (в файле лежат чужие незакоммиченные
  правки `AURAT-0155`, не тронуты). Workspace-репо локальное, без remote.
- Missus (шаги 012–019) — в индексе manor missus, не закоммичен.

Дальше — сборка на A50 (рецензент) и проверка владельцем: нет assert в logcat, свайп листов.
