# AURAT-0147-009 — Execute (часть 1: всё, что не зависит от AURAT-0146)

Дата: 2026-10-31
Слот `slave-2`, ветка `feature/AURAT-0147-bff-campaigns-app-config`. Ничего не закоммичено (ревью владельца).

## `aura-contracts` `v0.27.0`

Отдельный git worktree `/Volumes/Work/personal/ai-manors/aura-contracts.worktrees/v0.27.0-campaigns`,
ветка `feature/v0.27.0-campaigns` от `main` @ `v0.25.0`. Ничего не закоммичено и не запушено.
- `src/app-config.ts` (новый): `AppConfigResponse` / `AppConfigSeason` / `AppConfigPromo` /
  `AppConfigDiscount`, `SeasonPalette` (17 токенов, `#RRGGBB`), `HexColor`, `SEASON_TOKENS`,
  `SEASON_EFFECTS`, `SEASON_COPY_LIMITS` (28 / 60 / 16 — уточнить по `SEASONAL.md` до тега),
  `seasonCtaLabel`. `preset` и `effect` — строки, не enum.
- `src/season-contrast.ts` (новый): `SEASON_CONTRAST_PAIRS` P1–P18 как в брифе, `checkSeasonPalette`,
  `seasonPalettePasses`, `contrastRatio`, `relativeLuminance`, `compositeOver`. Сверено с числами
  брифа: coral на card — 3,26, на таб-баре — 2,84.
- `src/session.ts`: `SessionPriceDiscount`, `SessionPricing.blocks[].discount` (optional, nullable).
- `index.ts`, `package.json` 0.27.0, README (строки модулей + абзац `v0.27.0`). `tsc` + `tsup` — ок.
- В BFF собранный `dist` скопирован в `node_modules/@aura/contracts` слота. `package.json` BFF ещё
  на `#v0.25.0`.

## `aura-bff`

Данные:
- `prisma/schema.prisma`: `Campaign`, `CampaignEvent`, enum `CampaignStatus` и `CampaignEventAction`,
  `Session.discountCampaignId` (FK, nullable), `PromoCode.campaigns`.
- `prisma/migrations/20261031130000_campaigns/migration.sql`: только добавления. CHECK на окно и
  на 5–70%, append-only-триггер журнала.
- Env: `CAMPAIGN_ASSETS_BASE_URL` (необязательная), `.env.example`.

Цена (`sessions`):
- `session-discount.ts` (новый): `priceBlock` — большая из оффера и кампании (сравнение в центах
  на блок, при равенстве — кампания), `campaignDiscountMinor` (floor в пользу клиента).
- `getPricing` и `book` читают `CampaignDiscounts.active(now)` из базы. Репозиторий получает цену
  для обоих случаев (`offerAvailable` / `offerUsed`) и под замками выбирает нужную, пишет
  `discountCampaignId`.
- `firstSessionOfferUsed`: добавлено `discountCampaignId: null`. Бейдж «первая сессия» в столе
  (`listAdvisorBookings`) — тоже без кампаний.
- `session-policy.ts`: комментарий ссылается на `AURAD-0022`. Удалена `discountForBooking`, она
  больше нигде не используется.

Модуль `src/modules/campaigns/` (новый):
- `campaign-rules.ts`: пределы, формат ключа картинки с версией, `overlapConflicts` по частям,
  длина кнопки с кодом.
- `campaign-draft.ts`: разбор формы. Дни переводятся в полночи `SESSION_SLOT_TIMEZONE` через
  `startOfZonedDay` — тот же хунк, что в 0146, байт в байт.
- `campaign-preset.ts`: импорт `presets/<id>.json` (17 токенов строго).
- `campaign-enable-check.ts`: блокеры включения в виде данных.
- `campaigns.repository.ts`, `prisma-campaigns.repository.ts`: создание (`creationKey`), правка
  (только черновик и выключенная), включение (advisory-lock → замок строки → версия → пересечения →
  запись → журнал), выключение. В журнал пишется снимок кампании.
- `campaign-discounts(.module).ts`, `prisma-campaign-discounts.ts`: порт активной скидки для
  `sessions`, отдельный модуль, чтобы не было цикла.
