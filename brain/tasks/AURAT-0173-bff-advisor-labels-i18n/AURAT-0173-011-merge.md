# AURAT-0173-011 — merge

Дата: 2026-11-07

- Координатор (`slave-1-ac`) повторно проверил правки `010` — всё зелёное.
- Владелец одобрил выпуск контрактов → `aura-contracts` `main` `308b95e`, тег **`v0.29.0`** (`6311ab0`), запушено.
- BFF переключён на `@aura/contracts#v0.29.0` (lock → `308b95e`); typecheck / lint / build ✓, `npm test` 153 / 2044 ✓.
- Коммит BFF `8643880` в `feature/AURAT-0173-bff-advisor-labels-i18n`.
- Владелец одобрил мёрж → `wts-finish slave-1`: `develop` манора **`167f0b9`**, запушено (`bbc4c6c..167f0b9`). Missus — «no
  commits to merge» (как и должно: missus коммитится при закрытии). Свободные слоты обновлены.

## Проверка в маноре

1. migrate + seed — колонка `advisors.gender`, у Olivia `FEMALE`, у Labsang / Alisher / Ivan `MALE`; seed второй раз —
   без ошибок и дублей.
2. `GET /v1/advisors?lang=de` — Olivia «Hellseherin · Medium», Labsang «Medium · Hellseher», Ivan «Astrologe ·
   Kartenleger»; чипы по-немецки; `tagline` / `bio` / `greeting` — английские.
3. `?lang=el` — Veronica «Διορατική · Μέντιουμ · Ταρό»; `?lang=it` — «Tarocchi».
4. Без `lang` и `?lang=mt` при `DISABLED_LANGUAGES=mt` — английский; `topics` во всех языках одинаковы
   (Marta — `["LOVE"]`).
5. Гостем без токена — 200.
6. `npm run desk:setup` → описание `advisor_role` в Chatwoot новое; новый разговор — `advisor_role` по-английски;
   профиль советника в desk — по-английски.
