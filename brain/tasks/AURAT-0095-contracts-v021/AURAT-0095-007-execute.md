# AURAT-0095-007 — Исполнение (app, slave-1)

Дата: 2026-10-17
Ветка: `feature/AURAT-0095-contracts-v021` (`aura-app`), **не закоммичено** — на ревью владельца.
Гейты: `tsc` ✓, `eslint src` ✓, `jest` 123 / 871 ✓, prettier по изменённому файлу ✓.

## Что сделано
- `package.json` / `package-lock.json`: `@aura/contracts` `#v0.20.0` → `#v0.21.0`
  (resolved `0f35b76`). Обычный `npm install` lock не двигает — git-зависимость
  запинена; понадобился явный `npm install @aura/contracts@github:…#v0.21.0`.
  Других изменений в lock нет.
- `src/entities/wallet/api/wallet-api.ts`: удалены `WalletWithOffer` (схема + тип)
  и импорт `zod`; `fetchWallet(): Promise<WalletResponse>` → `WalletResponse.parse`.
  Комментарий про оффер сжат до двух строк в doc-блоке модуля.
- `wallet-store`, `use-first-session-offer`, тесты — без изменений: они читают
  `wallet.firstSessionOffer?.active / pct`, тип контракта идентичен.

## Сверка v0.21.0
- `FirstSessionOffer` = `{ active: boolean, pct: int 1..100 }`, optional — как было локально.
- `SessionPricing` — правки только в комментариях (`creditMinor` = скидка первой
  сессии); app уже трактует `creditMinor > 0` как «оффер применён».

## Открыто
- Отдельного теста на разбор `firstSessionOffer` в `fetchWallet` нет (стор-тесты
  мокают API) — не добавлял, поле теперь из контракта.
- Проверка на устройстве — в маноре после мёржа (поведение не должно измениться).
