# AURAT-0173-004 — context

Дата: 2026-11-07

## Код (`aura-bff` @ `bbc4c6c`) — источник истины

- **Данные.** `advisors.role` (`String`) и `advisors.specialties` (`String[]`) — из `ADVISOR_SEED`
  (`src/modules/advisors/advisor-seed.data.ts`, 8 персон), сид — upsert при каждом деплое. Бэкофис советников не
  правит — тексты меняются только правкой сида.
- **Словарь.** `role` — термины через « · »: 10 терминов (Psychic Reader, Medium, Psychic, Channeler, Tarot,
  Energy Healer, Clairvoyant, Love & Relationships, Astrologer, Card Reader). `specialties` — 34 разных термина
  (Mediumship ×3, Clairvoyance ×2, Tarot ×2, остальные по одному). Пересечения с `role` — `Tarot` и «Love &
  Relationships» / «Love & relationships» (регистр разный).
- **Род.** Советники в seed — 6 женских имён, 2 мужских (Alisher, Ivan); у Labsang Devi пол из био не ясен. Поля
  «пол» у советника нет. 7 из 10 терминов `role` — названия людей с родом в большинстве языков (de
  Hellseher/Hellseherin, fr voyant/voyante, pl jasnowidz/jasnowidząca, cs jasnovidec/jasnovidka…).
- **Куда уходит `Advisor`.** Клиенту — только `GET /v1/advisors` (`AdvisorsService.toDto`), публичный; отдельного
  `GET /advisors/:id` нет — профиль рисуется из каталога. В сокет, историю, сессии `role` / `specialties` не попадают
  (в контрактах этих полей нигде больше нет).
- **Английский остаётся:** `desk-attributes.ts` → атрибут Chatwoot `advisor_role`; `agent-desk.service.ts` →
  профиль советника в desk (роль и чипы специализаций) — интерфейс чаттеров.
- **Кэш.** HTTP-кэша и ETag у `GET /v1/advisors` **нет** (ETag есть только у `/v1/app-config`, `AURAT-0147`).
  Заглушка (`001` п. 3) говорит о ключе кэша и ETag по языку — на сервере ключевать нечего; `lang` — в URL, любой
  кэш по URL уже различает языки. Кэш каталога — у клиентов.
- **Резолвер** — готов (`0171`): `@RequestLanguage()`, `@ApiLanguageQuery()`, `languageOrDefault`,
  `request-language.routes.spec.ts` (HTTP через Fastify).
- Комментарий над `AdvisorsController`: «The day a field here starts to depend on the caller, this stops being
  public» — язык зависит от запроса, не от того, кто спрашивает; маршрут остаётся публичным, комментарий уточнить.

## Контракт (`aura-contracts` `v0.28.0`)

`Advisor.role: z.string()` — JSDoc «Short professional line, e.g. "Psychic Reader · Medium"»; `specialties:
z.array(z.string())` без описания. Схема не меняется.

## Глоссарий приложения (`aura-app` `scripts/i18n/glossary.json` v2)

- `psychic` (человек, мужская форма: de Hellseher, fr voyant, pl jasnowidz, it veggente, es vidente…; note: «The
  category “Psychic” on the web is the practice — translate the person here»), `medium` (de Medium, fr médium,
  hr medij…), `tarot` (it «tarocchi», bg «таро», et/lt/lv «taro»), `reader` («never the word for someone reading a
  book»), `specialties`.
- `away`: «The advisor’s gender is unknown» — приложение род не знает; сервер знает персону.
- Категории (`AURAT-0164`, `screens/advisors/config/locales`): LOVE de «Liebe», fr «Amour»; PSYCHIC — практика
  (de «Hellsehen», fr «Voyance», pl «Jasnowidzenie»); TAROT — «Tarot».
- Обращение — по `register` (для коротких подписей не важно).

## Противоречия

- `001` п. 3 «ключ кэша и ETag по языку» — на сервере кэша нет (см. выше). В спеке: ничего не делаем, записываем.
- Глоссарий даёт только мужскую форму `psychic` — для женских персон нужна женская (решение 1 в спеке).
