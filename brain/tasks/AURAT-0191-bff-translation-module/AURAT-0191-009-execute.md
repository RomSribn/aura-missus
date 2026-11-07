# AURAT-0191-009 — execute

Дата: 2026-11-07. Код по `007-spec-v2.md`, застейджен, без коммитов. Платных вызовов нет, ключи не искались.

> **После ревью кода (`010`) — исправления в `011-fix.md`; где 009 и 011 расходятся, верен 011.** Что в 009
> устарело:
> - порядок «бюджет и предохранитель до очереди»;
> - оценка обрыва «своя модель + запасная»: теперь только своя, Opus ≈ $0.33;
> - повторы SDK `maxRetries: 2`: теперь `maxRetries: 0` и свои повторы;
> - тексты XML-секцией в одном блоке: теперь отдельным блоком контента;
> - ключи уведомлений `notice-80`: теперь `notice:<период>:80`;
> - цифры тестов.
Писали две сессии слота: первая — модуль, у неё кончился лимит; вторая (перезапуск по «Да, перезапусти» владельца) —
тесты, документы, перенос на свежий `develop`, полные проверки и самопроверка.

## Сделано

**Модуль `src/modules/translation/`:**
- порт `translator.port.ts`;
- профили и env — `translation-config.ts`;
- сервис `translation.service.ts`;
- бюджет, предохранитель с замком пробы, уведомления;
- доводка: капс между плейсхолдерами, ro / fr / U+00AD;
- проверки: `placeholders`, `tokens`, `too_long`, `empty`, `glossary`, `typography`;
- семафор;
- адаптеры `off` / `fake` / `claude` (`claude/`: цены, thinking, ошибки, промпт);
- модуль, `TranslationModule` в `app.module.ts`.

**Глоссарий v3** скопирован дословно: `glossary/app-glossary.json`. Имя не `glossary.json`: jest разрешает
`./glossary` в `.json` раньше, чем в `.ts`.

**Env и зависимости:**
- `env.schema.ts`: `TRANSLATION_CAMPAIGN_*`, `TRANSLATION_BUDGET_RESET_DAY`, `ANTHROPIC_API_KEY`,
  `requireTranslationProfiles`;
- `package.json` — `@anthropic-ai/sdk` 1.6.0, точная версия;
- `deploy/env/bff.env.example` — блок «Translation (AURAT-0191)»: пустые значения и комментарии. Пустые строки файла
  схема считает «не задано» — это проверено тестом.

**Тесты второй сессии:**
- `translation.service.spec.ts`, 33 теста:
  - старт: `off` без `prepare` и `supports`; язык, которого нет у адаптера, — в логе и `supports = false`; ни одного
    языка — отказ старта; `DISABLED_LANGUAGES`; предупреждение «ключ без claude», сам ключ в лог не попадает;
  - `RangeError` — 9 случаев, адаптер не вызывается;
  - деньги: стоимость, оплаченный отказ, **обрыв по таймауту пишет оценку, а не 0**, уведомление на 80 %;
  - предохранитель через сервис: `auth` — одно уведомление, второй вызов идёт без вызова адаптера; 5 `provider`
    подряд; чужая ошибка → `provider`; без Telegram; Redis не отвечает → `provider`, повторяемый, без вызова;
  - 23 вызова при `CONCURRENCY=3`: в адаптере не больше 3 одновременно;
  - пропавший `id` → `invalid_output`, деньги списаны, предохранитель не открыт;
  - доводка el, `rejected` с причинами;
  - лог без текста, без `note` и без ответа провайдера — и при успехе, и при ошибке.
- `translation.module.spec.ts`, 9 тестов: `translatorFor` для каждого провайдера; `claude` без модели или ключа;
  неизвестная модель; Opus + `off`; ключ не попадает в ошибку; `readTranslationConfig`.
- `env.schema.spec.ts`, +19 случаев:
  - по умолчанию `off`;
  - пустые строки из `bff.env.example`;
  - `claude` в проде;
  - `claude` без модели, без бюджета, без ключа;
  - `off` + ключ — старт;
  - `fake` вне прода — да, в проде — нет;
  - границы `RESET_DAY` 0 / 28 / 29, `CONCURRENCY` 0 / 8 / 9, бюджет 0, неизвестные effort и провайдер.
- `glossary.spec.ts`: сверка с фикстурой `common/language/glossary-avoid.spec-fixtures.ts`. Каждая нелокальная форма
  фикстуры есть в целой копии для того же термина и языка; версии равны. Две копии v3 не разойдутся молча.

