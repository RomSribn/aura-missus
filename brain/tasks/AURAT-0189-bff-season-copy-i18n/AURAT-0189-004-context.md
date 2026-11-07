# AURAT-0189-004 — context

Дата: 2026-11-07 · Код — `aura-bff` `b81cc54`, `aura-contracts` `main` `54407ea` (BFF на теге `v0.29.0`), `aura-app`
манор, `aura-web` манор, хэндофф дизайнера `aura-app-manor/.claude/design_handoff_aura/`.

## Сервер (ground truth)

- **Хранение.** `Campaign.seasonCopy Json?` — 9 текстов, плейсхолдеры не подставлены; `promoHeadline String?`,
  `discountLabel String?` (`prisma/schema.prisma:515-527`). Пишутся формой бэкофиса целиком; язык один — английский.
- **Форма.** `campaign-draft.ts:230-250` — каждый текст обязателен, ≤ 120 знаков до подстановки, плейсхолдеры по
  `SEASON_COPY_PLACEHOLDERS`. `PROMO_HEADLINE_MAX = 60`, `DISCOUNT_LABEL_MAX = 24` (`campaign-rules.ts:21-22`).
  «Вставить presets/<id>.json» (`campaign-preset.ts`) заполняет тексты из файла дизайнера — пресет в код не попадает.
- **Длина.** `copyTooLong` (`campaign-rules.ts:112-135`) меряет `fillSeasonCopy` с каждым кодом, который может быть
  на показе, `{pct}` = 70; при включении — блокер `copy-too-long` (`campaign-enable-check.ts:156-189`). Только
  английский.
- **Отдача.** `buildAppConfig` (`app-config.builder.ts`) — чистая; `copy` парсится схемой контракта, `headline` /
  `label` — как в базе. `AppConfigService` кэширует **один** готовый ответ на 30 с (`app-config.service.ts:40-60`);
  контроллер публичный, без `?lang`, ETag по телу, `max-age=60` (`app-config.controller.ts`).
- **Подпись скидки — ещё и в цене.** `CampaignDiscounts.active` → `priceBlock` → `GET
  /v1/advisors/:id/sessions/pricing` (`sessions.service.ts:204-227`) несёт `discount.label` («Winter sale», en).
  Приложение показывает её в разбивке цены и на экране «Забронировано» (`block-discount.ts:75-93`,
  `BookedScreen.tsx:92-98`), веб — в `entities/session/lib/offer.ts:57`. Без перевода здесь app-config и цена
  разошлись бы по языку.
- **Резолвер `lang`** (`AURAT-0171`): `@RequestLanguage()` + `languageOrDefault`, выключенный язык → английский.
  `TranslatedLanguage` — 23 языка ЕС. Образец перевода «по полю с отпечатком» — `modules/advisors/texts/` (`0184`),
  проверки текстов в spec: NFC, ro ș ț, fr U+00A0, кавычки языка, обращение (`WRONG_ADDRESS`), `reader`/`reading`
  (`glossary-avoid.spec-fixtures.ts`, v3 + женские формы).
- **Порт перевода нет.** `AURAI-0012` (slave-2, только брейн) описывает `Translator` (абстрактный класс, адаптер
  через DI), не реализован, решения 1–5, 8, 9 ждут владельца.

## Тексты, которые есть

Пресеты дизайнера (`presets/winter.json`, `presets/valentine.json`, `SEASONAL.md` §11) — единственный источник
текстов сезона. Уникальных фраз 14: по 5 своих у каждого пресета (`heroTitle`, `heroBody`, `heroBodyNoCode`,
`ticketCodeEyebrow`, `ticketDiscountEyebrow`) и 4 общие (`Apply {code}`, `{amount} on your balance`, `{pct}% OFF
sessions`, `Any advisor · applied at checkout`). Подпись скидки по `SEASONAL.md` совпадает с эйбрау («Winter sale»).
`headline` в пресетах нет; его пишет оператор, с кодом буквально («Apply WINTER5»).
**Какие тексты у кампаний на bff-dev / проде — из слота не видно** (живой БД нет).

## Клиенты

- **Приложение уже шлёт `?lang` на каждый запрос**, публичные тоже (`http-client.ts:63`, `AURAT-0169`) — app-config
  и цена получат перевод без правки запроса.
- **Не перечитывает app-config при смене языка:** `campaign-store.ts:75-79` — не чаще раза в минуту, на старте и при
  возврате в приложение; кэш-файл `aura-app-config.json` — один, без языка. Каталог и таро перечитываются через
  `shared/lib/i18n/on-language-change.ts` (`use-advisor-catalog-sync.ts`) — образец есть.
- `SEASON_COPY_LANGUAGE = 'en'` (`entities/campaign/config/constants.ts`) — язык доступности hero (`SeasonHero.tsx`
  `accessibilityLanguage`, работает только на iOS); комментарии «a season words it itself — in English»
  (`ticket-content.ts:16-22`).
- **`promo.headline` не показывает никто** — ни приложение (только `test-support/season.ts`), ни веб.
- `fillSeasonCopy` пишет «$5» во всех языках — так и решено (`AURAT-0174`).
- Веб: app-config в `app/root.tsx` / `main.tsx`, hero с `lang="en"` (`AURAT-0149` решение 3). Приоритет — после
  Android.

## Экран (SEASONAL.md)

Hero 164 pt: заголовок Bricolage 800 20/22.4, 2 строки в колонке 182 pt; тело Hanken 13, 2 строки, длиннее —
многоточие; CTA одна строка. Билет: эйбрау / заголовок ≤ 22, подзаголовок ≤ 36. Лимиты знаков гарантированы на
316 pt для английского; языки — латиница, кириллица (bg), греческий (el), у de / fi / hu / nl длинные слова.

## Глоссарий и ревью

- `AURAF-0023-glossary.md`: `reader` — слово консультанта, не «читатель» (во всех 23); `reading` — слово консультации
  языка (fr «consultation», de «Deutung»). Оба пресета пишут «reader» / «reading» — главный риск перевода.
  Обращение и форма кнопки — таблица глоссария (cta — кнопка, остальное — текст).
- `@sensitive` (оплата, деньги) — ревью носителями не блокирует сборку, нужно до маркетинга в стране (`AURAI-0010`
  решение 7). Журнал ревью есть только в приложении (`scripts/i18n/native-review.json`), у BFF его нет.
- Тексты сезона говорят о «читателе» без рода и имени — в языках с родом нужен оборот без рода (мн. ч., «наши
  консультанты»), не мужской по умолчанию.

## Противоречий нет

Заглушка не знала о подписи скидки в цене сессии и о том, что `headline` не показывает ни один клиент — оба факта
в спеке.
