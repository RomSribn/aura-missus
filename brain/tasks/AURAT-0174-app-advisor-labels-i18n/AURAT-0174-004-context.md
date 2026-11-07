# AURAT-0174-004 — context

## Код (ground truth)

- `entities/advisor/model/catalog-store.ts` — `load()` отдаёт общий `inFlight`; `generation` растёт только в `reset`.
  Смена языка во время загрузки вернула бы старый запрос. Образец — `entities/tarot/model/daily-card-store.ts`:
  `load(force)` + счётчик `latest` (садится только последний запрос), `finally` чистит `inFlight` только свой.
- `use-advisor-catalog-sync.ts` — только `onAuthStateChanged`. Образец — `use-daily-card-sync.ts`: `onLanguageChange`
  → `load(true)`, если пользователь известен. Язык берётся в `http-client` в момент запроса (после `i18nReady()`).
- Потребители `load()` без аргументов: `use-advisors` (повтор), `use-write-review`, `ensureLoaded` (push). Не ломаются.
- Тип в UI: `AdvisorRow` и `BookSessionScreen` — одна строка `${role} · $x/min`, `numberOfLines={1}`.
  `TopAdvisorRow`, `SessionHero`, `BookReviewScreen`, `AdvisorHero` — тип один в строке, обрезается сам, цены там нет.
- `screens/advisors/lib/filter-advisors.ts` — `${name} ${role}`, без изменений.
- `scripts/i18n/glossary.json` v2: el `psychic` = «μέντιουμ» = el `medium`. el-строки приложения: onboarding уже
  «μέντιουμ, συμβούλους ταρό και διορατικούς» (psychics = διορατικοί); splash «ΜΑΝΤΕΙΑ», категория «Διόραση» — это
  практика, не человек. **Править el-строки не нужно**, только запись глоссария. `use` — совет (`translate.mjs check`),
  тест глоссария проверяет только `avoid`.
- Контракты: `package.json` → `#v0.28.0`; v0.29.0 = `Advisor.topics` (`.default([])`, в выходном типе обязательное) +
  JSDoc. Литералы `Advisor`: `src/test-support/advisor.ts` (`BASE`), `screens/daily-card/lib/__tests__/tarot-advisor.test.ts`.

## Ширины (HankenGrotesk-Regular из бандла, advance widths; совпадают с таблицей `0173-009`)

Цена « · $3.20/min»: 69.6 pt при 13 (de «· 3,20 $/Min.» — 76.2), 66.9 при 12.5. Звёзды на экране брони (13, с числом) ≈ 90.

| место | ширина под тип при 360 / 393 / 412 pt | самые длинные типы |
|---|---|---|
| `AdvisorRow`, тип + цена в строке (13pt) | 146 / 179 / 198 | en 147, lt 192, ro 184, nl 178, pl / et 176 |
| `BookSessionScreen`, тип + цена в строке (12.5pt) | 63 / 96 / 115 | en 141, lt 184, ro 177 |
| `BookSessionScreen`, тип своей строкой | 130 / 163 / 182 | те же |

Сейчас на экране брони цена не видна уже в английском: строка «Psychic Reader · Medium · $3.20/min» = 207 pt при
бюджете 128 (360 pt).
