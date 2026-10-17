# AURAT-0095-001 — @aura/contracts v0.21.0 вместо локального WalletWithOffer

Дата: 2026-10-17
Статус: **заведена**
Слэйв: `slave-1`, ветка `feature/AURAT-0095-contracts-v021` (`aura-app`, от `develop` @ `5428c49`)
ID выдан заранее в `active-work.md` (хвост `AURAT-0093`), новый не минтился.

## Слова владельца (близко к тексту)

> да, заведи и запусти в свободном слоте

Бриф из сессии манора, закрывшей `AURAT-0093`:
- поднять `@aura/contracts` в `aura-app` с `#v0.20.0` на `#v0.21.0` (тег из
  `AURAT-0094`, `aura-contracts` `0f35b76`; в нём
  `WalletResponse.firstSessionOffer?: { active: boolean; pct: number }`);
- убрать `WalletWithOffer = WalletResponse.extend(...)` в
  `src/entities/wallet/api/wallet-api.ts` — `fetchWallet` разбирает
  `WalletResponse` из контрактов;
- сверить поле и смысл с `wallet-store` (`firstSessionOfferPct = active ? pct : null`)
  и `useFirstSessionOffer`; проверить прочие изменения v0.21.0;
- `tsc` / `eslint` / `jest` — зелёные.

## Рамки
- Merge gate — только с явного подтверждения владельца.
- Brain — в манор-missus (у слота нет missus-worktree); коммит только своими
  путями (`git commit -- <paths>`), чужие staged файлы `AURAT-0080` не трогать.
