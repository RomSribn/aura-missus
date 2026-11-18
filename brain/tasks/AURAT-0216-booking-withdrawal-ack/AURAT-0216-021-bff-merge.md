# AURAT-0216-021 — BFF: merge в `develop`

Дата: 2026-11-18. Владелец: «Да, мёрж». `wts-finish slave-1`.

- Ветка `feature/AURAT-0216-booking-withdrawal-ack` → `develop` манора `df94915`
  (`Merge feature/AURAT-0216-booking-withdrawal-ack`), push `cd0975b..df94915` на origin — успешно.
- Missus: «Already up to date» (брейн не закоммичен — так и должно быть); предупреждение «missus push
  failed» — манор-missus не впереди origin (`behind 2`), ничего не потеряно. Перед `wts-release`
  подтянуть его с origin.
- Слот остаётся на ветке для шагов после merge.

## Дальше

1. Выкат `develop` `df94915` на bff-dev (владелец) — миграция `20261118150000_consents`; выключатели
   по умолчанию: `WEB_CONSENT_REQUIRED=false`, `STRIPE_TERMS_CONSENT` без изменений.
2. Проверка в маноре по `014` (миграция, `CHECK`, триггер; записи брони / «сейчас» / продления;
   приложение без согласия; `WEB_CONSENT_REQUIRED=true` и `STRIPE_TERMS_CONSENT=client` на sandbox) —
   можно вместе с веб-частью.
3. Координатор запускает веб (`AURAT-0218`, aura-web-manor slave-2) и приложение на контрактах
   `v0.35.0`.
