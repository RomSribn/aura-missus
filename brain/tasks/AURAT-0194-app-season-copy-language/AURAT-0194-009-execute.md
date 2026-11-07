# AURAT-0194-009 — execute

Дата: 2026-11-07 · slave-2, `feature/AURAT-0194-app-season-copy-language` от `develop` `3bee447`. **Не закоммичено**,
всё застейджено (`git add -A` в слоте; brain — в manor missus, только папка задачи). По `007-spec-v2`.

Проверки в слоте (без стека): `npx eslint . --max-warnings 0` — чисто; `npx tsc --noEmit` — чисто (скрипта
`typecheck` в `develop` нет); `npx jest --no-watchman` — **233 набора, 3169 тестов, все зелёные**.

## Файлы

**Контракты:** `package.json` / lock → `#v0.30.0` (`npm install`, lock: 3 строки). В маноре после мёржа — `npm ci`.

**`entities/campaign`**
- `model/campaign-store.ts` — общий `ask(now)`: номер запроса `latest`, язык запроса `latestLanguage` (`null`, пока i18n не
  стартовал), ответ и 404 ложатся только у последнего; `inFlight` снимает только свой (`006` п. 1); `followLanguage(language,
  now)` — мимо `inFlight` и троттла, `lastAskedAt = now`; флаг `behindLanguage` — пока ответ за новым языком не лёг,
  `refresh()` спрашивает мимо минуты (`006` п. 2).
- `model/use-app-config-sync.ts` — `onLanguageChange` → `followLanguage`.
- `lib/copy-language.ts` (новый) — `textLanguageOf(code)`: `isLanguage` или `en`.
- `lib/hero-content.ts` — `SeasonHeroContent.language`; `{amount}` — `formatUsdMinorCompact(minor, language)`.
- `lib/ticket-content.ts` — `eyebrowLanguage` у всех четырёх ветвей; `{amount}` сезона — так же; JSDoc.
- `ui/SeasonHero.tsx` — `accessibilityLanguage={hero.language}` (+ `HeroCta.language`).
- `config/constants.ts` — `SEASON_COPY_LANGUAGE` удалён. `api/app-config-api.ts`, `config/locales/en.ts` — комментарии.
- `api/parse-app-config.ts` — `partOf` возвращает **выход** схемы (`z.output<S>`): с `default('en')` вход и выход
  разошлись, `tsc` падал.

**`shared/ui/offer/CampaignTicket.tsx`** — `CampaignTicketContent.eyebrowLanguage`; надзаголовок рисуется
`upperLabel(eyebrow, eyebrowLanguage)`, `accessibilityLabel` — обычным регистром. `textTransform` в `ticketText` оставлен
(его делит `CouponTicket`).

**`features/booking`**
- `model/use-pricing-follows-language.ts` (новый) — тихое перечитывание цены на `onLanguageChange`; ложится последний
  ответ у смонтированного хука; ошибка — ничего.
- Подключён в `use-booking`, `use-quick-booking` (`enabled` — цена есть), `use-booking-confirm` (только своя цена).
- `lib/block-discount.ts` — комментарий «English until AURAF-0023 step 5».

**Тесты:** `campaign-store` (+6: язык мимо запроса в пути и минуты; старый ответ последним — не рисуется и не кэшируется;
старый ответ первым — `refresh` присоединяется к новому, третьего нет; 404 старого не гасит сезон; ждём i18n — один
запрос; тот же язык — ничего; неудача за языком — повтор мимо минуты, потом троттл держит), `use-app-config-sync` (новый,
2), `use-pricing-follows-language` (новый, 5), `hero-content` (+2), `ticket-content` (+3, ожидания с
`eyebrowLanguage`), `parse-app-config` (+1: v0.30 и сервер до него), `SeasonHero` (+1), `offer` (+1: el капсом без
тонуса, a11y обычным регистром). Фикстуры: `winterSeason` — `copyLanguage: 'en'`, `winterDiscount` — `labelLanguage: 'en'`;
`use-booking-confirm.test` — `labelLanguage` в ценах.

## Решения при исполнении

- Новых строк для человека нет — переводы и `i18next/no-literal-string` не затронуты.
- Тесты «marked English» в `SeasonHero.test` оставлены: фикстура теперь говорит `copyLanguage: 'en'`, они проверяют то же
  самое.

## Открыто

- Проверка в маноре — `007` «Проверка в маноре», 7 пунктов (координатор). Зависит от текста живой кампании на bff-dev
  (владелец меняет свой текст на текст пресета).
- Известное ограничение (`007` §4): смена языка во время **первой** загрузки цены экрана.
