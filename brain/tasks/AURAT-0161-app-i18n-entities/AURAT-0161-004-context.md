# AURAT-0161-004 — context

Код (`slave-0/master` @ `307bb14`) — сверено с инвентарём, совпадает:

- `entities/horoscope/config/signs.ts` — `SIGN_COPY: Record<ZodiacSign, {name, dates}>`, 12 × («Aries»,
  «Mar 21 – Apr 19»). Потребитель — `model/use-horoscope.ts` (`signCopy`) → `screens/home/ui/HoroscopeCard.tsx`
  (имя, даты, a11y `${name}, ${dates}` — это слой screens/home, не здесь). Тест `use-horoscope.test.tsx`.
- `entities/campaign/config/constants.ts` — `FALLBACK_TICKET_COPY` (4 строки, `{amount}` / `{pct}` одиночные
  скобки). Потребитель — `lib/ticket-content.ts` → `fillSeasonCopy` из `@aura/contracts` v0.27.0: подставляет
  `{amount}` как английское «$5» / «$5.50» (`formatSeasonAmount`), `{pct}` как число. Вызывает `model/use-offer-
  ticket.ts` (useMemo). Eyebrow билета — `textTransform: 'uppercase'` (`shared/ui/offer/TicketShell.tsx`) → el в
  капсе. Лимиты сервера (`SEASON_COPY_LIMITS`): eyebrow / title 22, sub 36.
- `entities/campaign/ui/SeasonHero.tsx:179` — a11y `${hero.title}. ${hero.body}`: обе части — серверный английский.
- `entities/user/ui/PhotoRow.tsx` — `CHANGE_PHOTO = 'Change photo'` (текст + a11y).
- advisor / session / tarot / wallet — текстов нет (grep литералов и `accessibilityLabel`); имена карт таро —
  с сервера.
- Форматтеры `@/shared`: `shortDateLabel(value, language)` (MMMd по CLDR), `formatUsdMinor`, `useLanguage()`.
  Диапазона дат нет. Hermes без `formatRange`.
- eslint: `i18next/no-literal-string` (`jsx-only`) — `src/shared/ui/**`, `src/features/app-language/**`.

Node ICU `formatRange` (MMMd), 24 языка: разделитель « – » у большинства, «–» без пробелов у da, fi, pl, sl, sv;
mt в диапазоне берёт «21 ta’ Mar», а одиночная дата — «Mar 21» (CLDR mt непоследователен).

aura-web (`88dd553`):
- `entities/season/config/locales` — те же 4 строки, но eyebrow кода — **«Gift code»** (в приложении «Promo
  code»); `{{amount}}` / `{{pct}}` двойные скобки;
- `features/edit-profile` `photo.change` — «Change photo» (23 перевода);
- `features/redeem-promo-code` `label` — «Promo code»;
- знаков зодиака на вебе нет — переводы делаются здесь.

Противоречий нет. Решить в спеке: разделитель диапазона (генератор vs ключ), «Promo code» vs «Gift code».
