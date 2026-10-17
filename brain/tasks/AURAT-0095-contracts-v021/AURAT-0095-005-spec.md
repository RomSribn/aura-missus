# AURAT-0095-005 — Спека

Тип: **task** (без feature-файла — техническое закрытие хвоста `AURAF-0017`).

## План
1. `package.json`: `@aura/contracts` → `github:RomSribn/aura-contracts#v0.21.0`;
   `npm install` → обновлённый `package-lock.json` (resolved → `0f35b76`).
2. `src/entities/wallet/api/wallet-api.ts`: удалить `WalletWithOffer` и импорт
   `zod`; `fetchWallet(): Promise<WalletResponse>` → `WalletResponse.parse(body)`.
   Комментарий про оффер сжать до одной строки-ссылки на контракт (или убрать).
3. Стор / хук / тесты — без изменений по логике; поправить только упоминания
   `WalletWithOffer` / «до v0.21.0» в комментариях, если есть.
4. Гейты: `tsc`, `eslint src`, `jest`.
5. Brain: строка в `active-work.md` → закрытие по аппруву.

## Вне рамок
- Барьер $10, iOS-проверка купона — отдельные хвосты `AURAT-0093`.
