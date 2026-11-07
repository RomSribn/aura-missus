# AURAT-0184-004 — context

Дата: 2026-11-07

## Код (`aura-bff` @ `167f0b9`) — источник истины

- **Данные.** `advisors.tagline` / `bio` / `greeting` (`String`) — из `ADVISOR_SEED`
  (`src/modules/advisors/advisor-seed.data.ts`, 8 персон); сид — upsert при каждом старте контейнера, `update: catalog`
  (тексты перезаписываются; правка — только правкой сида, бэкофис советников не правит). Комментарий сида: **био —
  дословно от владельца** («ADVISORS REAL.xlsx»), слоганы и приветствия выведены из био и утверждены в `AURAT-0013`.
- **Объём английского:** слоганы 38–58 знаков; приветствия 124–210; био 648–1006 (≈ 6,7 тыс. знаков на 8 био). Итого
  ≈ 8,2 тыс. знаков × 23 языка.
- **Особенности английского текста.** Био — дословный текст владельца с огрехами: смена лица («and understands»,
  «leaves one uplifted»), безличный оборот у May («The Healing Attunements offered… is a specialty offered here»),
  «chakra's», переносы строк `\n` (Sunshine, Marta), цитаты в “ ” (Marta), «Reader & Healer» / «Psychic Reader» /
  «reading professionally» / «30 years reading» (глоссарий: reader / reading — не «читатель» / «чтение»). У Marta
  вопросы клиента о партнёре — «What does he feel about me?», «Is he my soulmate?» (и в приветствии).
- **Точка отдачи** — `AdvisorsService.toDto(advisor, language)`: уже переводит `role` / `specialties`
  (`localize-advisor-labels.ts`, `AURAT-0173`); `tagline` / `bio` / `greeting` — `advisor.*` как есть. Комментарий
  `localize-advisor-labels.ts` говорит «stay as stored until … decision 8» — устарел с решением 8 = Б.
- **Род** — `advisors.gender` / `AdvisorSeedRow.gender` (`0173`): F — olivia, sunshine, veronica, may, marta;
  M — labsang, alisher, ivan. Протянут до `toDto`.
- **Образец — колода `0171`:** `deck-translations/<lang>.ts`, `Record` по id, у каждой записи `source` — отпечаток
  английского (sha256, 12 hex); spec сравнивает с сидом и называет всё, что надо перевести заново. Перевод
  накладывается в одной точке (`localizeCard`), в базу не пишется; нет перевода → английский.
- **Где ещё эти поля:** `agent-desk` (профиль советника у чаттера — `tagline` / `bio`) — английский, не трогаем.
  В Chatwoot, историю, сокет, пуши слоган / био / приветствие не уходят.
- **Приветствие нигде не хранится и не отправляется.** На сервере `greeting` есть только в каталоге. OpenAPI и JSDoc
  контракта: «Seeds the first message of a new thread» — неточно: клиенты рисуют его сами (см. ниже).
- **`glossary-avoid.spec-fixtures.ts`** — копия запретных форм `reader` / `reading` из глоссария **v2**; в v3 эти
  формы те же (изменился el `psychic`), версию поднять до 3.

## Контракт (`aura-contracts` `v0.29.0`, `main` = `308b95e`, чисто)

`tagline: z.string()` — «One-line hook for list and profile headers.»; `bio: z.string()` — без JSDoc; `greeting` —
«Seeds the first message of a new thread with this persona.». Схема не меняется; JSDoc о языке — по желанию (как
`TarotCard.name`, `3f12472`, коммит в `main` без тега).

## Глоссарий и обращение (`aura-app` `scripts/i18n/glossary.json` v3, `AURAF-0023-glossary.md`)

- `register`: «вы» — bg, cs, el, fr, hr, lt, lv, pt (você подразумевается), sk, sl; «ты» — da, de, es, et, fi, ga,
  hu, it, mt, nl, pl («Ty», «Twój», «Ciebie» — с заглавной), ro, sv. pl — без прошедшего времени с родом человека
  (-łeś/-łaś); fr — U+00A0 перед ? ! : ; » и после «; ro — ș ț с запятой; pt — европейский; es — Испании.
- Термины: `psychic` (человек), `medium`, `tarot` (it «tarocchi», bg «таро», et / lt / lv «taro»), `reading` = сеанс
  (de «Deutung», fr «consultation»; запрет de «Lesung», fr «lecture»), `reader` = советник (запрет «читатель» в 23
  языках), `advisor`.

## Клиенты — проверено по коду (aura-app, aura-web — manor master)

- **Приветствие — пузырь только в интерфейсе.** aura-app `screens/chat-thread/model/use-chat-thread.ts:84-104`:
  «The persona greeting is a UI-only intro bubble — never stored or sent»; берётся из `advisor.greeting` каталога,
  показывается в начале истории. aura-web `widgets/chat-thread/model/use-chat-thread.ts:104-115` — то же. Чаттер его
  не видит.
- Каталог у обоих клиентов уже в ключе языка и перечитывается при смене (`AURAT-0174` / `0175`).
- **Места показа** (нигде нет `numberOfLines` / line-clamp — текст переносится свободно; шрифт — HankenGrotesk):
  - `tagline` — **в приложении не показывается**; веб: страница советника (16px, колонка рядом с фото 300px),
    `MatchCard` (13.5px, сетка в 3 колонки), `AdvisorRail` в чатах (13px, ширина ~300px), `AdvisorRow` каталога (13px).
  - `bio` — приложение `AdvisorProfileScreen.tsx:110` (14.5/22, на всю ширину); веб `advisor-page` (15.5px,
    `max-width: 720px`, `white-space: pre-line`). `\n` сохраняются обоими.
  - `greeting` — пузырь чата: приложение `MessageBubble` (14.5/20, `maxWidth 76%`), веб `message-bubble` (14.5px,
    `max-width 68%`, `pre-wrap`).
- Поиск приложения — только `name` и `role`; подбор веба — `topics`. На слоган / био / приветствие ничего не завязано.
- **Строка, которая станет неправдой:** aura-app `features/app-language/config/locales/*.ts`, ключ `untranslated` —
  «Advisor profiles and tarot cards stay in English for now.» (комментарий — «their greetings» тоже), в шторке языка
  (`LanguageSheet.tsx:179`). Про таро она неверна уже с `0171` / `0169`. На вебе такой строки нет.

## Противоречия

- **Заглушка `001` п. 5 «клиентам ничего делать не нужно»** — почти: код клиентов не меняется, но строка `untranslated`
  в приложении после выкатки врёт → правка текста приложения (передача, номер — от координатора).
- **Заглушка `001` п. 3:** «первое сообщение треда создаётся на языке разговора … до этого приветствие остаётся
  английским». Первого сообщения на сервере нет — приветствие рисует клиент из каталога, т. е. уже на языке запроса.
  Решение владельца в спеке (решение 1).
