# AURAT-0146-010 — fix: ревью качества кода (манор)

Дата: 2026-10-31 · Слот: slave-1 · Ветка: `feature/AURAT-0146-public-promo-codes`

Манор (manor-70) по поручению владельца прочитал код на best practice и clean code. Пункты 1–6
нужно было сделать до мёржа, остальное записано ниже как «позже».

## Исправлено до мёржа

1. **Мёртвое `PromoCodeRow.redemptionsCount`** удалено вместе с `_count` в select у `findBatch`:
   раньше на партии из 500 кодов было 500 лишних подсчётов. Фикстуры и комментарий к
   `redemption` поправлены.
2. **Мёртвая `formatUtcDay`** удалена. Её тест заменён проверкой `formatDayKey`.
3. **Устаревшие комментарии и тексты:**
   - schema `PromoCode.disabledAt`: про SINGLE и PUBLIC;
   - текст `PromoCodeCollisionError`: «A promo code already exists»;
   - шапка `zoned-date.ts`: границу дня используют три фичи, третья — промокоды;
   - спека `-005` §4: `SessionPriceFloor` и все советники.
4. **`startOfZonedDay` в поясах, где летнее время пропускает саму полночь.** Это America/Santiago
   2026-09-06 и America/Havana 2026-03-08: функция возвращала время на час раньше, то есть ещё
   предыдущий день. Манор разрешал ограничиться честным комментарием, но правка в две строки,
   поэтому сделан третий проход: если результат читается как другой день, берётся смещение,
   действовавшее в тот момент. Получается момент перевода часов, первый миг нового дня.
   Тест фиксирует Santiago (04:00Z), Havana (05:00Z) и обычный следующий день. На прод
   (UTC/New_York) это не влияет.
5. **Вид партии определяется по одному признаку.** View везде проверяет `kind === 'public'`, а не
   `publicCode`. `toKind` — полный `Record<DbPromoBatchKind, PromoBatchKind>`, как `DB_KIND`.
   `displayPromoCode` принимает `PromoBatchKind`. Обнуление `publicCode` осталось в одном месте —
   в `toSummary`.
6. **Шум форматирования откачен.**
   - `src/contracts/openapi.ts` и `advisors.service.spec.ts` восстановлены из HEAD, в них заново
     внесены только строки задачи (описание redeem; мок `lowestPriceMinorPerMinute`).
   - `sameCampaignWarning` — в форматировании HEAD.
   - Prettier в этот раз запускался только на файлах, которые в HEAD уже были отформатированы им.
   - Абзац комментария в `backoffice-promo-codes.controller.ts` пересобран.
   - В контрактах `promo.ts` маршрут `POST /v1/wallet/promo-codes/redeem` возвращён в первый абзац.

Заодно сделано из «можно и сейчас»:
- в лог создания одноразовой партии добавлено `kind: 'single'`;
- `discountMinor(subtotalMinor, pct)` в `session-policy.ts`, `firstSessionDiscount` теперь
  выражена через неё. Так AURAT-0147 при rebase не получит конфликт в этом месте. Есть отдельный
  тест.

Lint ок, typecheck ок, jest 132 сьюта / 1820 тестов, build ок, `prisma validate` ок.
В контрактах typecheck и build ок.

## Позже (не в этой задаче)

- `confirmPublic` и `createPublic` начинаются одинаково → вынести в приватный
  `checkPublic(input, now)`. Текст «Код на такую сумму оплатит…» перенести к остальным текстам
  формы в `promo-batch-draft.ts`.
- Во view три словаря статусов кода (CODE_STATUS, CODE_STATUS_TEXT, CSV_STATUS) и инлайн
  `promoBatchStatusText` → один источник. Слово «погашено» перенести внутрь `redeemedText`.
  Вложенный тернарник уведомления перенести в `batchNotice`.
- Подписи UTC непоследовательны: у «создана …» есть «UTC», у «отключена …» нет.
- `timeZone` передаётся вручную в шести местах (admin.service, pages.service, controller) →
  отдавать его из `overview()` / `batch()` / `confirm*()`.
- `PromoCodesModule` тянет весь `SessionsModule` ради `SessionPriceFloor`. Прецедент есть
  (agent-desk), не блокер. Экспорт `cheapestSessionSubtotalMinor` **не убирать** — его
  использует 0147.
- `session-price-floor.spec.ts` повторяет числа из `session-policy.spec.ts`: достаточно одного
  случая на проводку и одного на null.
- В `promo-codes-admin.service.spec.ts` хелпер `build(undefined, null, {…})` перевести на объект
  опций.
- Третий проход `startOfZonedDay` — уже сделан (п. 4), из «позже» вычеркнут.

## Дальше

Манор передаёт владельцу на финальное ревью. После одобрения — коммит, затем отдельные вопросы
о мёрже в develop и о push `main` + тега `v0.26.0` в `aura-contracts`.
