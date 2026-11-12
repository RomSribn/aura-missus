# AURAT-0206-007 — execute

Дата: 2026-11-11. Слот `slave-1`, ветка `feature/AURAT-0206-promo-redemptions`. Не закоммичено —
всё застейджено на ревью в IDE.

## Файлы (aura-bff)

| Файл | Что |
|---|---|
| `promo-codes/promo-codes.repository.ts` | типы `PromoRedeemer`, `PromoRedeemersFollowUp`, `PromoRedeemers`; методы `listRedeemers`, `redeemersFollowUp`; комментарий у `PromoCodeRow.redemption` («никогда кто» → «страницами, `listRedeemers`») |
| `promo-codes/prisma-promo-codes.repository.ts` | общий `FROM` (`redeemersFrom`) для строки и сводки — считать по-разному они не могут; страница: `ORDER BY r."createdAt" DESC, r."id" DESC LIMIT take+1 OFFSET skip`; два `LATERAL`: `TOPUP` позже погашения и сессии `status <> 'CANCELLED' AND costMinor > 0 AND createdAt > погашения`; `bigint → number`; у удалённого `paidSessionsAfter = null` |
| `promo-codes/promo-codes-admin.service.ts` | `redeemers(batchId, page)` — страница и сводка параллельно |
| `backoffice/http/backoffice.forms.ts` | `page` в `promoBatchQuerySchema` (мусор → 1) |
| `backoffice/backoffice-pages.service.ts` | `promoBatch` читает погасивших вместе с партией, по `PAGE_SIZE` = 50 |
| `backoffice/views/promo-codes.view.ts` | `redeemersSection` на обеих страницах партии: заголовок, 2 карточки сводки, таблица, пейджер на `#redeemers`; пусто — «Код ещё никто не погасил.» |
| `backoffice/assets/backoffice.css` | `.cell-lines`, `.table-scroll`, `.table-dense` (плотные ячейки, перенос заголовков, горизонтальный скролл вместо обрезки) |
| спеки | view (+6 тестов, старые вызовы — с пустым `NOBODY`), repository (+3), admin service (+1), smoke (+1: страница `?page=2` → `skip 50`, `?page=abc` → 1, контакты не в CSV) |

## Отклонения от спеки

- **Телефон и email — одна колонка «Контакты»** (две строки в ячейке), не две колонки: девять
  колонок в 960 px не помещаются. Итого колонок: 7 (+ «Код» у одноразовой партии).
- «Сессий после»: `0` у живого аккаунта без сессий, `—` — только у удалённого (так различимо
  «не было» и «не узнать»). «Пополнения после»: `—`, если не было.
- Пояснение определений — строкой над таблицей, а не подписью под отдельной колонкой.

## Проверки (слейв)

- `tsc --noEmit` ✓, `eslint` по изменённым файлам ✓, `nest build` ✓.
- `jest` полностью: 2671 / 2673; упали 2 теста в `backoffice-auth.spec.ts` — известный
  флаки (scrypt под общей нагрузкой); отдельно — 20 / 20 ✓. Промокоды + бэкофис — 260 / 260 ✓.
- SQL проверен только на форме (моки). Живой Postgres (`LATERAL`, enum-сравнения, `bigint`) —
  в маноре после мёржа.

## Попутно

`prettier --write src/modules` переформатировал ~45 чужих файлов — откачено (`git checkout`
по списку, кроме файлов задачи), в своём `promo-codes.view.ts` два чужих куска возвращены руками.

## Доки

`AURAF-0021`: строка `008` (UI/BE пустые до проверки на bff-dev) + строка в Context.

## Дальше

Ревью владельцем в IDE → коммит в ветку → вопрос о мёрже (`wts-finish` пушит `develop` и missus).
Манор: страница `TEST5` и одноразовой партии на bff-dev — см. «Проверки» в спеке.
