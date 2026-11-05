# AURAT-0162-009 — merge

Дата: 2026-11-05. Владелец одобрил мёрж через AskUserQuestion — дважды: сначала я ошибочно написал «без push»,
переспросил с точным описанием (wts-finish пушит develop) — «Да, wts-finish с push».

- `bin/wts-finish slave-1` → aura-app `develop` @ `7f58117` (Merge feature/AURAT-0162-app-i18n-auth; в ней `8fd2f09`
  и `aeec786` — develop с AURAT-0161, конфликт `.eslintrc.js` разрешён в ветке). Push `d361bce..7f58117` в origin.
- slave-0 обновлён скриптом; slave-1 остаётся на ветке для документов после мёржа.

## Дальше — проверка в маноре
- `npm ci` в маноре (зависимости не менялись, но после мёржа — по правилу).
- Dev-меню → язык / псевдоязык: сплэш, слайды (de, fi, hu, el, ga, pl), экран телефона (заголовок; de / es на 360 dp),
  «Sent to … · change», лист стран (порядок, ga / mt, поиск «osterreich», «ŁOTWA», «germany» — Android release с R8),
  «нет SMS» (вставить +90…, +1 809…).
- После одобрения владельца — `NNN-approved.md`, коммит brain, `wts-release slave-1`.
