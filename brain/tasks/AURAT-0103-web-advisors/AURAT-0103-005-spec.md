# AURAT-0103-005 — Spec: каталог и профиль советника для гостя

Date: 2026-10-20
Type: task (строки `AURAF-0020-001`, `-002`, колонка UI). Новой фичи нет.
Status: done 2026-10-20 (`013`)

## Цель

Гость (и вошедший) открывает `/advisors` и `/advisors/:id` в aura-web и видит то, что
BFF отдаёт ему после `AURAT-0102`: каталог одним `GET /v1/advisors` на оба экрана, цену
блоков с оффером и ближайшие слоты. Фильтры и сортировка — на клиенте, в URL. На
телефоне Filters — шторка; «Назад» сначала закрывает открытый диалог.

## Что делаем

### 1. Данные

- **`entities/advisor/api`** — `getAdvisors` (`injectEndpoints`, `GET /v1/advisors`,
  `AdvisorsResponse.parse` в `transformResponse`), тег `Advisor`. Профиль берёт персону
  из того же кэша (`selectFromResult`), отдельного запроса нет. Неизвестный `:id` при
  загруженном каталоге → «советник не найден» (EmptyState + «See all advisors»).
- **`entities/session/api`** — `getSessionPricing(advisorId)` и
  `getAvailability({advisorId, minutes, days, tz})`, `SessionPricing.parse` /
  `AvailabilityResponse.parse`. Сейчас один потребитель (профиль), дальше — Book sheet и
  Quick book; это бронируемое время и цена сессии, поэтому entity `session`, не feature.
  Availability запрашивается после pricing: `minutes` = самый короткий блок из ответа,
  `days` = 7, `tz` = зона браузера. Pricing 404 (биллинг выключен) → нет цены блоков,
  слотов и оффера, availability не запрашивается.
- Ошибка каталога → EmptyState «Couldn't load advisors · Try again» (refetch). Ошибка
  pricing/availability, кроме 404, → блок Next available не рисуется, цена — простая
  ставка в минуту.

### 2. Оффер (−50%) — см. решение 1

- `shared/ui`: **`PriceTag`** (зачёркнутая цена + коралловая цена оффера, без оффера —
  простая), **`OffChip`** («−50%»), **`CouponTicket`** (teaser «Half price with {name} ·
  no code needed» / «… any advisor»). Все трое ничего не рисуют при `offerPct = null` —
  вызовы безусловные, как в приложении. Деньги — `Intl.NumberFormat` (USD) в текущем языке.
- Цена оффера в минуту — `discountedMinor(price, pct)` (порт, `floor`, как BFF).
- Источник `pct` — по решению 1.

### 3. Каталог `/advisors` — `pages/advisors` + `features/advisor-filters`

- Заголовок «Advisors» + «N advisors» + teaser-купон. Чипы: All · Love · Tarot · Psychic
  (из `AdvisorCategory`; Dreams / Career / Astrology не рисуем — их нет в данных).
- Рейл фильтров (desktop, sticky): **Price per minute** — двойной слайдер (две
  `input[type=range]`, границы = min/max каталога, шаг $0.10), **Rating** — Any / 4.8+ /
  4.5+ (радио), **Reset filters**. Availability (онлайн), Reading style, Language — не
  рисуем: полей нет (`AURAT-0102-006`).
- Results bar: «N advisors», Sort (Recommended = порядок сервера · Rating · Price ↑ ·
  Price ↓ · Most reviews; нативный `<select>`), grid ⇄ list (desktop; выбор хранится в
  `localStorage` браузера, в try/catch; телефон — только grid 2-up).
- Сетка 4-up / список; страница 24 + «Show more advisors» (скрыта, когда показано всё
  или 0). Смена фильтров сбрасывает страницу.
- Пустой результат: EmptyState «No advisors match · Try another category or loosen the
  filters · See all advisors» → `/advisors` без параметров.
