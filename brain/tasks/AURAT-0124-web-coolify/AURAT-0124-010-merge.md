# AURAT-0124-010 — Merge

Date: 2026-10-23

- Владелец подтвердил мёрж («Да, мёрж»). До коммита: манор проверил живой контейнер — 404 на
  чанк без `immutable`, остальное как надо; в тот же коммит — перенос строки 3 `Dockerfile` и одна
  проверка `VITE_BFF_WS_PATH` (`^/[^[:space:]]*$`, правило `env.ts` один в один).
- Код: `49d3422` на `feature/AURAT-0124-web-coolify`; `wts-finish slave-1` → develop `280988a`,
  push `d74e14a..280988a develop -> develop` — это первый деплой aura-web на
  `https://web-dev.aura-app.cc` (auto-deploy Coolify).
- Missus не закоммичен (коммит — при закрытии задачи).

## Живая проверка (манор, после деплоя)

Список — спека `005`, «После мёржа». Вход и запросы к BFF — после `AURAT-0125` и Authorized
domains в Firebase (владелец).