- `app-config.builder.ts`, `app-config.service.ts` (кэш 30 с, сброс при переключении, не дольше
  ближайшего `endsAt`), `app-config.controller.ts` (`@Public`, `Cache-Control`, слабый ETag, 304).
- `campaigns-admin.service.ts`: сохранение (код витрины ищется и проверяется: существует, не
  отключён, живёт до конца окна; ошибка называет оба дня и пояс), страница, проверка, включение
  с версией, выключение, сброс кэша.
- `promo-codes/promo-code-lookup.ts`: поиск кода по тексту, экспорт из `PromoCodesModule`.

Бэкофис:
- `backoffice-campaigns.controller.ts`: список, новая, импорт пресета, создание, страница,
  правка, подтверждение и включение, подтверждение и выключение. Гарды `SameOriginGuard →
  BackofficeSessionGuard`, не за биллингом.
- `views/campaigns.view.ts`: форма (17 полей палитры с образцами цвета, части за биллингом,
  картинки только при бакете), страница (таблица контраста, превью `app-config`, журнал),
  подтверждение обычными словами (блокеры — без кнопки).
- Вкладка «Кампании» в `layout.view.ts` (видна всегда), `campaignsChrome`, формы в
  `backoffice.forms.ts`, стили в `backoffice.css`.
- `contracts/app-config.ts` ре-экспорт, OpenAPI `appConfigResponseOpenApi` + `discount` в pricing.
- README: дерево модулей, `GET /v1/app-config`, цена, вкладка.
- `tsconfig.build.json`: исключены `**/*.spec-fixtures.ts` (общие фикстуры спек кампаний).

Тесты (новые): контракт и контраст, `session-discount`, правила, разбор формы, пресет, проверка
включения, сборка `app-config`, кэш, ETag/304, сервис администрирования, транзакции репозитория,
вью, HTTP smoke вкладки и `app-config`. Правка: `sessions.service`, `prisma-sessions.repository`,
`first-session-offer.query`, `session-policy`.

Проверки: `tsc` ✓, `eslint` на изменённом ✓ (по всему `src` одна старая ошибка `desk.js`, не моя),
`prettier` на новых и тронутых ✓, `nest build` ✓ (фикстур в `dist` нет), jest — 144 сьюта /
1846 тестов ✓.

Brain: `decisions/AURAD-0022-seasonal-discounts-and-palette-as-data.md` (новый), спека v2
сверена с кодом 0146 (§1, §4, §9).

## Решения по ходу

- Окно задаётся днями «с … по … включительно» в `SESSION_SLOT_TIMEZONE`, как срок кодов в 0146.
- Включение с версией (`updatedAt` со страницы подтверждения): если кампанию изменили после
  подтверждения, отказ `stale` — оператор включает только то, что видел.
- Предохранитель в `app-config`: даже включённая часть не отдаётся, если сегодня не прошла бы
  проверку (палитра не держит контраст, код отключён или истёк).
- Блокеры приходят из домена как данные, текст для оператора пишет вью.

## Осталось — после мёржа `AURAT-0146` в `develop` (часть 2)

1. Влить `develop` в ветку. Миграция `campaigns` уже идёт после `public_promo_codes` по времени
   (`20261031130000` > `20261031120000`).
2. Витрина — только `kind = PUBLIC` (`PromoCodeLookup` + блокер включения + фильтр в `app-config`).
   Нормализация vanity-кода (`WINTER5`) приходит из 0146 сама.
3. Порог: процент кампании в `SessionPriceFloor`. Включение кампании со скидкой ищет живые
   публичные коды ≥ порога → предупреждение + галочка «понимаю: код оплатит сессию целиком»
   (проверка на подтверждении и на записи). Обратная сторона: форма публичного кода 0146 учитывает
   включённую скидку, окно которой пересекает срок кода.
4. Контракты: перебазировать `feature/v0.27.0-campaigns` на `v0.26.0`. Push `main` и тега
   `v0.27.0` — только с одобрения владельца. После тега в BFF поставить `#v0.27.0`.
5. `AURAF-0022`: отметить BE строк 003–005.
