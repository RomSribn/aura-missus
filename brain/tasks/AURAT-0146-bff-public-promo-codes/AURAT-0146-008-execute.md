# AURAT-0146-008 — execute

Дата: 2026-10-31 · Слот: slave-1, `feature/AURAT-0146-public-promo-codes` · **не закоммичено, всё в stage**

## aura-bff (master)

**Схема и миграция** `prisma/migrations/20261031120000_public_promo_codes/`:
- `enum PromoBatchKind {SINGLE, PUBLIC}`, `promo_batches.kind` (default SINGLE, без бэкфилла),
  unique `(id, kind)`.
- `promo_redemptions.kind` (копия вида партии; default только для старых строк, сразу снят) +
  составной FK `(batchId, kind) → promo_batches(id, kind)` вместо `batchId → id` — запись с видом,
  не совпадающим с партией, невозможна.
- `promo_redemptions_codeId_key` → обычный индекс + частичный unique
  `promo_redemptions_single_use (codeId) WHERE kind = 'SINGLE'` (сырой SQL, как у сессий).
- Prisma: `PromoCode.redemption?` → `redemptions[]`. SQL написан руками (offline `migrate diff`
  в слоте ничего не выдал) по соглашениям имён Prisma — **на манор: `prisma migrate deploy` и
  `prisma migrate diff --from-migrations … --to-schema …` на dev-базе, дрейф должен быть только в
  частичном индексе.**

**Погашение** (`prisma-promo-codes.repository.ts`): код ищется с видом без замка; одноразовый —
`FOR UPDATE`, публичный — `FOR SHARE`. Повтор — по (партия, кошелёк) с проверкой кода; под замком
кошелька то же погашение того же кода = `replayed` (гонка двух запросов одного аккаунта), другого
кода партии = `campaign_used`. Ключ проводки `promo:<codeId>` не менялся (unique ledger — на кошелёк).
`normalisePromoCode` пропускает любые `A–Z0–9{4,20}`; 8-символьные коды — частный случай.

**Отключение**: публичный код отключается и после погашений (`disableBatch`/`disableCode`);
одноразовый погашенный — как раньше, «redeemed».

**Порог** (`sessions/session-price-floor.ts`, экспорт `SessionsModule`): `min(advisors.priceMinorPerMinute)`
по **всем** советникам (бронь `findById` не смотрит на `active`) × `min(SESSION_BLOCK_MINUTES)` с −50%.
Чистые функции `cheapestSessionSubtotalMinor` (без скидки — для 0147) и `cheapestSessionCostMinor`
в `session-policy.ts`. По умолчанию — $11.00.

**Бэкофис** (только вкладка «Промокоды», `layout.view.ts` не тронут): кнопка «Публичный код»,
`GET/POST new-public`, `POST confirm-public`, `POST public`. Подтверждение: код, «$N каждому
аккаунту, один раз», «без лимита», срок; если сумма ≥ порога (или порога нет) — предупреждение и
обязательная галочка `coversSession`, сервер её перепроверяет на создании (порог читается заново).
Занятое имя — ошибка поля (и на подтверждении, и при гонке на создании). Страница публичного кода —
код, погашений, начислено, «Отключить код»; без таблицы людей и CSV. Список/сводка: «публичный» +
имя, «N погашений», «Выпущено» — только одноразовые, «Активно» + «и N публичных кодов без лимита».

**Пояс срока (`-007`)**: срок **всех** партий вводится и показывается «до даты включительно» в
`SESSION_SLOT_TIMEZONE`, пояс подписан. `expiresAt` = полночь в поясе (`startOfZonedDay` в
`common/time/zoned-date.ts`, DST учтён, тесты NY). Аудит-времена (создана/погашен/отключена) — UTC,
как подписано в колонках. Старые партии не меняются.

**Прочее**: OpenAPI-описания redeem, `.env.example` / `env.schema.ts` — строка про пояс промокодов.

**Проверки в слоте**: `npm run lint`, `npm run typecheck`, `npx jest` — **132 suites / 1810 tests
passed**, `npm run build` — ок.

## aura-contracts (вне манора, ветка `feature/v0.26.0-public-promo-codes` от `main` @ 9848a02)

Только документация: `src/promo.ts` (два вида кодов, пояснения у `replayed`, `already_used`,
`campaign_used`, `expired`, `disabled`, у `code`), `README.md` (строка модуля + абзац v0.26.0),
`package.json` → 0.26.0. Zod-схемы не менялись. `typecheck` + `build` — ок. В stage, не закоммичено.
**Push `main` + тег `v0.26.0` — только по одобрению владельца**; после него BFF переводится на
`#v0.26.0` (`npm install` перепишет lock) — для сборки BFF это не обязательно (схемы те же).

## Открытое / на манор
- Миграция и все SQL-ветки (замки `FOR SHARE`/`FOR UPDATE`, частичный unique, составной FK) — только
  на живой базе.
- Сверить на проде `SESSION_BLOCK_MINUTES`, минимальную цену и `SESSION_SLOT_TIMEZONE` (форма покажет
  порог сама).
- Клиенты (`AURAT-0144`/`0145`) не трогались: шлют ввод как есть, все отказы публичного кода им известны.
