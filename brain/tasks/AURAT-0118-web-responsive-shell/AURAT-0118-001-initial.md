# AURAT-0118-001 — Initial (исполняется в `aura-web-manor`)

Date: 2026-10-21
Фича: `AURAF-0020` (веб-клиент), строка плана `AURAF-0020-008`. ID выдан в
`aura-app-manor/active-work.md` (новых не минтить).

## Слова владельца

> запускай 008 в свободном слейве aura-web

## Контекст из `aura-app-manor` (не слова владельца)

- Строка `AURAF-0020-008`, колонка UI: «На телефоне — нижние табы и шторки, на desktop —
  модальные окна и колонки; гость на `/chats`, `/sessions`, `/me` видит GuestGate без
  личных данных». Последняя незакрытая строка этапа 1 (MVP веба); после мёржа — ✓ в таблице.
- Часть оболочки уже есть: `src/app/guards/guest-gate.tsx`, `private-route.tsx`, табы и шапка
  в `src/app/layouts/app-layout/`. Начать с аудита: что из строки сделано, чего нет — по
  хендоффу (`README`, `STRUCTURE`, `NAVIGATION`, экраны `Aura Web - Screens Desktop|Phone.html`),
  брейкпоинты — с учётом расхождений из `AURAI-0007`.
- База: `develop` @ `2e9edd2` (после `AURAT-0117`).
- Строки — на 24 языка сразу (правило 9). Спека — владельцу до кода. Merge gate — только
  с разрешения владельца.

## Слот

`slave-2`, ветка `feature/AURAT-0118-web-responsive-shell` (master и missus);
master от `develop` `2e9edd2`, missus от `master` `c4b162e`.
(В `aura-app-manor/active-work.md` записано «slave-1 (`wts-run`)» — фактически slave-2.)
