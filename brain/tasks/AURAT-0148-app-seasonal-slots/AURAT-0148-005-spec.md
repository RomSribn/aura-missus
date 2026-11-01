# AURAT-0148-005 — Спека: сезонные места в приложении

Дата: 2026-10-31 · Статус: **draft — ждёт одобрения владельца**
Фича: `AURAF-0022` строка 006 · Дизайн: `SEASONAL.md` (экраны 67–81) · Контракт: `AURAT-0147-007` + `-010`
Слот: `aura-app-manor` slave-1, `feature/AURAT-0148-app-seasonal-slots` от `develop` @ `234c500`.

## 0. Главное

- Клиент рисует сезон **из палитры** (17 токенов) и текстов с сервера; `preset` — только имя, на
  отрисовку не влияет. Без сезона (`season: null`, нет ответа, 404 у старого BFF) — всё как сейчас.
- **Анимация — встроенный `Animated` (`useNativeDriver`), без `react-native-reanimated`.** Так и
  предлагает `SEASONAL.md` §6; движения простые (падение, покачивание, поворот — по таймлайну),
  новая нативная зависимость в ту же сборку — лишний риск без выигрыша.
- **Кэш — JSON-файл через `@dr.pogodin/react-native-fs`** (уже в зависимостях). Ни MMKV, ни
  AsyncStorage не добавляем → в сборке нет нового натива.
- **До тега `v0.27.0`** — локальный тип и zod-схема, совпадающие со спекой 0147 **с правкой
  `-010`** (9 ключей `copy`, `promo.amountMinor`). После тега — замена на импорт из
  `@aura/contracts` (`AppConfigResponse`, `fillSeasonCopy`, `formatSeasonAmount`) в этой же ветке.

## 1. Данные — новый entity `entities/season`

| Сегмент | Что |
|---|---|
| `api/app-config-api.ts` | `GET /v1/app-config` без токена (в `shared/api/bff` — публичный вариант запроса). Разбор схемой: неверный ответ = «сезона нет», не падение. |
| `model/types.ts` | Локальный `AppConfig` по 0147 (до тега). `effect` и `preset` — строки. |
| `model/season-store.ts` | Модульный стор + `useSyncExternalStore`, как `wallet-store`. Состояние: последний конфиг + момент. |
| `model/use-season.ts` | `useSeason()` → `{ palette, art, copy, effect, promo, discount }` или `null`, с гашением каждой части по её `endsAt` (часы — `serverNow()`; таймер на ближайший `endsAt`). |
| `model/use-app-config-sync.ts` | Загрузка на старте и при возврате приложения на передний план (`AppState`), не чаще раза в 60 с (у сервера `max-age=60`). Подключается в `app/index.tsx` рядом с остальными `*Sync`. Не зависит от входа — конфиг публичный. |
| `lib/config-cache.ts` | Чтение/запись `DocumentDirectory/aura-app-config.json`. Читается при старте до сплэша; битый файл — удаляется. Кэш с истёкшим `endsAt` не показывается. |
| `lib/fill-copy.ts` | Подстановка `{code}` / `{amount}` / `{pct}`; `{amount}` — `$5`, с центами `$5.50` (как `formatSeasonAmount` из `-010`). После тега — функции контракта. |
| `lib/pick-ticket.ts` | Чистое правило «один билет» (§3). |
| `lib/prefetch-art.ts` | `Image.prefetch` для `art.hero` и `art.ticket` при новом конфиге. |

`billing` выключен → `promo` и `discount` уже `null` с сервера; клиент дополнительно не показывает
их при `BILLING_ENABLED=false`.

## 2. Hero на Home — `entities/season/ui/SeasonHero.tsx` + частицы

- Место: между шапкой и `DailyCardBanner`; отступы 16 / 12 (`SEASONAL.md` §1). Высота **164**,
  радиус 24, фон `linear-gradient(120deg, heroFrom, heroTo)` (через `shared/ui/gradient`) +
  встроенное белое свечение 16% → 0, Ø 220, снизу справа.
- Арт 132 × 132, справа −10, снизу −12, клип по углам; появляется opacity 400 мс после загрузки.
  Нет арта / не загрузился — только фон и свечение (экран 70).
- Колонка текста ≤ ширина − 118: заголовок Bricolage 800 20/22.4, 2 строки; текст Hanken 500
  13/17.5, 2 строки, многоточие. С кодом — `heroBody` + кнопка `cta` (высота 34, радиус 12, нажатие
  0.975); без кода — `heroBodyNoCode`, без кнопки (экран 69).
- Вход: opacity 0→1 + translateY 12→0, 320 мс ease-out; при Reduce Motion — только opacity.
- **Частицы** (`SeasonParticles`): 14 штук, слой между артом и текстом, детерминированный ГПСЧ с
  зерном, размеры / времена / покачивание / поворот / прозрачность — §6 таблицей; над колонкой
  текста × 0.45; цвет `effectTint`; формы — пути из `effects/*.svg` в `config/`. Один проход
  ≤ 12 с при каждом фокусе Home, без петли. Reduce Motion — частиц нет. Неизвестный `effect` — нет.
- Кнопка открывает `PromoCodeSheet` **с подставленным кодом** (экран 79). Шторку хостит Home.
- Новые токены размеров/движения hero — в `theme.ts` (`theme.season`), правило 3 build-rules.

