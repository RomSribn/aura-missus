# AURAT-0123-009 — Execute (fix 008)

Date: 2026-10-23

- `src/pages/sessions/ui/sessions-page.module.css` — правило `.root:not(:has(> .panel))` с
  комментарием (одна колонка без панели).
- Проверки: prettier ✔, `npm run lint` ✔, тесты `shared/config` + `app/__tests__/sessions*` —
  77 ✔ (CSS-раскладку jsdom не проверяет — смотреть в маноре после мёржа: `/sessions` без сессий
  на desktop 1440 и на ~880px).
- Не закоммичено — ждёт ревью вместе с `007`.
