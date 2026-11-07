# AURAT-0192-004 — context

Дата: 2026-11-07. База — ветка 0192: `develop` `0410ed7` + 0191 `b247994` (`861100d`).

## Прочитано

- Брейн 0191 (`slave-4/missus`): `007-spec-v2`, `008-approval`, `009-execute`, `010-code-review`, `011-fix` (итог).
- Брейн 0189: `007-spec-v2`, `008-approval`, `009-execute`, `010-fix-review`.
- `AURAF-0023-glossary.md`, `AURAF-0024` (строка 003), `aura-app-manor/.claude/aura-build-rules.md` «Translations».
- Код: `src/modules/translation/**`, `src/modules/campaigns/**` (разговорник, `localize-campaign`,
  `campaign-translations`, `app-config.builder`, админ-сервис, репозиторий), `sessions.service.ts` (подпись в цене),
  `campaign-discounts.ts`, `backoffice-campaigns.controller.ts`, `views/campaigns.view.ts`, `prisma/schema.prisma`
  (`Campaign`, `CampaignEvent`), `src/jobs/*`, `common/language/text-checks.spec-fixtures.ts`.

## Что есть в коде

**Модуль перевода (0191).** Наружу — только `TranslationService`:
- `translate('campaign', { from: 'en', to, items }) → { items: translated | rejected + problems, engine, costUsd }`;
- `enabled('campaign')`, `supports('campaign', lang)`;
- отказ — `TranslationUnavailableError.reason` (`disabled`, `budget`, `credit`, `auth`, `rate_limited`, `timeout`,
  `refused`, `invalid_output`, `provider`);
- до 20 текстов на вызов, параллельность профиля держит сам сервис (23 вызова можно отдать разом);
- `item`: `form`, `maxLength` (длина с образцами плейсхолдеров), `placeholders`, `letterCase: 'upper'`, `note`;
- сам доводит: NFC, U+00AD, ro ș ț, fr пробелы, капс между плейсхолдерами;
- проверяет: `placeholders`, `tokens`, `too_long`, `empty`, `glossary`, `typography`. Сам не повторяет: «кампания может
  переспросить `rejected` с новой `note`».

**Разговорник (0189).**
- `translateCampaignText(place, english, language)` — чистая, по (месту, нормализованному английскому). Подпись скидки —
  без учёта регистра. Сейчас её зовут `localize-campaign.ts` и `campaign-translations.ts`, а через них —
  `app-config.builder.ts`, `sessions.service.ts` (цена), бэкофис.
- Набор из девяти — целиком на языке или целиком английский (решение 2). Кнопка с длинным кодом — `ctaWithoutCode`
  разговорника: один глагол на язык, не зависит от текста кампании (решение 5).
- Длина меряется живыми значениями при отдаче (`shownLength`, сумма на знак шире — решение 6); лимиты —
  `SEASON_COPY_TRANSLATED_LIMITS` (подзаголовок 40), подпись — 22.
- el: надзаголовки капсом без тонуса, подпись — обычным регистром. Остальные языки пишут надзаголовки обычным регистром
  (капс рисует клиент).
- `sensitive` — у фраз с деньгами.

**Кампании.**
- Тексты — JSON `seasonCopy` в `campaigns`, подпись — `discountLabel`. Править можно только черновик или выключенную.
  Версия для включения — `updatedAt`.
- Журнал `CampaignEvent`: действия `CREATED / UPDATED / ENABLED / DISABLED`, снимок кампании после действия;
  append-only.
- Бэкофис — HTML на сервере, без JS. Форма кампании и страница кампании, предупреждения «Другие языки — включить
  можно» (`translationNotes`).
- Цена (`CampaignDiscounts.active`) читает кампанию из базы на каждый запрос, без кэша; app-config кэширует прочитанные
  кампании на 30 с.

**Очереди.** Медленное — в BullMQ (правило стека). Процессоры тонкие (`avatar.processor.ts`), очереди — `queues.ts`,
`jobs.module.ts`.

## Находки и противоречия

1. **fr U+202F перед `%` — 0191 против 0189.** `translation-finish.ts` (0191) меняет пробел перед `%` на U+202F «как в
   приложении». Разговорник 0189 U+202F запрещает (`season-texts.spec.ts:56`): глоссарий fr — «not U+202F — the fonts
   lack it», `fr.ts` ставит U+00A0. Машинный fr «20 % de réduction» получит символ, которого нет в шрифтах. Правка —
   одна строка в 0191 (`/[  ](?=%)/` → U+00A0), 0191 ещё не в `develop`. Вопрос координатору.
2. **`WRONG_ADDRESS` — только тестовая фикстура** (`*.spec-fixtures.ts` исключены из сборки). Чтобы проверять обращение
   в машинных переводах при работе, а не в тестах, проверку нужно вынести в рантайм-модуль.
3. **Кнопка без кода уже есть в разговорнике** на все 23 языка и не зависит от текста кампании — переводить её машиной
   не нужно.
4. **Синхронный запрос не подходит.** 23 вызова по 3 одновременно, вызов Opus до 60 с — 2–8 минут. Нужна фоновая
   задача с прогрессом на странице, без автоповторов (вызовы платные).
5. **Устаревание.** Если английский правят после перевода, старый перевод отдавать нельзя — нужен исходник рядом с
   переводом.
6. **Включение и перевод.** Перевод включённой кампании поменял бы живые тексты в обход проверки включения — переводить
   и править можно только там, где правится английский (черновик, выключенная).
