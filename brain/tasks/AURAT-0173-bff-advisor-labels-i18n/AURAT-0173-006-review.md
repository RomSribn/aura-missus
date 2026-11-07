# AURAT-0173-006 — review спеки 005 + решения владельца

Дата: 2026-11-07 · Ревью: координатор `slave-1-ac` (`aura-app-manor`) по просьбе владельца; владелец сказал «передавай».
Исходный отчёт (англ., временный): `…/aura-app-manor-project-slave-1/…/scratchpad/wf-spec-0173-review.md` — суть ниже.

## Решения владельца (переданы координатором)

1. Род — **А**: род персоны в данных, две формы; клиентам род не уходит.
2. `role` — **А**: строка как есть, перевод по терминам через « · ».
3. JSDoc в контрактах — **А**: коммит в `main` без тега, пуш с одобрения. (Пересматривается в v2: замечание 1 меняет
   схему — см. `007` решение 4.)
- Пол Labsang Devi владелец **не указал** — спросить его самого, по фото, не по имени.

## Замечания (все 8 проверены по коду — подтверждаются)

**Важные**
1. **Подбор на вебе (`/match`) сломается в день выкатки.** `aura-web` `pages/match/lib/match-advisors.ts:20-24` ищет
   английские `TOPIC_WORDS` (`config/match.ts:9-18`: «The catalog serves specialties in English») в `specialties`;
   веб шлёт `?lang` во все запросы (`base-query.ts:86`) → уровень «also» молча пустеет для неанглийских посетителей.
   Предложение: язык-независимое поле `topics: AdvisorCategory[]` у советника из закрытого словаря; веб убирает
   `TOPIC_WORDS`. Временный вариант — веб ранжирует по отдельному чтению `?lang=en`.
2. **«Старые сборки ничего не заметят» — неверно.** Приложение (`0169`) и веб (`0170`) уже шлют `?lang`. Кэш каталога
   язык не учитывает: app `entities/advisor/model/catalog-store.ts:19-49` (generation — только при сбросе),
   `use-advisor-catalog-sync.ts:17-29` (перезагрузка только по смене uid); web `advisors-api.ts:13`
   (`build.query<Advisor[], undefined>`). Нужен раздел «порядок выкатки» и конкретная передача: app — подписка на
   `onLanguageChange` (как `use-daily-card-sync.ts:22`) + generation; web — язык в аргументе `getAdvisors`, как
   `daily-card-api.ts:9-18`. Места отрисовки роли: `AdvisorRow`, `TopAdvisorRow`, `BookSessionScreen`, `SessionHero`,
   web session-detail и advisor-page.
3. **Глобальная проверка «термины не сливаются» воюет с синонимами** (Psychic Reader / Psychic / Clairvoyant → de
   «Hellseher(in)», fr «voyant(e)»; da psychic = «clairvoyant») и противоречит §3 (Clairvoyance / Psychic reading
   словом категории). Ломается на деле повтор внутри персоны: глоссарий v2 el psychic = el medium = «μέντιουμ» →
   Veronica «Μέντιουμ · Μέντιουμ · Ταρό»; профиль ключует чипы текстом (`AdvisorProfileScreen.tsx:116-117`).
   Проверка — по персоне и языку. el psychic — «Διορατικός / Διορατική»; правка `glossary.json` aura-app (v3) — в
   передачу.

**Средние**
4. **Род не дойдёт до localize:** `AdvisorRecord` (`advisors.repository.ts:11-29`) и `toRecord`
   (`prisma-advisors.repository.ts:77-93`) — явная проекция без `gender`; тест сервиса на фальшивом репозитории не
   поймает. Нужны: Prisma enum, `AdvisorRecord.gender`, `toRecord`, тест цепочки сид → upsert → `toRecord` → `toDto`;
   в DTO и desk `gender` нет. Фейки `AdvisorRecord` в спеках sessions / reviews / agent-desk.
5. **Длина:** лимиты по термину не ловят собранную строку; в списке роль и цена в одной строке
   (`AdvisorRow.tsx:68-71`, 13pt): en 215pt из 216, de 240, pl 271. Тест на собранную роль по персоне × 23; ширина в
   pt в `execute`; передача — роль и цена в двух `Text` (`AdvisorRow`, `BookSessionScreen`).
6. **Запретные формы глоссария** (`reader` / `reading` / `psychic` / `medium`, `avoid`) на сервере не проверяются;
   `reading` в §3 не упомянут. Тест по началу слова, как `aura-app scripts/i18n/terms.js`, с версией глоссария.

**Мелкие**
7. `guest-access.smoke.spec` — гостевой `GET /v1/advisors?lang=de` (200, в `list` — `de`); заглушке `ConfigService`
   — `DISABLED_LANGUAGES: []`, иначе 500.
8. Desk: `desk-attributes.ts:74` («Persona title as the app shows it») и `agent-desk.service.ts:180-181` («what a client
   reads in the app») станут неправдой → переформулировать; описание атрибута дойдёт до Chatwoot только со
   следующим `desk:setup`; строка в заметки чаттеру, как в `0171`.

Отклонено ревьюером как дубли / вне задачи: поиск по переведённой роли — поведение клиента, так и нужно.

Дальше — `007-spec-v2.md`.
