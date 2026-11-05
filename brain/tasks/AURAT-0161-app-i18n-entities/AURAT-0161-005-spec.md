# AURAT-0161-005 — spec (draft, rev. 1 — правки ревью slave-1-9e: сумма compact, разделитель только месяц–день)

Тип: задача фичи `AURAF-0023`, шаг 3 — **entities**. Только `aura-app`; флаг `AURA_I18N_ENABLED` выключен — в
релизе английский, английский вывод не меняется. Правила — «Translations» в `aura-build-rules.md`.

## Что меняется

1. **Знаки зодиака — namespace `horoscope`** (`entities/horoscope/config/locales`, 24 языка).
   - `sign.<ZODIAC_SIGN>` — 12 названий; `@max 14` (строка в карточке рядом с глифом; впритык — ga
     «An tUisceadóir» ровно 14: проверить карточку на ga и псевдоязыке). Переводы — общепринятые
     названия знаков в каждом языке (на вебе их нет); совпадающие с английским (es «Aries», «Leo», «Virgo»,
     «Libra»; fr «Cancer»; ro «Capricorn» …) — в `SAME_AS_ENGLISH` как латинские названия.
   - `config/signs.ts`: вместо `SIGN_COPY` — `SIGN_DATES: Record<ZodiacSign, { from: [месяц, день], to: […] }>`
     (те же границы, что сейчас; комментарий про сверку с таблицей BFF остаётся).
   - Даты — `shortDateLabel` (CLDR MMMd, уже в `@/shared`) для обоих концов, соединённые **разделителем
     диапазона по CLDR** (п. 2). en-US «Mar 21 – Apr 19» как сейчас; en-GB «21 Mar – 19 Apr»; de «21. März –
     19. Apr.»; pl «21 mar–19 kwi»; cs «21. 3. – 19. 4.».
   - `useHoroscope().signCopy` — та же форма `{ name, dates }`, собирается в хуке (`useTranslation('horoscope')`
     + `useLanguage()`, `useMemo` по знаку и языку). `HoroscopeCard` (screens/home) не меняется — его a11y-склейка
     и прочие тексты Home — задача слайса home.
2. **Разделитель диапазона «месяц–день» — в генератор `0159`.** `generate-formats.mjs` берёт его из
   `formatRangeToParts` скелета MMMd для двух дат **из разных месяцев** (литерал между концами) для каждой
   таблицы → поле `monthDayRangeSeparator` в `formats.generated.ts`; drift-тест сверяет его с живым `Intl`; новый
   `@/shared` `monthDayRangeLabel(from, to, language)` = `shortDateLabel` + разделитель. JSDoc: «только
   месяц–день; у диапазона времени свой разделитель (de «10:00–10:30 Uhr», hu, el, mt) — своё поле, когда
   понадобится». Вне Hermes `formatRange` нет — потому таблица.
   *Альтернатива:* ключ `datesRange: '{{from}} – {{to}}'` в `horoscope` — 24 копии, 18 равны английскому
   (`SAME_AS_ENGLISH`), и разделитель живёт не там, где остальной CLDR. Рекомендую генератор.
   Оговорка: у mt одиночная дата CLDR «Mar 21», а в диапазоне «21 ta’ Mar» — берём одиночную, как везде в
   приложении.
3. **Запасные слова билета — namespace `campaign`** (`entities/campaign/config/locales`).
   - `ticket.codeEyebrow` «Promo code» (`@max 22`, капс → el в капсе), `ticket.codeTitle` «{{amount}} on your
     balance» (`@max 17`), `ticket.discountTitle` «{{pct}}% OFF sessions» (`@max 19`), `ticket.discountSub` «Any
     advisor · applied at checkout» (`@max 36`). Лимиты — серверные 22 / 36 минус место под сумму / процент.
     Переводы — веба (`season` ns: discountTitle / discountLine / codeTitle), «Promo code» — веба
     `redeem-promo-code:label`.
   - `FALLBACK_TICKET_COPY` удаляется. `campaignTicketContent(kind, config, fallback)` — третьим аргументом
     получает `t` namespace `campaign` и язык; запасные строки идут через i18next (`{{amount}}` =
     `formatUsdMinorCompact(amountMinor, language)` — как сезонный формат, без «.00» у целой суммы: en «$5» /
     «$5.50» (английский вывод не меняется), de «5 $», fr «5 $»… по CLDR), **сезонные — по-прежнему через
     `fillSeasonCopy`** с одиночными скобками, английское «$5» (сервер шлёт английский, `AURAT-0149` реш. 3).
     Подстановки не пересекаются: двойные скобки — только у наших строк, одиночные — только у серверных; тест на
     оба пути (сезон есть / нет) в de.
   - `useOfferTicket` берёт `t` и язык, `useMemo` пересчитывается при смене языка.
4. **Сезонная карточка — `SeasonHero`.** Склейка `${title}. ${body}` остаётся (два целых серверных предложения,
   переводимых кусков нет). Предлагаю добавить `accessibilityLanguage="en"` на блок текста и кнопку, пока сезон
   английский (константа `SEASON_COPY_LANGUAGE` в `config` с отсылкой к `AURAT-0149`): VoiceOver прочтёт
   английский английским голосом при немецком интерфейсе — аналог `lang="en"` на вебе. Только iOS; Android
   игнорирует.
5. **«Change photo» — namespace `user`** (`entities/user/config/locales`), `changePhoto`, `@max 24` (ссылка
   справа от аватара). Переводы — веба `edit-profile:photo.change`. `PhotoRow` вызывает `useTranslation('user')`.
6. **Обвязка.** Три namespace в `app/i18n/namespaces.ts`; `src/entities/**/*.tsx` — в override
   `i18next/no-literal-string` (`.eslintrc.js`); `translate.mjs scan` / `check` по трём en.ts — 0 запретных форм.
7. **Тесты.** `use-horoscope` — имя и даты на de / pl / en-GB; `ticket-content` — английский запасной билет
   остаётся «$5 on your balance», на de / fr — без «,00» у целой суммы, процент и сезонные без изменений (английское «$5»); `PhotoRow` — подпись на de; drift-тест —
   `rangeSeparator` × 25 таблиц. Английские тесты Home / профиля / промокода не должны поменяться.

## Не входит

- Тексты `screens/home` (подсказки гороскопа, a11y `${name}, ${dates}`), `features/promo-code` — их слайсы.
- Перевод серверных сезонных текстов и имён карт таро — нужен контракт с языком.
- `CampaignTicket` (shared, 0157) — `accessibilityLanguage` для серверных строк на билете; если п. 4 примем,
  билет — отдельной строкой в следующий шаг.

## Решения владельцу

1. Разделитель диапазона — **генератор CLDR** (рекомендую) или ключ в `horoscope`?
2. Eyebrow запасного билета — оставить **«Promo code»** (как сейчас в приложении; рекомендую) или «Gift code»,
   как на вебе?
3. `accessibilityLanguage="en"` на сезонной карточке — **да** (рекомендую) / нет?

## Проверка

Слот: `npx tsc --noEmit`, `npm run lint`, `npx jest --no-watchman`, `generate-formats.mjs --check`,
`translate.mjs check`. Манор (после merge): dev-меню «i18n: next language» — Home (знак и даты на de / pl / pt /
el, без обрезки), билет без сезона на профиле (de / fr / el в капсе), «Change photo» в Edit Profile; VoiceOver на
сезонной карточке при de.
