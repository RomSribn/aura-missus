# AURAT-0175-004 — context

Дата: 2026-11-07

## Сервер (`AURAT-0173`, `007-spec-v2`, `009`, `010`, `011`, `012`)
- `topics` = объединение тем английских специализаций в порядке `AdvisorCategory` (`LOVE`, `TAROT`, `PSYCHIC`), без
  языка. Темы терминов (BFF `advisor-label-terms.ts`) — ровно то, что находил `TOPIC_WORDS` веба; паритет — тест BFF.
- Темы персон сида: olivia LOVE·PSYCHIC, sunshine TAROT·PSYCHIC, veronica TAROT·PSYCHIC, may PSYCHIC, labsang PSYCHIC,
  alisher PSYCHIC, marta LOVE, ivan LOVE·TAROT.
- Контракт: `topics: z.array(AdvisorCategory).default([])` — во входном типе необязательно, в выходном (`Advisor`) —
  обязательно.
- Длины: самая длинная роль — lt «Ekstrasensė · Čenelingo praktikė» (32 знака), en сейчас до 24.

## Веб (код, ground truth)
- Подбор: `pages/match/lib/match-advisors.ts` `readsOn` — подстроки `TOPIC_WORDS` (`pages/match/config/match.ts`) в
  `specialties`. Других потребителей `TOPIC_WORDS` нет.
- Каталог: `entities/advisor/api/advisors-api.ts` — `getAdvisors: build.query<Advisor[], undefined>`; вызовы — только
  `entities/advisor/model/use-advisors.ts` (`useAdvisors`, `useAdvisor`, оба `useGetAdvisorsQuery(undefined)`).
  `updateQueryData('getAdvisors', …)` нигде нет; тег `Advisors` инвалидирует `write-review` — по тегу, все ключи.
- Образец: `entities/tarot/api/daily-card-api.ts` (`DailyCardArgs { tz, language }`) + `model/use-daily-card.ts`
  (`useTranslation()` для подписки на смену языка, `currentLanguage()` из `@/shared`); тесты — `app/__tests__/daily.test.tsx`
  «a change of language reads the card again» и «an answer still on its way…».
- Места роли и специализаций (рендер строки сервера, менять нечего): `entities/advisor/ui/advisor-tile.tsx` (`.meta`
  12.5px, переносится), `advisor-row.tsx` (чипы), `pages/advisor/ui/advisor-page.tsx` (eyebrow + чипы),
  `widgets/session-detail/ui/session-detail.tsx` (`.role`). Обрезки нет — длинная роль перенесётся; смотреть в маноре.
- Фикстуры `Advisor` без `topics`: `app/__tests__/{booking,season,psp,book-now,chats,sessions,daily,home,live-session,advisors}.test.tsx`,
  `features/advisor-filters/lib/__tests__/filter-advisors.test.ts`, `pages/match/lib/__tests__/match-advisors.test.ts`.

## Глоссарий
- `glossary.json` приложения: «aura-web takes a copy with this version and keeps no second one»; `AURAF-0023-glossary.md`
  — «Веб берёт копию… в своей задаче», «Вебу — взять копию v2». **У веба копии нет** и нет проверки, которая её читала бы.
  Принять глоссарий в веб = копия + тест «ни один перевод не содержит `avoid`» → тест сразу упадёт на известных
  расхождениях веба (`AURAF-0023-glossary.md` «Расхождения веба», ~20+ строк: ga «léitheoir», fr «chat»…).
- В этой задаче новых строк нет; el-строки веба про psychic уже «Διόραση» / «διόραση» — проблемы v2 (psychic = medium)
  у веба нет.

## Противоречие
Заглушка: «глоссарий v3 — копией из приложения по version». Код: копировать некуда — у веба нет ни копии, ни
потребителя; копия без проверки — мёртвый файл, копия с проверкой — отдельная задача по правке расхождений. → решение
владельца в спеке.
