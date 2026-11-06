# AURAT-0168-002 — check

Дата: 2026-11-06

- Папка задачи есть: `001-initial.md` — заглушка координатора (`aura-app-manor`, slave-1-9e) с картой кода и словами
  владельца. Других шагов нет — задача свежая.
- Слот: `slave-1` был в detached HEAD при строке `busy` в `active-work.md` → `wts-start slave-1
  feature/AURAT-0168-bff-i18n-lang-marker` (master `develop` @ `c8d78cf`, missus `master` @ `3bb7889`).
- `npm ci && npx prisma generate` в `slave-1/master` — ок (контракты в `node_modules` теперь `v0.27.0`).
- Соседние заглушки: `AURAT-0169` (приложение), `AURAT-0170` (веб), `AURAT-0171` (колода таро) — ждут спеку этой
  задачи; их ожидания от `lang` / `LANGUAGES` / `marker` учтены в спеке.
- Фича: `AURAF-0023` строка 009; расследование `AURAI-0010` §6 и Recommendation п. 5.
- Контракты: `/Volumes/Work/personal/ai-manors/aura-contracts`, `main` @ `8699e32` (`v0.27.0`), чисто.
