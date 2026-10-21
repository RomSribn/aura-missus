# AURAT-0100-004 — Context

Date: 2026-10-19

Проверено в коде (`develop` @ `bb00d30`):

- **Единственная таблица** — `src/modules/wallet/top-up-tiers.ts`
  (`TOP_UP_TIERS` + `creditForProduct`, защита `hasOwnProperty`, `Object.freeze`).
  Читают её только `PlayTopUpService` и `AppleTopUpService` через
  `creditForProduct`; неизвестный продукт → `BadRequestException('Unknown
  product')` до любых обращений к стору/БД.
- **Верификаторы** Play (`google-play.verifier.ts`, `fake-play.verifier.ts`) и
  Apple (`app-store-transaction.verifier.ts`) передают `productId` дальше и
  сверяют его с ответом стора; списка продуктов в них нет.
- **Возвраты и уведомления** (`play-refund.service.ts`, `apple-refund.service.ts`,
  RTDN, App Store Notifications) реверсят `creditedMinor` сохранённой покупки, а
  не значение из таблицы — расширение лестницы на них не влияет, прошлые покупки
  разбираются по своей записи.
- **Контракты** (`@aura/contracts`, `src/contracts/openapi.ts`): `productId` —
  свободная строка `min(1)`, перечня нет — менять нечего.
- **Сиды / миграции / env** — продуктов не перечисляют.
- **Тесты**, перечисляющие тиры: `top-up-tiers.spec.ts` (пинит ровно четыре —
  нужно переписать), `play-top-up.service.spec.ts` / `apple-top-up.service.spec.ts`
  (`it.each` по четырём; «чужой» продукт — `usd9999`, остаётся вне лестницы).
- Комментарий в `top-up-tiers.ts` говорит «four cards» / «the app's drives four
  cards» — обновить: копия в приложении теперь — четыре карточки + лестница.

Противоречий нет.

Next: 005-spec.
