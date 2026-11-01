# AURAT-0148-013 — правки финального ревью манора

Дата: 2026-11-01. Слот `slave-1`, всё в индексе (104 файла), не закоммичено. 0147 в `develop`
(`aura-bff` `c8d78cf`); на bff-dev `/v1/app-config` пока 404 — проверки против bff-dev и на устройствах
после выкатки.

**До мёржа — сделано**
- **B-1** (блокер): `savedWithOf(discount)` → параметр `savedWith` маршрута Booked (Review и Quick book):
  «You saved $X with Winter sale» / «with your welcome offer» (оффер или BFF без поля) / «You saved $X»
  (вид незнаком). Session detail — «Saved».
- **M-1**: виды `credit` (BFF без поля, без оффера → «First-session credit») и `other` (незнакомый →
  «Discount»); `BookingPrice.creditRow`.
- **M-2** (решение владельца, со слов манора): `savingMinor` по `ratePct` — футер Book Session
  зачёркнут и «You save» при кампании; `campaignLine` в футере Book Session и в Quick book; §6 спеки
  поправлен (`-006`, раздел «Поправка к §6»).
- **M-3**: `shared/lib/modal-presence.ts` — `useModalPresence(isShown, releaseAfterMs)` в `BottomSheet`,
  `ImageViewer`, `SpreadCardViewer` (у просмотрщиков — отпуск через 600 мс после скрытия: у fade нет
  колбэка на Android). Старый `bottom-sheet/presence.ts` удалён.
- **M-4**: очередь разбирается через 120 мс после последней модалки, по одному запросу, с перепроверкой
  `shown === 0`.
- **M-5**: `openPromoCodeSheet` (тап) открывает сразу; `openPromoCodeSheetWhenClear` (пуш через Home) ждёт
  модалки не дольше 3 с.
- **M-6**: хост шторки передаёт `onClosed={closePromoCodeSheet}`.
- **L-1**: `NOISE` — `\u`-escape'ы (раньше символы стояли буквально); тесты — тоже escape'ы.
- **L-2**: `BookingPrice.discount` теперь читается (B-1).
- **L-5**: тест — вторая попытка после 409 идёт с новым ключом и новым `expectedCostMinor`.
- **L-6** попутно: `first_session` / `campaign` привязаны `satisfies SessionDiscountKind`.

Проверки: `tsc` ✓, `eslint` ✓, jest 151 / 1141 ✓.

**Позже (записано)**
- M-7: холодный старт из пуша — `navigate(MAIN)` при Splash даёт `[MAIN, MAIN]` / пропуск Create Account;
  держать тапы до ухода сплэша — отдельной задачей (проверить на устройстве в этой).
- L-3: вывод скидки продублирован в `use-quick-book` и `use-booking` → `useQuickBooking` отдаёт
  `offerPct` / `ratePct` / `campaignLine`, экспорты хелперов из `features/booking` убрать.
- L-4: после 409 перечитывание цены без состояния загрузки, Pay активна со старой ценой; упавшее
  перечитывание `failed` затирает `priceChanged`.
- L-7: `useReplayOnFocus` может проиграть дважды при монтировании (focus приходит и на первом рендере).
- L-8: `campaign-store` ставит `lastAskedAt` до запроса — без сети на старте повтор не раньше 60 с.
- L-9 (известное ограничение): цены в списке советников, `OffChip`, `StatsCard`, `SessionInviteCard`
  («50% OFF First Session») — от оффера кошелька; при кампании больше оффера занижают скидку.
- L-10: в `DailyCardBanner` переменная `gold` хранит акцент сезона — переименовать.
- `BottomSheet.handleDismissed` — игнорировать запоздалое закрытие, если шторка снова видима (M-6, позже).
- Из `-009`: `readBody<T>()` в `http-client`; «сезонные» имена в shared; подписка хоста шторки в `model/`;
  Profile → `openPromoCodeSheet`; остальные 7 вызовов `isReduceMotionEnabled` → `useReducedMotion`.

**Проверить на устройствах (A50 + iOS) — для манора**
1. iOS, тап по пушу `promo`, когда открыто: Quick book в чате; TopUp на Review (хватает ли 600 мс);
   ImageViewer; SpreadCardViewer; уже открытая промо-шторка (код заменяется).
2. iOS: быстро закрыть и сразу открыть промо-шторку из hero; цепочка шторок, пока промо в очереди.
3. iOS (RN 0.85 Fabric): приложение свернули посреди закрытия шторки — hero после этого работает.
4. Холодный старт из пуша (вошедший / аккаунт без имени): что в стеке, куда ведёт «назад», не пропущен
   ли Create Account.
5. Кэш: первая запись и перезапись на обеих платформах; первый запуск сезона — coral-орб, второй —
   сезонный; очистка Caches системой.
6. Hermes на A50: `normalize('NFKC')` для полноширинного кода.
7. Частицы на A50 (падение кадров), Reduce Motion / «Убрать анимации» на обеих платформах.
8. Hero 164 при крупном системном шрифте.
9. Вживую с BFF 0147: 409 `session_price_changed` на Review, в Quick book и через стор (sandbox); в логах
   BFF у второй попытки другой `idempotencyKey`, двойного списания нет.
10. `.webp` и `Image.prefetch` на Android.

Мёрж — после выкатки 0147 на bff-dev и проверки на устройствах; только с явного «да» владельца.