**Правки кода во второй сессии:**
- **Один клиент на все Claude-профили** (§3): фабрика `TRANSLATORS` создаёт SDK-клиент один раз и отдаёт его каждому
  Claude-профилю. Раньше клиент создавался на профиль — при одном профиле незаметно, у задачи 5 было бы два.
- **Оценка при обрыве — по реальной запасной модели** (§3: «самой дорогой, достижимой через запасную»).
  - Новая таблица `SERVER_FALLBACK_TARGETS` в `claude-thinking.ts`: Opus 5.5 → Opus 5 / Opus 4.8, Sonnet 5.5 →
    Sonnet 5, у Haiku 5.5 запасной нет.
  - Было: запасная всегда по самой дорогой цене таблицы ($25 за выход). Для Opus ничего не меняется, ≈ $0.75; Sonnet
    5.5 — ≈ $0.33 вместо ≈ $0.58.
  - Тест на Sonnet и Haiku.
- Комментарий `glossary.ts` указывает на новый путь фикстуры (`common/language`, после `AURAT-0189`).

**Брейн:**
- `TECH-DEBT.md` №37 — ссылка на модуль.
- `AURAF-0023-glossary.md` — раздел копий: две копии BFF (формы `avoid` в `common/language` и глоссарий целиком в
  модуле), сверка спекой. Заодно исправлен путь и список терминов фикстуры после `AURAT-0189`: в брейне ещё стоял
  `advisors/labels` и только `reader` / `reading`.
- `AURAF-0024` — строка плана «2 — `AURAT-0191`»: код в ветке, в `develop` — вместе с `AURAT-0192`. Строка 003 станет
  BE ✓ только после мёржа (§10), сейчас не отмечена.

## Сверка с `develop` 0410ed7 (AURAT-0189)

- `master` и `missus` перенесены на свежие `origin/develop` 0410ed7 и `origin/master` 94e5a2b: временный коммит →
  `rebase` → `reset --soft`. Конфликтов нет, всё снова застейджено, своих коммитов у веток нет. Ветки не пушились.
- `package.json`: контракты v0.30.0 из `develop` и `@anthropic-ai/sdk` 1.6.0 из 0191 сошлись без конфликта. Lock
  перегенерирован через `npm ci`, ставятся `@aura/contracts` 0.30.0.
- **Глоссарий и `GLOSSARY_AVOID` в `common/language`.** Код модуля их не импортирует: у него своя целая рантайм-копия,
  а фикстура — только для тестов, она исключена из `dist`. Ломать нечего; осталась ссылка в комментарии, она
  исправлена. От дрейфа защищает новая сверка в `glossary.spec.ts`. `TranslatedLanguage` модуль уже брал из
  `common/language/translated-language`.
- `common/language/text-checks.spec-fixtures.ts` из 0189 (`WRONG_ADDRESS`) — тестовая проверка обращения в своих
  текстах сервера, с проверками перевода не пересекается. Её стоит применить к машинным переводам кампании в
  `AURAT-0192`, когда там появятся тесты на реальные ответы.

## Отступление: `beta.messages.create` + свой zod вместо `messages.parse` — проверено по скиллу `claude-api`

**Вывод: отступление верное, оставляю.**

**Что говорит скилл.** Рекомендует `messages.parse` с `zodOutputFormat`. Пишет «`parsed_output` is null if parsing
failed», но тут же предупреждает:
- при `stop_reason: "refusal"` ответ может не совпасть со схемой;
- при `max_tokens` — оказаться неполным.

**Что делает установленный SDK 1.6.0** (`lib/beta-parser.js`):
- `client.beta.messages.parse` есть;
- `parseBetaOutputFormat` при битом JSON или несовпадении со схемой **бросает**
  `AnthropicError("Failed to parse structured output: …")`, а не возвращает `null`.

**Последствия `parse`:**
- на отказе или обрыве по `max_tokens` с частичным JSON ответ вместе с `usage` теряется. Деньги этого вызова не
  записать, а запись денег — §2 шаг 7 и р. 4;
- в `message` ошибки попадает текст разбора, а с ним может попасть кусок ответа модели. Это противоречит правилу
  порта: в `error.message` только `reason`, потому что `logging-worker.host.ts` пишет его в лог.

**Что делает наш путь** — `beta.messages.create` с `output_config.format: { type: 'json_schema', schema }`:
1. Сначала стоимость по `usage` и `usage.iterations`.
2. Потом `stop_reason`: `refusal` → `refused`, `max_tokens` → `invalid_output`, оба оплачены.
3. Потом текстовый блок, найденный по типу, после блоков thinking. Его разбирает своя zod-схема через `safeParse`.

