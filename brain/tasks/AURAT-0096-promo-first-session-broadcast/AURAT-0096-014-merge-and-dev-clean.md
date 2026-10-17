# AURAT-0096-014 — merge «без метки» + чистка dev

2026-10-17, с подтверждения владельца: `7dc6d3a` → `develop` @ `bce50b6`, запушено; `bff-dev`
выкатился (`mtnsnawmogikfwm0uvl1g1yc-190436853375`, образ `bce50b6`).

- Chatwoot аккаунт 2: метка `promo-first-50` удалена на уровне аккаунта (id 3) — Chatwoot снял её
  и с диалогов 10, 16, 23, 25 (проверено поштучно). Остался только `paid-session`.
- `--dry-run`: `recipients 7 · skipped: 4 already sent, 3 offer used · would send 0` — «уже
  отправлено» берётся из store, как задумано.

Дальше — релиз `develop` → `main` (отдельное «да»), затем прод.
