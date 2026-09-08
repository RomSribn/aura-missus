# AURAT-0063-002 — Что уже есть

Дата: 2026-09-08
Слот: slave-2 · `feature/AURAT-0063-user-profile` (master от `develop` = `5d61207`,
missus от `master` = `e9b03a6`)

## В brain

Папка задачи существует и содержит ровно один файл — `AURAT-0063-001-initial.md`,
перенесённый из `aura-app-manor`. Это и есть спека: колонки, маршруты, валидация,
контракты, порядок. Продолжаю с `002`.

Ничего профильного в `brain/` этого клона больше нет: `AURAF-0015` и шаговые файлы
`AURAT-0062` лежат незакоммиченными в рабочей копии `aura-app-manor` (прочитаны
оттуда как справка — см. `004-context`). Ближайшие соседи по номерам —
`AURAT-0058/0059` (советники, тот же порядок половин) и `AURAT-0050` (гонка в
`ensureUser`, на которую опирается идентичность здесь).

## В коде (`aura-bff` @ `5d61207`)

Спека подтверждается ground truth:

- `prisma/schema.prisma`, `model User` — `id`, `firebaseUid`, `phoneE164`,
  `chatwootContactId`, `chatwootSourceId`, связи, `createdAt`/`updatedAt`.
  Ни `displayName`, ни `email`, ни `birthDate`, ни `marketingOptIn`.
- Контроллера `me` нет: `src/modules/` — `advisors`, `auth`, `chat`, `chatwoot`,
  `delivery`, `health`, `play`, `presence`, `sessions`, `tarot`, `wallet`.
  Модуля `profile` среди них нет.
- `src/contracts/` — восемь файлов, `profile.ts` отсутствует.
- `@aura/contracts` в `package.json` — `#v0.15.0`. Репозиторий
  `aura-contracts` живёт **вне манора** (`/Volumes/Work/personal/ai-manors/aura-contracts`),
  ветка `main` чистая, последний тег `v0.15.0`.
- `TECH-DEBT.md` #27 описывает ровно эту дыру («The app calls two endpoints this
  service has never had») и после задачи станет наполовину неверным.

## Что дальше

`003-understand` — разбор задачи; `004-context` — источники и находки, включая
две, которые уточняют спеку.
