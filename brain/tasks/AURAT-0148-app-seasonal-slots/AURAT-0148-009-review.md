# AURAT-0148-009 — ревью манора первого этапа + решение владельца

Дата: 2026-11-01. Два ревью манора (баги; clean code / FSD) по staged-диффу `-008`. Тег `@aura/contracts`
`v0.27.0` выпущен (`main` `8699e32`); BFF 0147 на нём, но не смёржен (на bff-dev нет).

Подтверждено ревью: tsc / eslint / jest чистые, локальная схема совпадает с контрактом поле в поле,
решения владельца реализованы, частицы ≤ 12 с, глобальный `PromoCodeSheetHost` в `features` — верный слой.

**До мёржа (баги):** B1 пуш `promo` при открытой шторке → вторая нативная модалка (блокировка iOS,
`AURAT-0020`), холодный старт — шторка над сплэшем → пуш ведёт на Home с параметром, глобальная шторка
открывается, только когда не показана ни одна `BottomSheet`. B2 `useLive` не сдвигает `now` при новом
конфиге. B3 нормализация кода ≠ серверной (NFKC, мягкий перенос, нулевой ширины, тире U+2010–2015, U+2212).
B4 повторный `openPromoCodeSheet` не подставляет код. Низкие: B5 композит без округления (уйдёт с
контрактом), B6 `onError` глифа билета / `key` у арта hero, B7 неатомарная запись кэша, B8 публичный
ответ из HTTP-кэша сдвигает `serverNow`.

**До мёржа (clean code / FSD):** C1 удалить локальную копию контракта; C2 `OfferTicketState` — union по
`kind`, `onPressCode` отдельным пропом, без него билет кода не кнопка; C3 мёртвые экспорты; C4
`useSeasonHero` / `useSeasonBanner` / `useSeasonTabAccent` в сущности; C5 `useReducedMotion` и
`useReplayOnFocus` в `shared/lib`; C6 без `onLayout`-ширины в hero, `React.memo`, интерполяции в `useMemo`;
C7 порядок комментария в `use-quick-book`.

**C8 — решение владельца (2026-11-01): слайс переименовать в `entities/campaign`** (держит сезон, код и
скидку, как кампания в BFF 0147).

**Позже (записано, не в этой ветке):** `readBody<T>()` в `http-client` (общий хвост, ветка 204);
«сезонные» имена в shared (`seasonTicketSkin`, `seasonShadowAlpha` → `stubShadowAlpha`); эталон частиц
из прототипа в тесте, разбить `copy-and-parts.test.ts`, тесты `useOfferTicket` / `ticketSkinOf`;
non-null assertions в `active-parts.ts`, `pick-ticket.ts`; переобернуть комментарии
`notification-taps.ts`, `PushBootstrap.tsx`; хост шторки — подписку в `model/`, Profile — на
`openPromoCodeSheet`; остальные 7 вызовов `isReduceMotionEnabled` — на `useReducedMotion`.

Порядок: правки → переход на `#v0.27.0` (отдельный шаг) → этап 2 (§6).
