# AURAT-0103-001 — Initial (заглушка; исполняется в `aura-web-manor`)

Date: 2026-10-20
Выдан в `aura-app-manor` для `AURAF-0020` (веб-клиент), этап 1 — строки 001 и 002
scope (колонка UI), шаг «Advisors» плана `AURAI-0007` (порядок — Р5 `AURAD-0019`).
Опирается на каркас `AURAT-0101` (`develop` @ `9d2aa22`) и гостевой доступ BFF
`AURAT-0102` (спека `005`, ответы владельца `006`).

Что нужно: гость открывает каталог и профиль советника — NAVIGATION §2.6, §2.7,
README §3, §5, §6 веб-хендоффа.

- **Данные.** Один `GET /v1/advisors` (`@Public`) на оба экрана: профиль берёт
  персону из того же кэша RTK Query, `GET /advisors/:id` нет (`AURAT-0102-005` §4);
  неизвестный `:id` → NotFound. Цена блоков — `…/:id/sessions/pricing`, слоты —
  `…/:id/sessions/availability`: без токена — гостевой ответ (цена с оффером,
  занятость только советника); без биллинга — 404 → нет цены блоков и слотов,
  остаётся ставка в минуту. У этих двух эндпоинтов будет 2+ потребителя (профиль,
  Book sheet, Quick book) — место по скиллу `fsd`. Ответы — `parse` схемами
  `@aura/contracts` v0.22.0.
- **Каталог `/advisors`.** Чипы категорий, фильтры (цена, рейтинг), сортировка
  (Recommended = порядок сервера, Rating, Price ↑/↓, Most reviews), grid ⇄ list на
  desktop (телефон — grid 2-up), страница 24 / «Show more», пустое состояние.
  Фильтрация на клиенте; фильтры и сортировка — в URL через контракт
  `shared/config/routes.ts` (сейчас там только `?cat=`). Телефон: **Filters** →
  Sheet `filters` → «Show N advisors».
- **Профиль `/advisors/:id`.** Шапка, специализации, About, отзывы (3 + «Show all»),
  sticky-карточка: PriceTag в минуту с оффером, Next available (4 слота), Book
  session, Free chat, заметка об отмене; teaser-купон (мобильный `OFFER.md`).
  Телефон — фиксированная панель «PriceTag + Book session», таб-бар скрыт.
  Оффер гостя активен (как в гостевом ответе pricing); у вошедшего — из кошелька,
  с задачей входа.
- **Хендофф шире данных** — решить в спеке по правилу `AURAT-0102-006` (нет поля —
  не показываем; новое поле — отдельная задача contracts + BFF): в контракте 3
  категории против 6 чипов; нет полей под Reading style, Language, Verified,
  readings, years; онлайн-точку и фильтр Availability гость не видит.
- **CTA гостя** (слот, Book session, All dates & times, Free chat, Chat free / Book
  на плитке) по хендоффу ведут в gate с resume — это задача входа (строки 003–004),
  Book sheet — задача брони (строка 006). Решить в спеке, что CTA делают до них,
  без обработчиков-заглушек (правило 5): например, Free chat — ссылка на
  `/chats/:advisorId` (там GuestGate), слот и Book — deep link `?book=1&slot=`.
- **«Назад» сначала закрывает открытый диалог** (NAVIGATION §5): Filters — первый
  настоящий диалог, поэтому открытый пункт `AURAT-0101-016` делается здесь, а не с
  окном входа.
- Перенос из aura-app только нужного экранам, копией с тестами и шапкой
  `// Ported from aura-app <path> (<ID>)`: `entities/advisor/lib/rating.ts`,
  `features/booking/lib/slots.ts`, `shared/lib/{format,dates,time-zone,monogram-tint}.ts`.
- Новые строки — сразу на все 24 языка (правило 9).

Вне задачи: Home `/` (его нет ни в одной строке этапа 1 — отдельным решением), вход
и gate с resume, Book sheet и оплата, Write a review (этап 2), онлайн-статус (с WS,
задача чата), `/match`.

Проверка в маноре — после merge `AURAT-0102`, против BFF с `WEB_ALLOWED_ORIGINS`,
где есть `http://localhost:5173`. Старт — `wts-task` в `aura-web-manor`, спека на
одобрение владельцу.
