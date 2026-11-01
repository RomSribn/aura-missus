# AURAT-0148-004 — context

Источники: `AURAF-0022`, `AURAI-0009` §4/§8, `.claude/design_handoff_aura/SEASONAL.md` (+ `presets/`,
`effects/`, экраны 67–81), `AURAT-0147-007` / `-008` / `-009` / `-010` (bff slave-2), worktree
контрактов `v0.27.0-campaigns` (`src/app-config.ts`, `src/session.ts`), код `aura-app` `develop` @ `234c500`.

Код (ground truth):
- `screens/home/ui/HomeScreen.tsx` — шапка → `DailyCardBanner` (marginTop 16); hero встаёт между.
- `screens/home/ui/DailyCardBanner.tsx` — `theme.gradients.plum`, gold в eyebrow / рамках / звёздах.
- `shared/ui/offer/CouponTicket.tsx` — только «50% OFF First Session»; цвета из `theme`
  (accent, accentSoft, `gradients.coupon`, тень coral). Места: Advisors, AdvisorProfile,
  PromoCodeSheet, бронь (Book / Review / QuickBook).
- `shared/ui/orb/Orb.tsx` — тона только `coral` / `teal`; `PulsingOrb` уже гасит пульс при Reduce Motion.
- `app/navigation/AuraTabBar.tsx` — активная иконка и точка `theme.colors.accent`.
- `features/promo-code` — шторка в Profile (`use-profile`), поле пустое при каждом открытии;
  `initialCode` нет.
- `features/push/lib/parse-push-data.ts` — действия `rate`, `daily-card`, `advisorId`; `promo` нет.
- Бронь: `use-booking-confirm.ts:109`, `use-booking.ts:334`, `use-quick-book.ts:72` —
  `offerPct = useFirstSessionOffer()` при `creditMinor > 0` (ошибка при скидке кампании, `AURAT-0147-007` §3).
- Хранилища ключ-значение (MMKV / AsyncStorage) нет, **но есть `@dr.pogodin/react-native-fs`** (файл в
  DocumentDirectory) — кэш без новой нативной зависимости.
- `react-native-reanimated` нет; `SEASONAL.md` §6 сам предлагает `Animated.View` + `useNativeDriver`.
- `bffRequest` всегда с токеном; `app-config` публичный — нужен запрос без токена.
- Модульные сторы + `useSyncExternalStore` — образец `entities/wallet/model/wallet-store.ts`.

Противоречия:
- `SEASONAL.md` §0 — форма `season{preset, code, codeValue, discount}`; `AURAT-0147-010` §3 оставляет
  `season` / `promo` / `discount` + `promo.amountMinor`. Берём 0147 (контракт — его).
- `copy`: в worktree контрактов 3 ключа и лимиты 28/60/16, в `-010` и `SEASONAL.md` — 9 ключей и
  26/50/16. `-010` ещё не одобрена. Локальный тип делаем по `-010`.
- `heroBodyNoCode` в пресетах 54 символа при лимите 50 — вопрос `AURAT-0147-010`; клиент режет
  многоточием на 2 строках.
