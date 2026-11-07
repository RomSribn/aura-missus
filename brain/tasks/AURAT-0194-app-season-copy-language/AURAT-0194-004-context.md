# AURAT-0194-004 — context

Дата: 2026-11-07 · Код — `develop` `3bee447` (slave-2).

## Сервер / контракты (`AURAT-0189`, high)

- `v0.30.0` (тег на origin): `AppConfigSeason.copyLanguage`, `AppConfigDiscount.labelLanguage`,
  `SessionPriceDiscount.labelLanguage` — `z.string().min(1).default('en')`, то есть **строка**, не `Language`.
  `fillSeasonCopy(template, { code?, amountMinor?, amount?, pct? })` — готовая `amount` выигрывает у `amountMinor`.
- Набор из девяти текстов — целиком на языке или целиком английский; `copyLanguage: 'en'` на запрос `de` — **верный**
  ответ (свой текст владельца без перевода). Значит, «ответ на чужом языке» определяется по языку **запроса**, а не
  по `copyLanguage`.
- Сервер мерит перевод с суммой на знак шире «$5» — под форму CLDR клиента («5 $»).
- Подпись скидки — обычным регистром на всех языках; el-надзаголовки сезона (`ticket*Eyebrow`) — уже капсом без тонуса.
- В приложении сейчас `#v0.29.0` (`package.json:19`, `node_modules` — 0.29.0).

## Приложение (ground truth)

- `entities/campaign/model/campaign-store.ts` — `refresh()` отдаёт текущий `inFlight`, троттл 60 с (`lastAskedAt`), языка
  запроса не знает; ответ публикуется и пишется в кэш без проверки. `useAppConfigSync` — `hydrate` + `refresh` на старте
  и при возврате в приложение; смену языка не слушает.
- `?lang` уходит сам: `http-client.performRequest` ждёт `i18nReady()` и берёт `currentLanguage()` в момент отправки.
- Образец «за языком» — `entities/advisor/model/catalog-store.ts` (`followLanguage`, счётчик `latest`, `latestLanguage =
  null`, пока i18n не стартовал — холодный старт в сохранённом языке спрашивает один раз) + `use-advisor-catalog-sync.ts`
  (`onLanguageChange`).
- Кэш `aura-app-config.json` — сырой ответ (`config-cache.ts`). Его же читает старт i18n
  (`readCachedDisabledLanguages`) — формат файла трогать дорого. Ответ v0.30 сам несёт `copyLanguage` / `labelLanguage`.
- `SEASON_COPY_LANGUAGE = 'en'` (`config/constants.ts:19`) — только `accessibilityLanguage` в `SeasonHero.tsx` (4 места;
  iOS — у Android такого свойства нет).
- `{amount}`: `hero-content.ts` (`heroBody`, `cta`) и `ticket-content.ts` (`ticketCode*`) зовут `fillSeasonCopy` с
  `amountMinor` → «$5» всегда. Без сезона билет пишет сумму `formatUsdMinorCompact(minor, language)` (CLDR, `AURAT-0174`).
  `formatUsdMinorCompact(…, 'en')` = `formatSeasonAmount` («$5», «$5.50») — английский не меняется.
- Капс надзаголовка билета — `ticketText.eyebrow` `textTransform: 'uppercase'` (`shared/ui/offer/TicketShell.tsx:425`).
  Подпись скидки попадает туда только у билета скидки **без сезона** (`ticket-content.ts:48`). На iOS el-капс через
  `textTransform` сохраняет тонос. `upperLabel(text, language)` — `shared/lib/dates.ts:233`; образец «капс на экране,
  обычный регистр для чтения» — `UpcomingSessionCard`, `SessionHero`.
- Подпись скидки в остальных местах — внутри фразы обычным регистром: `campaignDiscountTitle` («20% OFF · Winter sale»:
  профиль, приглашение в чате, разбивка цены), `BookedScreen` (`savedWith`, снимок на момент брони). Капса там нет.
- Цена (`fetchPricing`, `entities/session`) с подписью читается в трёх хуках `features/booking`: `use-booking`
  (`setPricing`), `use-booking-confirm` (свой `ownPricing`, если не дали `pricing`), `use-quick-booking`. `use-paid-session`
  подпись не показывает. Перечитывания при смене языка нет нигде.
- Комментарии «in English»: `ticket-content.ts:16-22`, `campaign/config/locales/en.ts:2-5`, `constants.ts:14-19`,
  `block-discount.ts:71-74` («English until AURAF-0023 step 5»).
- fr U+202F (заметка `0189-009`): шрифты приложения U+202F покрывают (`AURAT-0156`, `scripts/fonts/README.md:40`) —
  в приложении править нечего; устарела строка глоссария `fr.note` («the fonts lack it») — вне задачи, сказать
  координатору.
- Новых строк для человека нет → переводы и линтер строк (`AURAT-0180`) не затрагиваются.
