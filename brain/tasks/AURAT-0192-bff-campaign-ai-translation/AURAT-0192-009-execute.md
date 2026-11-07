# AURAT-0192-009 — execute

Дата: 2026-11-07. Слот `aura-bff-manor` slave-1, ветка `feature/AURAT-0192-bff-campaign-ai-translation`. Ветка стоит на
develop `0410ed7` со смёрженной 0191 (`861100d`).

Код — по `005-spec.md` с правками `007-spec-v2.md`. **Не закоммичено, всё застейджено** (master и missus). Платных
вызовов нет: в тестах только фейковый переводчик и заглушки. Ключи не искались, стек не поднимался, миграция не
применялась.

## Проверки

| Проверка | Итог |
|---|---|
| `npm run lint` | чисто |
| `npm run typecheck` | чисто (`tsc --noEmit` и клиент desk) |
| `npm run build` | ✓; `dist/common/language/text-checks.js` есть, `*.spec*` в `dist` не попадают |
| `npx jest` | **177 сьютов, 2371 тест — все зелёные**. До задачи было 171 / 2294; новых — 6 сьютов, 77 тестов |
| `npx prisma validate` | ✓ |
| `npx prisma generate` | ✓ (клиент 7.8.0) |

- Prettier: новые файлы и изменённые файлы, которые до задачи были отформатированы, — чисто. Три файла 0191
  (`translation-finish.ts`, его spec, `translation.service.ts`) не проходили prettier и до моих правок, их не
  переформатировал.
- `prisma migrate diff` в слоте без `DATABASE_URL` ничего не выдаёт. SQL миграции сверен со схемой вручную.

## Правка модуля 0191 (р. 2 из `006`) — в ветке 0192

1. **fr U+202F → U+00A0 перед `%`** (`translation/translation-finish.ts`).
   - Причина: в шрифтах приложения U+202F нет — так говорят глоссарий v3 (fr `note`) и разговорник 0189 (`fr.ts`,
     `season-texts.spec.ts`).
   - Теперь U+202F на входе тоже заменяется на U+00A0 перед `? ! : ; %`.
   - Тест в `translation-finish.spec.ts`: два старых ожидания исправлены, два новых добавлены.
2. **`TranslationService.review(from, to, item, text)`** — новый публичный метод.
   - Доводит и проверяет текст так же, как ответ модели: `normalizeText` → капс → `checkItem` с глоссарием. Провайдера не
     вызывает и работает даже при `off`.
   - Нужен, чтобы правку владельца судить теми же правилами. Цикл `translate()` теперь сам вызывает `review()`, двух
     копий логики нет.
   - Тест в `translation.service.spec.ts`.
   - `ItemProblem` реэкспортирован из `translation.service.ts`.

Брейн 0191 не трогал.

## Сделано (aura-bff)

**Схема и миграция**
- `prisma/schema.prisma`: модель `CampaignTranslation` (`campaign_translations`, уникальна по кампании и языку) и
  значения `CampaignEventAction` `TRANSLATED`, `TRANSLATION_EDITED`.
- `prisma/migrations/20261107130000_campaign_translations/migration.sql`: два `ALTER TYPE … ADD VALUE`, таблица, CHECK на
  `costMicroUsd ≥ 0` и на язык (две буквы, не `en`), уникальный индекс, внешний ключ. Только добавления.

**Кампании — чистые части**
- `campaign-own-translations.ts` — типы `StoredCampaignText` / `CampaignLanguageTexts` / `CampaignTranslations`,
  `CampaignTextProblem`, `BREAKING_PROBLEMS`. Листовой модуль, без циклов импорта.
- `campaign-translation-merge.ts` — `mergeMachine` (годная правка владельца остаётся, места не из ответа не трогаются),
  `mergeOwner`, `englishIn`, `CAMPAIGN_TEXT_PLACES`, `storedTextsOf` (сужение JSON из базы).
- `campaign-translation-requests.ts` — что уходит (`pendingPlaces`, `translationPlan`) и как описан текст
  (`translationItem`: `form`, лимит, образцы, капс el, `note`). Образцы — `SAMPLE_VALUES`: `WINTER10`, `25 $`, `70`.
- `campaign-text-checks.ts` — `address`, `quotes`, `same_as_english`, `forbidden_char`, `case` (el).
- `texts/translate-campaign-text.ts` — `translateCampaignText(place, english, language, own?)`: сначала перевод кампании,
  потом разговорник. Плюс `sameCampaignText`, `servable`.
- `localize-campaign.ts`, `campaign-translations.ts` — переводы кампании в наборе, подписи, счётчиках и
  предупреждениях. Новые предупреждения: `missing-languages`, `stale`, `soft-problems`.

**Кампании — данные и сервисы**
- `campaigns.repository.ts`:
  - `CampaignRecord.translations`, `CampaignTranslationRow`;
  - новые методы `translationRows`, `writeMachineTranslation`, `writeOwnerTranslation`, `journalTranslationRun`.
- `prisma-campaigns.repository.ts` — реализация методов:
  - запись под `lockCampaign … FOR UPDATE` и со слиянием по местам;
  - у включённой кампании — `not-editable`;
  - правка владельца сверяет версию строки (`stale`);
  - `campaigns.updatedAt` трогается при каждой записи;
  - журнал `TRANSLATION_EDITED` в той же транзакции.