Ограничение формы со стороны API то же самое (structured outputs). Скилл не требует `parse`, он его рекомендует как
удобство. «Don't reimplement SDK functionality» здесь не нарушено: SDK-хелпер не умеет то, что нужно, — не терять
`usage`.

**Попутно сверено по скиллу (кэш 2026-10-06):**
- **Цены.** Opus 5.5 — $4 / $20, кэш: запись $5 (5 мин) / $8 (1 ч), чтение $0.20. Sonnet 5.5 — $2 / $10, запись
  $2.50 / $4, чтение $0.20. Haiku 5.5 — $0.10 / $0.50, свыше 100 тыс. токенов промпта $0.50 / $2.50, чтение 0.1×.
  Запасные модели: Opus 5 и Opus 4.8 — $5 / $25, чтение 0.1×; Sonnet 5 — $2 / $10. Всё совпадает с `claude/prices.ts`.
- **Запасная модель.**
  - `fallbacks: "default"` ставится с бетой `server-side-fallback-2026-07-01`, через `client.beta.messages`.
  - Opus 5.5 идёт на Opus 5 / Opus 4.8 по категории отказа.
  - Sonnet 5.5 — на Sonnet 5, только для `cyber` и `frontier_llm`.
  - У Haiku 5.5 серверной запасной нет.
  - Стоимость берётся из `usage.iterations` (`message` / `fallback_message`), а верхний `usage` — только у
    последней попытки. Так и считает `responseCost`.
- **Thinking.**
  - Opus 5.5: `disabled` — 400 при любом effort, effort по умолчанию `medium` — поэтому ставим его явно.
  - Sonnet 5.5: выключение — `between_tools`, только при effort ≤ `high`.
  - Haiku 5.5: `disabled` — только при effort ≤ `high`.
  - Всё совпадает с `claude-thinking.ts`.
- **Ошибки.**
  - 402 — это `billing_error`; у `APIError` есть `.type` (`error-codes.md`), отсюда `credit`.
  - `APIConnectionTimeoutError` — подкласс `APIConnectionError`, поэтому проверяется раньше.
  - Порядок от частного к общему соблюдён.
- **Кэш.** Минимум префикса у Opus / Sonnet / Haiku 5.5 — 512 токенов; `system` его превышает, это проверяет тест
  адаптера. `temperature` и prefill не передаются: оба дают 400.
- **Таймаут.** `max_tokens` 16 000 без потоковой передачи — в пределах рекомендации скилла (~16 000 для
  непотокового). Бюджет времени задаёт `signal`, `maxRetries: 2` укладываются в него.

## Самопроверка против v2

**§1 Порт** — ✓ дословно: `TextForm`, `TranslationItem`, `TranslationRequest`, `TranslationUsage`,
`TranslationResult`, `TranslationFailure` с `credit`. `TranslationUnavailableError.message = reason`.
`Translator` — абстрактный класс. Наружу модуль экспортирует только `TranslationService`.

**§2 Сервис:**
- Шаги 1–11 — ✓.
- Порядок шагов 1 и 2 переставлен: `off` → `disabled` раньше проверки запроса. Выключенный профиль ничего не
  поддерживает, и иначе любой запрос к нему давал бы `RangeError` вместо `disabled`. Остальные нарушения запроса — до
  бюджета и предохранителя.
- Замок пробы живёт `timeout + 5 с`: проба, повисшая до своего таймаута, ещё держит замок.
- `refused` и `invalid_output` не считаются в серию. Предохранитель трактует их как «провайдер жив»: обнуляет серию и
  закрывает его после паузы. Это строже буквы «не считаются», но в её духе: провайдер ответил.
- Redis не ответил за 1 с → `provider`, повторяемый, без вызова адаптера. Деньги без хранилища не проверить.
- Ошибка записи денег после ответа только логируется: перевод уже оплачен.
- Тексты уведомлений близки к §2, суммы — с центами («$25.00»).

**§3 Адаптеры:**
- ✓ фабрика, старт (`off` без `prepare` / `supports`, отказ — только если не поддержан ни один язык), `Disabled`,
  `Fake`, `Claude`.
- Один клиент — исправлено, см. выше.
- Оценка обрыва — по реальной запасной модели, исправлено.
- `engine` = `claude:<модель>`, с запасной — `…><запасная>`.
- Вызов — `create`, не `parse`: отступление выше.

