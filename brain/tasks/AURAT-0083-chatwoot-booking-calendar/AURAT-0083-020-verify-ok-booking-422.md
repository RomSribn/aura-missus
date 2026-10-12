# AURAT-0083-020 — виджет работает; ошибка брони у второго пользователя — не 0083 (2026-10-12)

Владелец: вкладка «Aura» в «Aura Dev» добавлена, «все норм» (шаги 3–4 ✓).

Попутно: вошёл другим пользователем, пополнил баланс, бронь в свободный слот
рядом с бронью первого пользователя → в приложении «that didn't go through».

Разбор (логи dev-BFF `mtnsnawmogikfwm0uvl1g1yc-164001704176`, SSH как в `019`):
- каждый `POST /v1/advisors/olivia/sessions` → 500;
  `ChatwootApiError 422 on /api/v1/accounts/2/contacts` из
  `ProvisioningService.ensureChatwootIdentity` ← `ensureConversation` ←
  `SessionsService.book`. До слота и денег дело не доходит.
- dev-БД: у нового пользователя (создан сегодня, контакта нет) тот же номер,
  что у двух прежних строк `users` (2026-08-19 с `chatwootContactId=1`,
  2026-08-28 без контакта).
- Chatwoot аккаунт 2: номер держит контакт #1 со старым identifier → создание
  нового контакта с тем же номером → 422 «Phone number has already been taken».

Это **TECH-DEBT #34**, чинится в **AURAT-0085** (slave-3, `007-execute`, ждёт
ревью/мержа). К виджету и к броням не относится; данные не менялись.