- Фильтрация и сортировка — чистая функция `filterAdvisors(advisors, search)` в
  `features/advisor-filters/lib` (с тестами). Сортировка устойчивая; Rating — по
  `ratingTenths`, при равенстве по `reviewsCount`.
- **URL-контракт** (`shared/config/routes.ts`, расширяем `AdvisorsSearch`):
  `?cat=love&sort=rating&pmin=150&pmax=250&rating=48` (цены — центы, рейтинг — десятые;
  неизвестные/битые значения игнорируются). Изменения фильтров пишутся с `replace` —
  «Назад» уводит со страницы каталога, а не листает состояния фильтров.
- **Телефон**: кнопка **Filters** → `openDialog({kind: 'filters'})` → Sheet с тем же
  телом фильтров, применяются сразу; «Show N advisors» закрывает. Регистрация `filters`
  в `app/config/dialogs.ts`.

### 4. Плитка и строка — `entities/advisor/ui`

- **AdvisorTile**: фото (`avatarUrl`; пока грузится или при ошибке — монограмма на
  тинте `monogramTint(name)`), рейтинг, имя + OffChip, `role · N reviews`, PriceTag /min.
  **AdvisorRow** (list): фото, имя, tagline, до 3 специализаций, рейтинг (N), PriceTag.
  Онлайн-бейджа нет (гостю не показываем, вошедшему — с задачей чата).
- Вся карточка — ссылка на `/advisors/:id`. Кнопки **Chat free** / **Book** — слот
  `actions` (entity не знает про gate); что они делают — решение 2.
- Строки — `React.memo`, стабильные ключи.

### 5. Профиль `/advisors/:id` — `pages/advisor`

- «← All advisors» (ссылка на `/advisors`); фото, имя, tagline, role; статистика —
  рейтинг · N reviews (readings и years не рисуем — полей нет; Online / Verified тоже).
- Specialties (теги), About (`bio`), Reviews: заголовок «Reviews · 4.9 from 12», 3
  карточки + «Show all N reviews» → весь список на месте, по 24 + «Show more». Карточка
  отзыва: монограмма, имя (или «Anonymous · Verified client»), звёзды, цитата (пустая —
  без строки цитаты). Без даты (её нет на проводе намеренно). Отзывов 0 — секции нет.
  **Write a review** не рисуем (этап 2).
- Sticky-карточка (desktop): «Private paid chat» + OffChip, PriceTag /min,
  **Next available** — 4 ближайших свободных слота (позже серверного «сейчас»), подпись
  дня Today / Tomorrow / день недели + время (`Intl`, зона браузера), «All dates & times
  →», **Book session**, **Free chat**, заметка «Free cancellation up to 24 h before ·
  reschedule free up to 4 h before»; под ней teaser-купон.
- Биллинг выключен (pricing 404): нет Next available, All dates, Book session, купона и
  OffChip; остаются ставка в минуту и Free chat.
- **Телефон**: sticky-карточка и купон скрыты; фиксированный action bar «PriceTag +
  Book session» (биллинг выключен — «Free chat»); таб-бар скрыт (`handle.pushed` уже есть).

### 6. «Назад» закрывает диалог (NAVIGATION §5, открытый пункт `AURAT-0101-016`)

В `app/dialog-host`: при открытии диалога — запись в историю на тот же URL с пометкой
в `state`; «Назад» (popstate без пометки при открытом диалоге) → `closeDialog()`;
закрытие × / Esc / scrim → шаг назад по своей записи. Смена фильтров внутри шторки
идёт `replace` и пометку сохраняет. Работает для всех будущих диалогов.

### 7. Порт из aura-app (копией с тестами, шапка `// Ported from aura-app <path> (<ID>)`)