**§4 Глоссарий** — ✓ копия v3 целиком, zod-схема, отказ старта на битой копии, `GLOSSARY_VERSION = 3`. Матчер — по
семантике `terms.js`. Имя файла — `app-glossary.json`, причина выше.

**§5 Env** — ✓ все переменные и умолчания. «Все или ничего» — только при `claude`. Ключ без Claude-профиля —
предупреждение. `fake` при `NODE_ENV=production` — отказ. `bff.env.example` — блок. `docker-compose` не тронут.

**§6 Файлы** — ✓, плюс `translation-config.ts`, `translation-notices.ts`, `translation-store.ts` и
`translation-store.spec-fixtures.ts` — подменённый Redis с TTL / NX и часами.

**§7 Тесты** — ✓ все группы. Одна строка «профили считаются раздельно» проверена на уровне ключей бюджета
(`translation-budget.spec`), потому что второго профиля пока нет.

**§9** — отличия от `AURAI-0012` реализованы, как в таблице.

**Замечания ревью `006`:**

| # | Как закрыто | Где проверено |
|---|---|---|
| р. 1 | Капс только между `{name}` и `::TOKEN::` | `translation-finish.spec`; el `{pct}% … ΜΑΪΟ` в `translation.service.spec` |
| р. 2 | Профиль `campaign`: свои env, адаптер, бюджет, предохранитель, семафор | Код сервиса и конфига |
| р. 3 | Ключ без `claude` — предупреждение, а не отказ старта | `env.schema.spec`, `translation.service.spec` |
| р. 4 | Обрыв по таймауту пишется оценкой худшего случая; худший вызов Opus ≈ $0.75 | `claude.translator.spec`, `translation.service.spec` |
| р. 5 | Семафор, по умолчанию 3; `rate_limited` не считается | Семафор: тест 23 / 3. `rate_limited`: `translation-breaker.spec` |
| р. 6 | Спека, не код | — |
| р. 7 | `off` без `prepare` / `supports`; недостающий язык → лог и `false`; отказ — только если не поддержан ни один | `translation.service.spec` |
| р. 8 | Проблемы `glossary` и `typography`, нормализация ro / fr / U+00AD | `translation-checks.spec`, `translation-finish.spec`, `translation.service.spec` |
| р. 9 | Замок пробы, сброс серии успехом, `max_tokens` → `invalid_output`, 402 → `credit` | `translation-breaker.spec`, `claude-errors.spec`, `claude.translator.spec` |
| р. 10 | `RangeError` для `speaker` / `context` не с одним `message` | `translation.service.spec` |

**Правила сборки:**
1. SDK знает только `claude/`.
2. Тонкий транспорт — контроллеров нет.
3. Ни ключа, ни текста в логах и ошибках — тесты есть.
4. Деньги перевода — счётчик в Redis, а не леджер; это не правило 4.
5. Неприменимо.
6. Неприменимо.
7. Контракты не менялись.
8. `TranslationService` пока никто не зовёт. Это принято решением 5: 0191 и 0192 мёржатся в `develop` вместе.

## Проверки (итоговое состояние, база `develop` 0410ed7)

| Проверка | Итог |
|---|---|
| `npm run lint` | чисто |
| `npm run typecheck` | чисто: `tsc --noEmit` и клиент desk |
| `npm run build` | ✓; в `dist/modules/translation/glossary/` есть `app-glossary.json`, `*.spec*` в `dist` не попадают |
| `npm test` | **170 сьют, 2263 теста — все зелёные**. Из них модуль перевода — 12 сьют, 122 теста |

**Что ещё не проверено (§8, манор и bff-dev, после мёржа с 0192):**
- старт с `off` и с оставленным ключом;
- живой вызов со staging-ключом — после отдельного одобрения владельца;
- замер p95 для `TIMEOUT_MS`;
- неверный ключ → `auth`;
- бюджет $0.01.

## Передача координатору (§10)

- **`aura-app`** — в `glossary.json` поле `about`: «aura-bff copies only the avoid forms it checks» → «aura-bff copies
  it whole for machine translation (AURAT-0191) and the avoid forms for its checks». Без смены `version`. Здесь не
  делаю: другой репозиторий.
- **`AURAT-0192`** — профиль `campaign`. 23 вызова отдаются сразу, параллельность держит сервис.
  - `supports(campaign, lang) = false` или ошибка — язык показывается по-английски.
  - `rejected` — с причинами в форме.
  - На машинных переводах стоит гонять `WRONG_ADDRESS` из `common/language/text-checks.spec-fixtures.ts`.
- **Мелкая задача после мёржа** — свести две копии глоссария v3 в BFF в одну.