- `campaign-discounts.ts`, `prisma-campaign-discounts.ts` — `labelTranslations`, той же выборкой.
- `campaign-translation.service.ts` (новый):
  - `run` — все языки сразу, один повтор для `too_long` / `placeholders`, запись языка по готовности, прогресс, журнал
    `TRANSLATED`;
  - `review`, `pending`, `languages`, `enabled`.
- `campaigns-admin.service.ts` — `translationState`, `startTranslation` (дедупликация BullMQ, версия),
  `translationLanguagePage` (с превью app-config на языке), `saveTranslation`, `translationEnabled`.
- `app-config.builder.ts`, `sessions/sessions.service.ts` — отдача через переводы кампании.
- `campaigns.module.ts` — `TranslationModule`, очередь, `CampaignTranslationService` в экспорт.

**Очередь**
- `jobs/queues.ts` — `campaign-translation`, задача `translate`, `campaignTranslationDedupId`,
  `campaignTranslationQueueOptions` (`attempts: 1`), `CampaignTranslateJobData`.
- `jobs/campaign-translation.processor.ts` — тонкий процессор.
- `jobs.module.ts` — процессор и `CampaignsModule`.

**Бэкофис**
- `backoffice-campaigns.controller.ts`:
  - `POST :id/translate`;
  - `GET` / `POST :id/translations/:lang`;
  - «Сохранить и перевести» (`andTranslate`) в create / update.
- `http/backoffice.forms.ts` — `campaignTranslateSchema`, `campaignTranslationFormSchema` (`.strict()`),
  `translationLanguageSchema` (23 языка), `translationPageQuerySchema`, новые `notice`.
- `views/campaign-translations.view.ts` (новый) — раздел «Переводы», страница языка, превью «Как увидит de».
- `views/campaigns.view.ts`:
  - раздел на странице кампании;
  - кнопка «Сохранить и перевести»;
  - уведомления;
  - предупреждение «Перевод ещё идёт» на подтверждении;
  - журнал: «переведена», «перевод изменён».

**Перенос:** `common/language/text-checks.spec-fixtures.ts` → `text-checks.ts` (`git mv`). Шапка — «ships in dist».
Импорты двух спеков правлены, комментарий фикстуры советников тоже.

## Решения при исполнении

- **Гарды новых POST** (р. 3) — классовые гарды контроллера: `@Public`, `SameOriginGuard`, `BackofficeSessionGuard`,
  `BackofficeExceptionFilter`. Тело — строгий `ZodValidationPipe`, версия — как в 007 §3. Smoke проверяет 403 с чужого
  сайта и 400 на битое и лишнее.
- **`onDelete: Restrict`**, а не `Cascade`, как было в 005 §3: кампании не удаляются (журнал держит `Restrict`), и
  переводы ведут себя так же.
- **Дедупликация** — `deduplication: { id: campaign-translate:<id> }` BullMQ 5.80, без `ttl`: ключ живёт, пока задача не
  кончится. `jobId` на кампанию не подошёл: удержание завершённых задач (`KEEP_COMPLETED_SECONDS`) не дало бы нажать
  снова.
- **Неудача записи в базу** — язык помечается `store`, в лог идёт стоимость, остальные языки и журнал записываются.
  Повторный вызов за уже оплаченное не делается.
- **Неудачный повтор** (второй вызов) оставляет первый ответ с его проблемами, а язык не помечается непереведённым.
- **Правка владельца без изменений** не превращает машинный текст во «владельческий»: место пропускается.
- **Предохранитель 0191**: `auth` и `credit` открывают его сразу, поэтому остальные языки прогона получают ту же причину
  без вызова, и платных вызовов не больше `CONCURRENCY`. Это проверено тестом.
- **Отказ `RangeError`** (наш запрос неверен) → язык помечается `invalid_request`, ошибка в лог. Прогон идёт дальше.
- **Превью языка** — app-config этой же функцией, на языке страницы.
- **Тексты страниц** — по-русски, как весь бэкофис. Места подписаны по-человечески («Hero · заголовок»), а не ключами.

## Не сделано / на потом

- **Автообновления страницы нет** (без JS): во время прогона владелец обновляет её сам. Так и записано в 005.
- **Живой прогон** со staging-ключом — только после мёржа и с отдельного одобрения владельца (005 §11, передача 0191).
- **Пиксельная проверка** длинных машинных переводов на устройстве — как у 0189, в маноре и на устройстве.
- **После мёржа:**
  - `AURAF-0024` строка 003 — BE ✓, вместе с 0191;
  - `AURAF-0023` строка 011 — дописать: свои тексты кампаний — машинный перевод в бэкофисе (`AURAT-0192`).

## Проверка после мёржа (манор / bff-dev, координатор)

По 005 §11, плюс:
- **Миграция.** Применяется; `ALTER TYPE … ADD VALUE` — на PG ≥ 12 внутри транзакции миграции.
- **Без ключа (`off`).** Кнопки нет, правка языка работает, «Как увидит de» показывает `copyLanguage`.
- **`fake` локально.** «Перевести» → «Перевод идёт: N из 23» → таблица заполняется. Журнал `TRANSLATED` с $0. Второе
  нажатие во время прогона — «уже идёт».
- **Слияние.** Правка de во время прогона остаётся (`kept`). Форма языка, открытая до прогона, — 409.
- **Отдача.** `?lang=de` — набор на языке, `labelLanguage` в цене. Правка английского → «устарел» и английский в
  `?lang=de`.
