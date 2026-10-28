# AURAT-0143-009 — Merge

Date: 2026-10-28

- `aura-contracts` (с разрешения владельца): `feature/v0.25.0-promo-codes` → `main` fast-forward
  `9848a02`, аннотированный тег `v0.25.0`, push `main` + тег. Ветка удалена.
- `aura-bff`: `1bfc7d5` — `@aura/contracts#v0.25.0` (`package.json` + lock, lock → `9848a02`).
  Условие владельца выполнено до мёржа: с нуля `npm ci` → `prisma generate` → build ✓, tsc ✓,
  lint ✓, jest 131 / 1749 ✓ — без скопированного `dist`.
- `wts-finish slave-1` (разрешение владельца): `feature/AURAT-0143-promo-codes` (`bd23cf3` +
  `1bfc7d5`) → `develop` @ `130fa9d`, push в origin ✓. Idle-слоты обновлены.
- Missus не закоммичен (коммит — при закрытии задачи).

Дальше — живая проверка манора на bff-dev (§7 спеки): миграция `20261027120000_promo_codes`,
вход в бэкофис, партия (подтверждение, двойная отправка), погашение и `PROMO_CREDIT`, повтор
своим / чужим, два погашения одного кода одновременно, `campaign_used`, 10 неверных → 429,
отключение кода и партии (галочка), лог без кода.
