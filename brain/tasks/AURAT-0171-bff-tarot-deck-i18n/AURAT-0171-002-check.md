# AURAT-0171-002 — check

Дата: 2026-11-06

- Папка задачи есть: только `001-initial.md` (заглушка из `aura-app-manor`, сессия `slave-1-9e`). Работы ещё не было.
- Слот `slave-2` стоял без ветки (detached на `c8d78cf`), хотя в `active-work.md` уже `busy`. Запущен
  `wts-start slave-2 feature/AURAT-0171-bff-tarot-deck-i18n`: master от `develop @ c8d78cf`, missus от `master @ 9adc0bb`.
  `npm ci` — ок (контракты в `node_modules` — `v0.27.0`).
- Связанное:
  - `AURAF-0023` строка 010 (колода на языке пользователя) и шаг 5 плана;
  - `AURAT-0137-005/006` — решение 3А: колоду переводит сервер, не клиент по `card.id`;
  - `AURAT-0168` (slave-1): спека v2 одобрена (`007-spec-v2`, `008-approval`), контракт `v0.28.0` заморожен, код
    пишется; в `aura-contracts` — ветка `feature/AURAT-0168-v0.28.0`, тега ещё нет. §2 спеки — устройство резолвера
    `?lang`, которое пишется здесь;
  - `AURAT-0049` (колода, сид, правила текста), `AURAT-0051` (расклад в чате, карта в истории);
  - глоссарий `AURAF-0023-glossary.md` + `aura-app/scripts/i18n/glossary.json` v2 (термины `tarot`, `tarot-card`,
    `tarot-spread`, таблица обращения).

Дальше: 003 — понимание.
