# AURAT-0102-008 — fix: allowlist origins

2026-10-20. Владелец на ревью: allowed origins пока только `http://localhost:5173/`
(Vite dev-сервер aura-web).

Сделано:
- `.env.example` — `WEB_ALLOWED_ORIGINS=http://localhost:5173` (было пусто).
  Хвостовой `/` из слов владельца схема срезает сама — `http://localhost:5173/`
  тоже валидно.
- `deploy/env/bff.env.example` (прод) — пусто, веб-доменов ещё нет.
- Живой `.env` манора (gitignored) — ту же строку добавить в маноре при
  проверке после merge, иначе локальный стек CORS не включит.