## 3. Билет — `CouponTicket` получает варианты и сезонную кожу

- Геометрия и движение без изменений. Кожа (`ticketStub`, `ticketStubLabel`, `ticketSoft`,
  `ticketEyebrow`, тень `ticketStub` 22%, глиф `art.ticket` 23 pt; без арта — `percent` / `tag`)
  приходит пропом; без сезона — нынешние coral-цвета.
- Варианты: `welcome` (как сейчас), `discount` («20% OFF sessions», Auto-applied, экран 74),
  `code` («$5 on your balance», чип `[WINTER5]`, «Tap to apply ›», весь билет — кнопка → шторка с
  кодом; экраны 73, 80). «Auto-applied» / «You save» — teal всегда.
- Правило `pick-ticket` (§2 сдачи): бронь/оплата → welcome, если −50% активен, иначе ничего;
  иначе −50% активен и 50 ≥ сезонного % → welcome в сезонной коже (75); иначе есть скидка →
  discount; иначе есть код → code; иначе ничего.
- Где: Advisors (место `CouponTicket`), AdvisorProfile, PromoCodeSheet — по правилу; бронь
  (Book / Review / QuickBook) — только welcome в коже.

## 4. Орб, баннер, таб-бар

- `Orb` / `PulsingOrb`: кроме `coral` / `teal` — тон `{ base, soft }`. Сплэш берёт `orbBase` /
  `orbSoft` **из кэша прошлого запуска** (первый запуск сезона — coral, так задумано). Пульс 2.6 с,
  Reduce Motion — статично (уже так).
- `DailyCardBanner`: фон `150deg bannerFrom → bannerTo`; `bannerAccent` — eyebrow, рамки веера,
  звёзды боковых карт; искра центральной карты — gold; заголовок белый, подзаголовок 70%.
- `AuraTabBar`: `tabActive` — только активная иконка и точка.
- Всё остальное (paper, card, ink, цены, первичные кнопки вне мест, вся teal-семья) не меняется.

## 5. Шторка кода и пуш `promo`

- `usePromoCode(visible, onRedeemed, initialCode?)`: при открытии поле заполняется `initialCode`
  (иначе пустое, как сейчас). Остальное — как в `AURAT-0144`.
- Пуш: `action: 'promo'` + `code` → открывается Home и шторка с кодом (параметр маршрута Home).
  Без `code` — просто Home. Промо-пуши по topic ждут `AURAT-0140`; разбор действия едет в этой
  сборке, чтобы потом не ждать релиза.

## 6. Скидка в брони — после тега `v0.27.0`

`SessionPricing.blocks[].discount {kind, pct, label}`: при `kind: 'campaign'` подписи брони
(`DurationPicker`, `BookSessionScreen`, `BookReviewScreen`, `QuickBookSheet`) показывают
`label · pct% off` и **не** рисуют welcome-билет; при `first_session` — как сейчас; поля нет
(старый BFF) — нынешнее поведение (`offerPct` при `creditMinor > 0`). Это закрывает «известное
ограничение» `AURAT-0147-007` §3. Требует контракта (поле отбрасывается схемой 0.25), поэтому —
вторым этапом в этой же ветке.

## 7. FSD

`entities/season` (данные, `SeasonHero`, `SeasonParticles`, правило билета) ← `screens/home`,
`screens/advisors`, `screens/advisor-profile`, `screens/splash`, `features/promo-code`,
`features/booking`; `app/navigation/AuraTabBar` и `app/index.tsx` — через публичный API.
`shared/ui/offer/CouponTicket` и `shared/ui/orb` получают пропы, о сезоне не знают.

## 8. Проверки

- Слот: юнит-тесты — разбор конфига (неизвестные `effect`/`preset`, битый ответ, лишние токены),
  гашение по `endsAt`, кэш (запись/чтение/битый/истёкший), `fill-copy`, `pick-ticket` (все ветки,
  включая равенство 50), ГПСЧ частиц детерминирован и укладывается в 12 с, рендер hero (с кодом /
  без / без арта / Reduce Motion), билет в трёх вариантах и без сезона = как сейчас, `usePromoCode`
  с `initialCode`, `tapTargetFromData` с `promo`. `tsc`, `eslint`, jest.
- Манор после мёржа: сезон с bff-dev (кампания 0147 включена) — экраны 67–80 на устройстве; кэш
  холодного старта (сплэш); выключение кампании → места пропадают ≤ 60 с + до фокуса.

## 9. Порядок

1. Сейчас: §1–§5 на локальном типе (по `-010`).
2. Тег `v0.27.0` → переход на контракт + §6.
3. Мёрж — после тега и проверки в маноре на bff-dev с 0147. **Если тег не успевает к сборке
   ~15.11** — мёржим §1–§5 на локальном типе (разбор совпадает со спекой), переход и §6 — следом.

## Решения в спеке (поправь, если не так)

1. `Animated` вместо Reanimated; кэш в файле через `react-native-fs` — новых нативных зависимостей нет.
2. Локальный тип — по правке `0147-010` (9 ключей `copy`, `amountMinor`), хотя она ещё не одобрена.
3. Шторку кода из hero и пуша хостит Home; пуш `promo` + `code` ведёт на Home.
4. Билет в брони — только welcome; скидка кампании в брони — подписью, не билетом.
5. Конфиг тянется на старте и при возврате на передний план (≥ 60 с между запросами), без опроса.
