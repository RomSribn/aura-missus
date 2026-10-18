# AURAT-0099-004 — Context

Код (aura-app `develop` @ `f097f1e`):

- Три точки ухода в Top Up: `features/booking/model/use-booking-confirm.ts:207,259`
  (+ `screens/booking/model/use-book-review.ts:44`),
  `screens/chat-thread/model/use-quick-book.ts:107,173`,
  `features/paid-session/ui/SessionBlockSheet.tsx:120`
  (+ `screens/chat-thread/model/use-chat-thread.ts:153`).
- `features/store-topup/model/use-store-topup.ts` — единственный потребитель
  (Profile); `initConnection`/`endConnection` глобальны, второй потребитель
  сломает первый → подключение надо вынести в одного владельца.
- `features/store-topup/config/products.ts` и BFF `src/modules/wallet/top-up-tiers.ts`
  — по четыре тира; BFF отвергает неизвестный продукт 400.
- Блоки 1/10/20/30 мин, цены $2.20–$3.80/мин → максимум $114.
- Слоя `widgets` нет; экраны уже связывают фичи через колбэки (`onTopUp`).

Правила сторов — `AURAI-0006`: оплата через IAP полностью в правилах; брендинг
Apple Pay на IAP — нет.