Только то, что нужно экранам:
- `entities/advisor/lib/rating.ts` — `ratingFromTenths`;
- `shared/lib/format.ts` — `discountedMinor`;
- `shared/lib/dates.ts` — `daysUntil`, `localDateKey`;
- `shared/lib/time-zone.ts` — `deviceTimeZone`;
- `shared/lib/monogram-tint.ts` — хеш как есть; тинты — токены `--mono-1…6` в `tokens.css`;
- `entities/session/lib/slots.ts` — `nextFreeSlot` → `nextFreeSlots(availability, now,
  count)` (та же логика, N слотов вместо одного).

**Отличие от приложения (по правилам веба):** подписи (`$1.99`, «Today», «Jan»,
время) не переносим ручными английскими строками — деньги и даты через `Intl` в текущем
языке, слова — ключи i18n. Арифметика и правила (`floor`, серверные часы, локальный
день) — один в один.

### 8. Строки

Новые namespace: `advisor` (entity), `session` (entity, подписи дней), `advisor-filters`,
`advisors` (page), `advisor-page` (page) и дополнения `shared` (PriceTag/OffChip/Coupon,
`aria-label`). Все — на английском и сразу на 23 языка ЕС (правило 9). Названия
категорий — ключи, не значения enum.

## Тесты

- Порты (rating, discountedMinor, dates, time-zone, monogram-tint, nextFreeSlots).
- `routes`: разбор и сборка новых параметров, битые значения.
- `filterAdvisors`: категория, цена, рейтинг, каждая сортировка, устойчивость.
- Источник оффера (по решению 1).
- `entities/advisor/api`: `parse` ответа, отказ на битом ответе.
- Страница каталога (store с подставленным ответом): чипы → URL, пустое состояние и
  «See all advisors», «Show more», Filters → диалог, «Show N advisors».
- Профиль: неизвестный id → not found; pricing 404 → нет Book и купона; 4 слота.
- DialogHost: «Назад» закрывает диалог и остаётся на странице; × — шаг назад.

Зелёные `npm run lint && npm run typecheck && npm test && npm run build`. Живая проверка
(гость без токена, CORS, цены и слоты с bff-dev) — в маноре после merge `AURAT-0102`.

## Вне задачи

Home `/`, вход и gate с resume (строки 003–004), Book sheet и оплата (строка 006),
Write a review (этап 2), онлайн-статус (WS, задача чата), `/match`, кошелёк вошедшего.

## После задачи (brain)

`AURAF-0020`: UI ✗ → ✓ в 001 (без «онлайн» и «язык» — по `AURAT-0102-006`) и 002.

## Решения для владельца

1. **Откуда оффер у гостя.** Кошелька у гостя нет, `pct` на проводе для него нет.
   - **(рекомендую)** Из ответа pricing: оффер активен, если хоть у одного блока
     `creditMinor > 0`, `pct = round(100 · credit / subtotal)` самого длинного блока.
     Профиль — pricing этого советника; каталог (плитки, купон) — pricing первого
     советника каталога: один кэшированный запрос, оффер — свойство человека, а не
     советника. Вошедший получает тот же ответ со своим кредитом (0 после использования),
     так что до задачи кошелька картинка верна и у него; с задачей входа/кошелька —
     `wallet.firstSessionOffer` по правилу 7.
   - Каталог без оффера (простые цены, без купона), оффер только в профиле.
   - Отдельная задача contracts + BFF: публичный оффер (поле в `SessionPricing` или
     `GET /v1/offer`); до неё у гостя простые цены везде.
2. **CTA до задач входа и брони.**
   - **(рекомендую)** Ссылки по URL-контракту: **Free chat / Chat free** →
     `/chats/:advisorId` (гость видит GuestGate); **слот / Book session / All dates /
     Book** → `/advisors/:id?book=1[&slot=…]`. До задачи брони диплинк ничего не
     открывает; задача входа повесит gate на диплинк (данные resume — уже в URL), задача
     брони откроет по нему Book sheet. Обработчиков-заглушек нет.
   - Не рисовать Book-CTA и слоты кликабельными до задачи брони (слоты — только
     информация, action bar на телефоне — «Free chat»).
