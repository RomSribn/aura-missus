# AURAT-0102-004 — context

Проверено: `AURAD-0019`, `AURAI-0007`, `AURAF-0020`, код `aura-bff` (`develop` @
`63acf5d`), WS-клиент `aura-app` и исходники React Native 0.85.

## Что есть в коде

- **CORS** — нет вовсе (`app.setup.ts`: helmet, rate-limit 120/мин на IP,
  multipart). `@fastify/cors` не установлен.
- **`FirebaseAuthGuard`** — глобальный; `@Public()` пропускает без разбора токена.
  `@CurrentUser()` бросает 401, если `authUser` нет. «Необязательного» входа нет.
- **Каталог** `GET /v1/advisors` — 8 активных персон, каждая уже несёт всё для
  профиля: bio, specialties, greeting, avatarUrl, цену за минуту, рейтинг, число
  отзывов и **все опубликованные отзывы** (одним join). Персональных полей нет —
  ответ одинаков для всех. `GET /advisors/:id` нет.
- **Слоты** `GET …/sessions/availability` — за `BillingEnabledGuard`; per-user:
  `ensureUser(auth)` (создаёт пользователя!) + занятость самого пользователя
  (`listUserBusyWindows`).
- **Цена** `GET …/sessions/pricing` — за `BillingEnabledGuard`; per-user:
  `ensureUser` + `hasUsedFirstSessionOffer` → блоки со скидкой −50% или без.
- **`/ws`** — `ChatGateway.handleConnection`, токен в `?token=`, `Origin` не
  смотрится.
- **Онлайн** — `PresenceService`: один глобальный флаг (пул чаттеров), уходит
  только по WS подключённым пользователям; в REST его нет.
- **Язык советника** — такого поля в модели `Advisor` нет.

## Расхождение с заглушкой 001

Заглушка говорит «мобильное приложение `Origin` не шлёт». **Неверно:** RN 0.85 на
Android (`WebSocketModule.kt`, `getDefaultOrigin`) сам ставит `Origin` =
`https://<хост BFF>`; на iOS SocketRocket делает то же (`SR_origin`). Проверка
`Origin` на `/ws` обязана пропускать «свой» хост, иначе приложение потеряет
realtime. Caddy (`reverse_proxy bff:3000`) сохраняет `Host` — сравнение
`Origin` с `Host` на сервере работает и за прокси.

## Фильтры каталога

8 персон, всё для фильтров «категория / цена / рейтинг» уже в DTO; страница 24
> всего каталога; «язык» — нет данных; «онлайн» — один глобальный флаг, не
per-advisor. Серверные фильтры/пагинация сейчас ничего не дают.
