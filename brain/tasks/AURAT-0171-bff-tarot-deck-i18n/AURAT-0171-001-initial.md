# AURAT-0171-001 — initial (заглушка)

Дата: 2026-11-06
Репо: `aura-bff-manor` (BFF) + `aura-contracts` (описание полей; новая версия — только если меняется схема). Выдан из
`aura-app-manor` (сессия slave-1-9e).
Фича: `AURAF-0023` строка 010; решение `AURAT-0137-006` §3A (колоду переводит сервер, не клиент по `card.id`) и
`AURAF-0020-053` (веб).

## Решение владельца (2026-11-06)

Английские надписи, напечатанные на самих картинках карт («THE SUN», «TWO OF CUPS»), остаются как есть: `imageUrl` и
арт не меняются. Это снимает оговорку строки 010 «сначала — что делать с английскими названиями на артах».

## Что нужно

1. **Колода на 23 языках:** `name`, `keywords` (ровно три слова через « · »), `daily` (одно-два предложения) для 78 карт
   — сейчас `src/modules/tarot/tarot-deck.data.ts` (`TAROT_DECK_SEED`, из brain `AURAT-0049-deck.json`) → таблица
   `tarot_cards` (`schema.prisma:913-930`), сид при каждом деплое (`src/seed.ts:87-98`). ≈ 9,9 тыс. знаков × 23.
   Хранение — решить в спеке (таблица переводов `(cardId, lang)` или сид по языкам); английский — запасной.
2. **Отдача по `lang`:** `GET /v1/tarot/daily`, `POST /v1/tarot/spread/:messageId/pick`,
   `GET /v1/advisors/:advisorId/messages` — карта открытого расклада в истории (`chat.service.ts:137`, `toSpreadDto`,
   `prisma-messages.repository.ts:350`), DTO — `tarot-card.dto.ts:19-27`. `toDto` получает параметр языка; клиенты
   перезапрашивают историю при смене языка. Сокету язык не нужен — инвариант: в сокет уходят только новые вставки
   (`fanOut` лишь при `inserted`, `chat.service.ts:251-258, 277-283`), а у только что выложенного расклада карты ещё нет.
2a. **Резолвер `?lang` пишется здесь** (решение владельца, `AURAT-0168-008` п. 3 — в 0168 у него не было бы
   потребителя). Устройство обязательное, из `AURAT-0168-007-spec-v2.md` §2:
   - чистое ядро `src/common/language/request-language.ts`: `languageFromQuery(raw: unknown, disabled: readonly
     Language[]): Language | null` — код из `LANGUAGES`, не выключенный, иначе `null` (нет параметра, неизвестный код,
     `DE`, массив из `?lang=de&lang=fr`, выключенный); `languageOrDefault(language) → SOURCE_LANGUAGE` при `null`;
   - обёртка `@RequestLanguage()` = `Query(LANGUAGE_QUERY_PARAM, RequestLanguagePipe)`; пайп `@Injectable` берёт
     провалидированный `DISABLED_LANGUAGES` из `ConfigService`; `@ApiLanguageQuery()` — описание для Swagger;
   - выключенный язык → `null` → ответ на английском (выключатель работает и для клиентов со старым кэшем конфига);
     `Accept-Language` не читать;
   - тесты: нет параметра, неизвестный, `DE`, массив, выключенный `mt` при `DISABLED_LANGUAGES=mt` → `null`;
     `languageOrDefault`.
   Контракты `v0.28.0` заморожены: `LANGUAGES`, `type Language`, `SOURCE_LANGUAGE`, `isLanguage`,
   `LANGUAGE_QUERY_PARAM` (помощника «неизвестное → en» в контрактах нет); `DISABLED_LANGUAGES` в `env.schema` — из 0168.
3. **Переводы** — по глоссарию aura-app (`scripts/i18n/glossary.json`, гайд `AURAF-0023-glossary.md`): устоявшиеся в
   каждом языке названия арканов и мастей, не дословный перевод; правила `tarot-deck.data.spec.ts` (форма `keywords`)
   — на всех языках. Не `@sensitive`: ревью носителями желательно, не обязательно.
4. Приватная заметка чаттеру `Card chosen: ${card.name}` (`tarot.service.ts:158`) — по-английски, она для чаттера.
5. Контракт: `TarotCard.name` — «English name» → «на языке запроса»; поля не меняются.

Клиенты — в `AURAT-0169` (приложение) и `AURAT-0170` (веб): фразы с именем карты, перезапрос при смене языка.

Зависимость от `AURAT-0168` (`aura-bff-manor` slave-1): спека одобрена 2026-11-06 (`007-spec-v2`, `008-approval`;
полный текст — `/Volumes/Work/personal/ai-manors/aura-bff-manor/project/slave-1/missus/brain/tasks/AURAT-0168-bff-i18n-lang-marker/AURAT-0168-007-spec-v2.md`,
в missus пока не закоммичен), код ещё пишется. Перевод колоды и хранение — сразу; перед резолвером и маршрутами —
влить `develop` после мёржа 0168 (нужны `DISABLED_LANGUAGES` и контракты `v0.28.0`). Запущена 2026-11-06.

## Слова владельца (дословно, 2026-11-06)

> «давай теперь шаг 5 серверный, потом по таро, надписи на самих картинках оставляем как есть»

## Контекст слота

Манор `aura-bff-manor`, слот `slave-2`, ветка `feature/AURAT-0171-bff-tarot-deck-i18n` от `develop` @ `c8d78cf`.
Параллельно: `AURAT-0168` (slave-1, контракты `v0.28.0` + BFF). Перед сборкой — `npm ci` (контракты в `node_modules`
манора устарели). ID здесь не минтятся (выданы в `aura-app-manor`).
