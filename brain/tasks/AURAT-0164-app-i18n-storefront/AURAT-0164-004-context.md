# AURAT-0164-004 — context

## Код (ground truth, develop @ 7f58117)
Линтер (`i18next/no-literal-string`, временный прогон) — 29 мест в JSX; плюс строки в `config/` и `model/`.
- `screens/home` (~27): `config/constants.ts` — баннер Daily (4), гороскоп (7 + подсказка a11y), лист даты рождения
  (5 + подписи Day / Month / Year); `use-home` — «Hi, ${name}» / «Hi there»; `HomeScreen` — My horoscope, Top advisors,
  See all (+ a11y), Continue your chat; a11y `ContinueChatCard` «Continue your chat with ${name}», `BirthDateSheet`
  «${title}. Day, month, year», `HoroscopeCard` `${sign}, ${dates}` (знак и даты — уже `0161`). Дата в шапке и
  Today / Tomorrow — уже `0157`.
- `screens/advisors` (~10 сверх `segments`): заголовок Advisors, поиск (placeholder = a11y), Clear search, категории
  All / Love / Tarot / Psychic (`CATEGORY_LABELS` в config), 3 состояния списка, «/min» в строке и `suffix` у
  `PriceTag`.
- `screens/advisor-profile` (~20): Online now, «Away · replies in ~1h», About, Specialties, статистика (Rating /
  Reviews / Per min — капсом), Reviews, Write a review, «You reviewed ${firstName}», Chat first to review,
  «· Verified client» после `authorName`, Book, Start free chat, a11y с именем: Show / Close «${name}'s photo»,
  Close, «Book a session with ${name}[, ${discountLine}]», «Start free chat with ${name}», «Write a review for ${name}».
  `catalogDiscountLine`, `OfferTicket` — уже `0161`.
- `screens/daily-card` (~16): `config/copy.ts` — eyebrow, 3 фазы × 2, мост (функция `BRIDGE_TITLE(cardName)`), Ask an
  advisor, Chat is free to start, `OPENING_DRAFT(cardName)` (черновик в composer чата), Reaching for your card…,
  ошибка (2). Дата — `longDateLabel` (`0159`).
- «/min» ещё в `features/booking`, `features/paid-session`, `screens/booking` (задачи «бронь», «деньги»).
- Рейтинг: `formatDecimal` (`0159`) считает от целых десятых без `Intl` — half-even iOS (4.85 → 4.8) не возникает,
  рейтинг и так приходит десятыми (`ratingTenths`). Пункт заглушки снят.
- `AdvisorReview.authorName` = `'Anonymous'` (английский, от сервера), если `anonymous`; веб рисует
  `t('review.anonymous')` = «Anonymous · Verified client» и серверное имя не показывает.
- Порядок полей даты рождения — день первым во всех языках (решение `0157`: `shared:dob.placeholder` «Day first in
  every language: it is the mask's own order»).

## Веб (aura-web develop @ 88dd553, advisory — переиспользовать переводы)
- `pages/daily` — почти 1:1 с экраном Daily card: фазы, drawing, failed, bridge «Wondering what {{card}} means for
  you?», ask, free, **draft «I drew {{card}} today. What could it mean for me?»** — веб даёт черновик на языке
  интерфейса.
- `entities/advisor`: категории All / Love / Tarot / Psychic, `review.anonymous`.
- `pages/advisor`: Specialties, Reviews, «Per minute», About me; `pages/advisors`: Advisors, «Couldn’t load advisors»;
  `pages/home`: Top advisors, «See all advisors», «One free pull every day», «Drawn today».
- Имена в падежных слотах у веба есть («About {{name}}», «Tarot · from {{name}}») — не копировать формулировку.

## Противоречия / замечания
- Заглушка просила проверить half-even рейтинга — неактуально (см. выше).
- Поиск советников идёт по `name` и английской `role`: немец, набравший «Liebe», не найдёт — роль серверная, до шага 5.
