# AURAT-0107-004 — Context

Date: 2026-10-20

Источники: заглушка `001`; `AURAF-0020` (строки 006, 007), `AURAD-0019`, `AURAI-0007` («Заготовка под
PSP», FSD-раскладка), шаги `AURAT-0103`…`0105`; код веба (`develop` `708d7f6`); aura-app `develop`
`cc71ef4` (только чтение); aura-bff `develop` `4bc1504`, aura-contracts `v0.22.0` (`003040a`);
веб-хендофф README §3, §4.1–4.7, §5, §8, NAVIGATION §1.1, §2.3–2.8, §3.2, §3.4, §4–6, `src/` и
прототип; мобильные `SESSIONS_BOOKING.md`, `CHECKOUT.md`, `OFFER.md`.

## 1. Что уже есть в вебе

- `entities/session`: `getSessionPricing`, `getAvailability` (`extraOptions.public` — токен
  прикладывается, если есть, т. е. вошедшему ответ персональный), `nextFreeSlots`,
  `offerPctFromPricing`, `useSessionPricing` (`billing: on/off/unknown/loading`), `useNextSlots`
  (7 дней), `SessionInviteCard`.
- Профиль: «Next available» (4 слота, Today/Tomorrow/день недели), Book / All dates / слот — ссылки
  `?book=1[&slot=YYYY-MM-DDTHH:mm]` через `gateLink(reason 'book')`; `useGateOnArrival` для прямого
  захода. Самой шторки нет: `book` объявлен в `DialogKind`, не зарегистрирован в `DIALOGS`.
- Чат: календарь в шапке, Book в rail и в приглашении — ссылки на профиль `?book=1`.
- Маршруты `/checkout` (pushed) и `/booked/:sessionId` — `element: null`; `/sessions` — `null`.
- `shared`: `PriceTag`, `OffChip`, `CouponTicket` (teaser), `Sheet`, `formatUsdMinor`,
  `discountedMinor`, `daysUntil`, `localSlotKey`, `formatTime/Weekday`, `deviceTimeZone`,
  `serverNow`, `BILLING_DISABLED_STATUS`; `env.pspEnabled` (`VITE_PSP_ENABLED`) объявлен, никем не
  читается. `baseApi.tagTypes` пуст. Кошелька (`entities/wallet`) нет. Магазинных ссылок на
  приложение в конфиге нет.

## 2. BFF (без изменений)

- `GET /v1/advisors/:id/sessions/pricing` → `{priceMinorPerMinute, blocks[{minutes, subtotalMinor,
  creditMinor, costMinor}]}`; `creditMinor` — скидка первой сессии (50 %), `costMinor` — что
  спишется. Блоки — `SESSION_BLOCK_MINUTES` (по умолчанию 10, 20, 30; **на bff-dev 1, 10, 20, 30**).
- `GET …/sessions/availability?days(1–14, def 14)&tz&minutes` → `{instantAvailable, days[{date,
  slots[{startsAt, available}]}]}`; **первый день — сегодня** в `tz`, сетка 24/7 шагом 30 мин;
  прошедшие слоты сегодня приходят `available:false`; занятость самого человека учитывается, если
  есть токен. Lead: по умолчанию 30 мин, на bff-dev 5.
- `POST /v1/advisors/:id/sessions` `{startsAt | startNow, minutes, idempotencyKey(uuid)}` → 201
  `{session, balanceMinor}`. Ошибки — тело Nest без `code`: 400 (вне сетки, ближе lead, дальше
  горизонта, не тот блок), 404 (нет цены; без биллинга — голый 404), 409 «слот заняли» / «у вас уже
  сессия в это время» / «ключ уже потрачен на другое списание» — различимы только текстом, 402 —
  не хватает. **Повтор с тем же ключом тело не сравнивает**: вернёт исходную сессию (201, текущий
  баланс), даже если слот или блок другие. Проверки 400 идут до поиска повтора: повтор, чей слот
  уже ближе lead, получит 400.
- Оффер применяет сервер под блокировкой; израсходован, когда на сессии записан `creditMinor > 0`;
  возвращается при отмене с полным возвратом.
- `GET /v1/sessions` → `{sessions[]}` до 100, все статусы, без пагинации; `GET /v1/sessions/:id`
  нет. `Session` без имени советника (джойн с каталогом) и без `creditMinor` — экономия считается
  `sessionSavingMinor` (`bookedMinutes × rate − costMinor`).
- `GET /v1/wallet` → `{balanceMinor, currency:'USD', purchaseAccountId?, firstSessionOffer{active,
  pct}}`. По сокету баланс не приходит; `session.updated` — приходит (бронь, старт, отмена …), чат
  его сейчас игнорирует.
