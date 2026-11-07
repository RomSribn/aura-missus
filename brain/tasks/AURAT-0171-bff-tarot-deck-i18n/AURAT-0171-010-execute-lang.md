# AURAT-0171-010 — execute, этап 2: резолвер `?lang` и три маршрута

Дата: 2026-11-06 · Статус: готово к ревью владельца в IDE. Не закоммичено.

## Влито

`develop @ c24d55c` (мёрж `AURAT-0168`, контракты `v0.28.0`, `DISABLED_LANGUAGES`) — fast-forward ветки; правки
этапа 1 отложены в stash с меткой и возвращены без конфликтов; `npm ci` (lock — `v0.28.0`).

## Файлы (aura-bff), сверх `009`

Новые — `src/common/language/` (устройство `AURAT-0168-007` §2, без отступлений):
- `request-language.ts` — `languageFromQuery(raw, disabled)` (null: нет, неизвестный, `DE`, массив, выключенный),
  `languageOrDefault`;
- `request-language.pipe.ts` — `RequestLanguagePipe`, `DISABLED_LANGUAGES` из `ConfigService`, не бросает;
- `request-language.decorator.ts` — `@RequestLanguage()` = `Query(LANGUAGE_QUERY_PARAM, RequestLanguagePipe)`,
  `@ApiLanguageQuery()` (enum `LANGUAGES`, описание правил);
- `request-language.spec.ts` — 8 тестов (известный, нет параметра / пусто, `ru` / `de-AT`, `DE`, массив, `mt` при
  выключенном `mt`, `languageOrDefault`).

Изменены:
- `src/contracts/language.ts` — реэкспорт `LANGUAGE_QUERY_PARAM` (замечание 13).
- `deck-translations/index.ts` — `TranslatedLanguage = Exclude<Language, typeof SOURCE_LANGUAGE>`: новый язык в
  контракте не соберётся без своей колоды; локальный союз и `DeckLanguage` удалены.
- `localize-card.ts`, `tarot-card.dto.ts`, `tarot.service.ts`, `chat.service.ts` — контрактный `Language`;
  `'en'` → `SOURCE_LANGUAGE`.
- `tarot.controller.ts` (`getDaily`, `pickSpreadCard`), `chat.controller.ts` (`getHistory`) —
  `@RequestLanguage() language` → `languageOrDefault(language)`, `@ApiLanguageQuery()`.
- `src/contracts/openapi.ts` — `tarotCardOpenApi`: `name` / `keywords` / `daily` — на языке запроса, `imageUrl` —
  один на все языки (только этот блок; остальные неотформатированные места файла были такими до задачи).
- `tarot.smoke.spec.ts` — заглушка `ConfigService` по ключу (`DISABLED_LANGUAGES: ['mt']`, замечание 10); новые
  09–11: `?lang=de` → немецкий с тем же `imageUrl`; `DE`, два `lang`, `ru`, пустой → английский, 200; `mt`
  выключенный → английский. Старые 09, 10 → 12, 13.
- `deck-translations.spec.ts` — набор языков сверяется с контрактным `LANGUAGES` без `en`.
- `chat.service.spec.ts` — новый тест маркеров из `0168` получил язык.
- `README.md` — блок «Response language», `&lang=` у трёх маршрутов, строка про `deck-translations/` в дереве.

## Проверки

- `npm run lint`, `npm run typecheck`, `npm run build` — чисто.
- `jest` целиком: 150 наборов, 2 011 тестов; 2 упали в `backoffice-promo-codes.smoke.spec.ts` (модуль не тронут,
  набор шёл 123 с под общей нагрузкой); отдельно — 12 / 12 зелёные. Таймаут под нагрузкой, не регрессия.

## Осталось

- JSDoc `TarotCard.name` в `aura-contracts` (`src/tarot.ts:42`, «English name») — одна строка в `main` без тега
  (решение 2 — А); чекаут контрактов общий, поэтому правка — вместе с одобрением коммита и пуша.
- `AURAF-0023` строка 010, колонка BE — ✓ после проверки в маноре.
- Манор после мёржа: `GET /v1/tarot/daily?lang=de`; `?lang=mt` при `DISABLED_LANGUAGES=mt` → английский; `pick` с
  `?lang=de` — первое и повторное нажатие; история с открытым раскладом `?lang=fr`; Swagger — параметр `lang` у
  трёх маршрутов.
