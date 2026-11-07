# AURAT-0175-001 — initial (заглушка)

Дата: 2026-11-07
Репо: `aura-web-manor` (веб). Выдан из `aura-app-manor` (сессия slave-1-ac) — клиентская часть `AURAT-0173`.
Фича: `AURAF-0023` строка 011 (подписи советников).

## Откуда

`AURAT-0173` (aura-bff-manor slave-1): сервер отдаёт `Advisor.role` и `Advisor.specialties` на языке запроса (`?lang`)
и новое поле без языка `Advisor.topics: AdvisorCategory[]` (контракты `v0.29.0`, по умолчанию `[]`; тег — с одобрения
владельца). Спека и передача клиентам:
`/Volumes/Work/personal/ai-manors/aura-bff-manor/project/slave-1/missus/brain/tasks/AURAT-0173-bff-advisor-labels-i18n/AURAT-0173-007-spec-v2.md`
и `009-execute.md`. Веб уже шлёт `?lang` во все запросы (0170), поэтому типы переключатся в день выкатки сервера.

## Что нужно

1. **Подбор советника (`/match`) — по `topics`, а не по английским словам.** Сейчас
   `src/pages/match/lib/match-advisors.ts:20-24` ищет `TOPIC_WORDS` (`config/match.ts:9-18`, «The catalog serves
   specialties in English») внутри `specialties`; с переведёнными специализациями уровень «also» молча опустеет у всех
   неанглийских посетителей. Перейти на `topics`, убрать `TOPIC_WORDS`. Паритет со старым подбором 0173 закрепила
   тестом на сервере — сверить.
2. **Язык в ключе кэша каталога:** `src/entities/advisor/api/advisors-api.ts:13` — `build.query<Advisor[], undefined>`;
   сделать язык аргументом, как в `entities/tarot/api/daily-card-api.ts:9-18`, чтобы смена языка перечитывала каталог,
   а опоздавший ответ ложился под свой ключ.
3. **Контракты:** пин на `v0.29.0`, когда тег будет на GitHub (`topics`). В типе `Advisor` (`z.infer` — выходной тип)
   `topics` обязательное, `.default([])` действует только на входе — фикстуры перестанут компилироваться: `const MIA:
   Advisor` в `src/app/__tests__/{booking,season,psp,book-now}.test.tsx`, фабрики в
   `{chats,sessions,daily,home,live-session,advisors}.test.tsx`, `features/advisor-filters/lib/__tests__/filter-advisors.test.ts:13`.
   В `pages/match/lib/__tests__/match-advisors.test.ts:5` — настоящие темы персон, чтобы тест подбора проверял `topics`
   (ревью кода `0173`).
4. **Глоссарий v3** — взять копию из приложения по `version` (`AURAT-0174`: el psychic «Διορατικός / Διορατική»).
5. Новые строки, если появятся, — на 24 языках.

## Порядок выкатки

Сразу после сервера 0173, в одном окне: до выкатки сервера `topics` нет, а после неё старый подбор не работает у
неанглийских посетителей. `topics` по умолчанию `[]`, так что веб с новым подбором переживает и старый сервер.

Запущена 2026-11-07 по команде владельца: «запускай 0174 и 0175».

## Контекст слота

`aura-web-manor` slave-1, ветка `feature/AURAT-0175-web-advisor-labels-i18n` от `develop` @ `154c842`. ID выданы в
`aura-app-manor`, здесь не минтятся. `topics` — из контрактов v0.29.0: тега на GitHub ещё нет (пуш — с одобрения
владельца после его ревью 0173); до тега — тип по спеке или локальная сборка `aura-contracts`, ветка
`feature/v0.29.0-advisor-labels-i18n`. Глоссарий v3 делает `AURAT-0174` в приложении (app slave-0) — веб берёт копию
по `version`, сам `glossary.json` не правит. Спеку и код проверит координатор (slave-1-ac). Коммит и мёрж — только с
одобрения владельца.
