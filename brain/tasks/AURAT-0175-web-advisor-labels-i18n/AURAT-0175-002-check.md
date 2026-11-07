# AURAT-0175-002 — check

Дата: 2026-11-07

- Папка задачи уже есть: `001-initial.md` — заглушка из `aura-app-manor` (координатор `slave-1-ac`), запуск по слову
  владельца «запускай 0174 и 0175». Здесь исполняется только `0175`; `0174` — в aura-app-manor slave-0.
- Слот: `wts-start slave-1 feature/AURAT-0175-web-advisor-labels-i18n` — master от `develop` @ `154c842`, missus от
  `11bdd53`. `active-work.md` — slave-1 busy.
- Сервер `AURAT-0173` — **done** (`012-approved`): BFF `develop` `167f0b9`, контракты `main` `308b95e`, тег **`v0.29.0`
  на GitHub есть** (`git ls-remote` → `6311ab0`). Значит, локальная сборка `aura-contracts` не нужна — пиним тег.
- Глоссарий: в приложении (манор и app slave-0) — `glossary.json` **v2**; v3 (`AURAT-0174`) ещё не закоммичен.
  У веба копии глоссария **нет вовсе** (ни v1, ни v2).
- Веб сейчас на `@aura/contracts#v0.28.0`.

Дальше: 003 — понимание.
