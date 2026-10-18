# AURAT-0098-002 — Проверка состояния

Дата: 2026-10-18
Слот: `slave-1`, ветка `feature/AURAT-0098-bff-message-delete` (Case B без бампа
счётчика — ID выдан в `aura-app-manor`). `aura-bff` от `develop` @ `3cab10c`,
`aura-missus` от `master` @ `3073093`.

- В общем мозге (`aura-missus` манора) папки `AURAT-0098-*`, `AURAT-0097-*` и
  `AURAF-0018-*` ещё нет — они лежат только в клоне `aura-app-manor` и не
  запушены. `001-initial.md` скопирован оттуда без изменений; `AURAF-0018` и
  `AURAT-0097-*` здесь не дублируются (их пушит app-манор), читаются по
  абсолютным путям.
- `aura-contracts` (`/Volumes/Work/personal/ai-manors/aura-contracts`, `main`) —
  чистый, на `v0.21.0` (`0f35b76`), совпадает с `origin/main`.
- Свежая задача: в BFF удаления нет (`webhook-events.ts` отбрасывает
  `message_updated`).

Дальше — понимание и контекст.