- **Расхождение с заглушкой:** `POST /v1/wallet/top-ups` отвечает 503 только при
  `NODE_ENV=production`; у bff-dev (`.env` манора BFF — `development`) это dev-заглушка, которая
  **зачисляет деньги без оплаты**. Веб её не вызывает (это не пополнение, а инструмент разработки).
- Контракты `v0.22.0` содержат всё нужное: `BookSessionRequest/Response`, `SessionsResponse`,
  `Session`, `WalletResponse`, `FirstSessionOffer`.

## 3. Приложение (`develop` `cc71ef4`)

- `features/booking/lib/slots.ts`: `toBookingDays` (первый день — «Today», дальше день недели,
  `hasFreeSlots`), `toBookingSlots` (прошедшие по часам сервера убраны, занятые остаются),
  `nextFreeSlot`, `untilLabel`, `toBookingDurations` (блоки сервера), `slotRangeLabel`. Подписи —
  английские руками; веб форматирует `Intl` (как в `AURAT-0103`).
- `use-booking`: открытие — pricing + availability для **самого короткого** блока; дата — первый
  день со свободным слотом; смена длительности перечитывает сетку и сбрасывает время; смена даты —
  сбрасывает время. `refreshAvailability` есть, но после 409 никто не зовёт (не копировать).
- `use-booking-confirm`: на входе перечитывает кошелёк; ключ попытки — в ref, **сбрасывается
  только на определённом исходе** (успех, 400/402/404/409); сеть и 5xx — ключ держится, повтор не
  спишет дважды. Успех → баланс из ответа, при скидке — перечитать кошелёк (оффер ушёл везде).
  402 → перечитать кошелёк + Top up. Оффер показывается, только если pricing его подтверждает
  (`creditMinor > 0`). Тесты — 14 сценариев (список в отчёте контекста).
- Quick book (`use-quick-booking`): ближайший слот или «сейчас» (`instantAvailable`), длительности,
  «Another time» → полная сетка; открывается из шапки чата и приглашения. Мгновенная сессия —
  баннер в треде, без Booked.
- Booked: «Session booked», «{name} will be ready for you at the time you picked.», «You saved $X
  with your welcome offer», карточка, «View session». Календаря и чата нет (`AURAF-0008-012`).
- `entities/session/lib/{saving,session-state}.ts`, `shared/lib/dates.ts` (`localDateKey`,
  `todayDateKey`, `longDateLabel` …). Переводов нет — строки в коде.
- `AURAT-0099` (оплата в один тап) — **не закоммичена**: staged в slave-1 приложения. Меняет
  `confirm()` на `charge() → 'done' | 'slotTaken' | 'insufficient' | 'failed'` (400 и 409 — оба
  `slotTaken`), остальное — магазинный рельс (вебу не нужен). API брони не меняет.

## 4. Хендоффы — что расходится с данными

| Тема | Веб-хендофф | Мобильный / сервер |
|---|---|---|
| Дни | 7, с завтра, без «Today» | 14, с сегодня, «Today» |
| Длительности | 30 / 45 / 60 | блоки сервера (10/20/30; bff-dev 1/10/20/30) |
| Путь | профиль: шторка с inline-оплатой; остальные: шторка → `/checkout` | Book → Review |
| Баланс | тумблер «Use balance» (вычет перед картой), кнопки Apple/Google Pay и «Pay $X» | баланс выбран, «not enough», «Top up to book» |
| Недостача без PSP | не нарисована | «Top up to book» → магазин |
| Quick book | в приглашении и rail: длительности, 6 ближайших слотов, сохранённая карта, «Pay $X · {day} {time}», «More dates →» | шторка: ближайший слот / «Start now» |
| Booked | «Go to session» (`/sessions`), Add to calendar (.ics / Google), «Can't wait? Say hi … free chat →» | «View session» |
| Вопрос | только показ вопроса из `/match` | — |
| Оффер | `user.offer` | `firstSessionOffer` кошелька (правило 7) |

Ошибки зоны в `src` хендоффа: `toISOString().slice(0,10)` (день сдвигается в UTC+),
`startsAt.slice(11,16)`, черновик `slot: "HH:MM"` без смещения, `fEnd` без `%24` — не переносить.
Аналитики в вебе нет — события §6 вне задачи.

## 5. Оценка объёма

Строка 006 одна больше чата `AURAT-0105`: кошелёк, шторка Book (длительности, 14 дней, слоты,
черновик), оплата с баланса (ключ, исходы, «Still confirming…»), Quick book в чате, `/checkout`,
`/booked` с .ics, баланс в шапке, 24 языка. Строка 007 — порт способа оплаты с фейковым провайдером
карты и кошелька, маршрут возврата с hosted page, опрос — отдельный слой, который до PSP не
списывает деньги. → в спеке предложено разделить.
