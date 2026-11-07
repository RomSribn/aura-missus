# AURAT-0171-004 — context

Дата: 2026-11-06

## Код (ground truth, `develop @ c8d78cf`)

- Колода: `src/modules/tarot/tarot-deck.data.ts` — `TAROT_DECK_SEED`, 78 строк; английские тексты ≈ 9,9 тыс. знаков.
  Правила — `tarot-deck.data.spec.ts`: ровно три слова через « · », `daily` ≤ 160, 78 разных `daily`, никаких
  предсказаний (`you will`, `promise`…), семь карт дизайна — посимвольно.
- Таблица `tarot_cards` (`schema.prisma:913-930`); комментарий над моделью уже предвидит «translations table, not
  `name_ru` columns». Сид — upsert по id при каждом деплое (`src/seed.ts:87-98`), ничего не удаляет.
- Карта уходит клиенту в одном месте — `toTarotCardDto(card, assetsBaseUrl)` (`tarot-card.dto.ts`), из двух
  путей:
  - `TarotService` — `GET /v1/tarot/daily` (`findDailyCard` / `dealDailyCard`, include `card`) и
    `POST /v1/tarot/spread/:messageId/pick` (`pickSpreadCard` → `findCard` / `findFirst include card`);
  - `ChatService.getHistory` → `toDto` → `toSpreadDto` — карта открытого расклада; читается
    `MESSAGE_INCLUDE = { spread: { include: { card: true } } }` (`prisma-messages.repository.ts:62-64`), тот же
    include у всех чтений сообщений (upsert, удаление).
- Сокет: `fanOut` только при `inserted`; у только что выложенного расклада карты нет (`picked: null` → без
  `card`). Ответ `pick` в сокет не уходит. Язык в сокете не нужен — подтверждено.
- Заметка чаттеру `Card chosen: ${card.name}` (`tarot.service.ts:158`) читает `findCard` — остаётся английской.
- Бэкофис колоду не редактирует (тексты меняются только через сид).
- Swagger: `tarotCardOpenApi.name` — «English name» (`src/contracts/openapi.ts:34`).
- Смоук `tarot.smoke.spec.ts` — фейковый `TarotRepository`, реальный контроллер/пайпы по HTTP.

## Контракты

- `aura-contracts/src/tarot.ts:42` — JSDoc `/** English name, e.g. "The Sun". */`; схема полей не меняется.
- `v0.28.0` (`AURAT-0168`) ещё не вышел: ветка `feature/AURAT-0168-v0.28.0` в общем чекауте. Из него нужны
  `LANGUAGES`, `Language`, `SOURCE_LANGUAGE`, `isLanguage`, `LANGUAGE_QUERY_PARAM`; из BFF 0168 — `DISABLED_LANGUAGES`
  в `env.schema`.

## Переводы

- Глоссарий v2: `tarot` (bg «таро», it «tarocchi», et/lt/lv «taro»…), `tarot-card` (карта/Karte/carte…),
  `tarot-spread`; обращение по языкам — таблица в `AURAF-0023-glossary.md` (формальное: bg, cs, el, fr, hr, lt, lv,
  pt, sk, sl; остальные на «ты»). Терминов для арканов и мастей в глоссарии нет — берутся устоявшиеся в каждом
  языке названия колоды Райдера–Уэйта.
- Не `@sensitive`: ревью носителями желательно, не обязательно (`001` п. 3).

## Противоречий нет

Стаб предлагает хранение «таблица `(cardId, lang)` или сид по языкам» — выбор в спеке.
