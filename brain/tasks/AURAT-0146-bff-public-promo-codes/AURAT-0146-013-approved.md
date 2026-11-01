# AURAT-0146-013 — approved

Дата: 2026-11-01 · Слот: slave-1 · Ветка: `feature/AURAT-0146-public-promo-codes`

Владелец принял результат («Да, approved») после проверки на bff-dev (`-012`) и одобрил
`wts-release`.

## Итог

- BFF: публичные промокоды (`ed1fe6d`) и `@aura/contracts` v0.26.0 (`d6ceac6`) — в develop
  (`6741848`), выкачено на bff-dev.
- aura-contracts: `v0.26.0` (`98c859e`) на `main`, тег на GitHub.
- AURAF-0022: строки 001–002 — UI ✓ BE ✓.

## Остаётся вне задачи

- Перед выкладкой на main сверить `SESSION_SLOT_TIMEZONE` в Coolify (prod).
- Список «позже» из `-010` (рефакторинг сервиса и view, подписи UTC, `timeZone` из сервисов,
  спеки).
- `replayed` для публичного кода вживую не проверялся (покрыт юнит-тестами).
- Следом: AURAT-0147 (slave-2) перебазируется на v0.26.0 → contracts v0.27.0.
