# AURAT-0200-005 — spec

2026-11-08 · Status: `draft` · тип: задача (без фичи). Пункты 2 и 5 — решения владельца, переданы координатором.

## 1. Карточка согласия — отступ снизу

- Новый токен `theme.spacing.thread: 14` — боковой отступ треда.
- `ChatConsentCard.wrap`: `paddingHorizontal` и новый `paddingBottom` — `theme.spacing.thread`.
- Те же 14 в `ChatInputBar.bar` и `DraftAttachmentBar.bar` → токен (вид не меняется; правило 3 — вторая копия).

## 2. Текст согласия (решение владельца)

`features/chat-settings/config/locales`, `consent.text`, 24 языка. EN и DE — дословно от владельца (`AURAT-0200`,
сообщение координатора 2026-11-08):
- EN: «I agree that Aura may use sensitive details I choose to share in chat, like health, love life or beliefs, for my
  readings, and that my chat is machine-translated by an external translation service. I can turn translation off or
  withdraw this consent at any time in my profile.»
- DE: «Ich bin einverstanden, dass Aura für meine Deutungen sensible Angaben nutzt, die ich selbst im Chat mache, etwa zu
  Gesundheit, Liebesleben oder Glauben, und dass mein Chat von einem externen Übersetzungsdienst maschinell übersetzt
  wird. Ich kann jederzeit in meinem Profil die Übersetzung ausschalten oder meine Einwilligung widerrufen.»
- JSDoc `en.ts` — контекст переводчику: явное согласие от первого лица; сведения, которыми человек решил поделиться сам,
  с примерами; цель — мои расклады; чат целиком (обе стороны) переводится машинно внешним сервисом; выключить перевод и
  отозвать согласие — в профиле; без «AI» / «KI» и без имени провайдера (Anthropic и США — в политике, задача 9).
- Остаётся `@sensitive`; 23 перевода — в `native-review.json` (`translate.mjs review`). Перед переводом — `translate.mjs
  scan` / `check`, глоссарий, регистр. Прочие ключи `consent` не трогаю. `CHAT_CONSENT_VERSION` = 1, контракты и BFF
  не меняются.

## 3. Нижние панели над системной навигацией (Android 15+)

- Хук `useBottomBarInset(base)` в `shared/lib` (экспорт из `@/shared`): iOS → `base` (как сейчас); Android →
  `max(base, insets.bottom + theme.spacing.md)`. На Android ≤ 14 `insets.bottom` = 0 → `base`, A50 не меняется. На 15+:
  3 кнопки (48) → 60, жесты (~24) → 36.
- Применить: `BookSessionScreen`, `BookReviewScreen`, `SessionDetailScreen`, `RescheduleScreen` (футер, `base` 26),
  `OnboardingSliderScreen` (`bottomContainer`, `base` 40).
- `Toast`: на Android `bottom = 96 + insets.bottom` (над таб-баром, который вырос на инсет), iOS — 96.
- `AdvisorProfile` уже учитывает инсет — не трогаю.

## 4. Шторки над клавиатурой (Android 15+)

- `BottomSheet.tsx`: `KeyboardAvoidingView` → `KeyboardAvoider` (как тред; без `legacyAndroid`: iOS `padding`, ≤ 14 —
  ничего, как сейчас; 15+ — отступ от `AuraKeyboardFrame`). Модуль не меняю (окно активности видит IME — `004`).
- Avoider — во весь экран (`flex: 1`, `justifyContent: 'flex-end'`, `pointerEvents: 'box-none'` — скрим под ним
  нажимается), `paddingTop: insets.top`; шторка и её тело (`body` у стран) — `flexShrink: 1`: высокая шторка ужимается
  до места над клавиатурой, а не уезжает верхом за экран. Это же исправляет iOS и Android ≤ 14 (сейчас там верх высокой
  шторки под клавиатурой срезан — по коду, не проверено).
- Одним изменением чинит все три шторки с полем: страны, `BirthDateSheet`, `PromoCodeSheet`.
- **Вопрос A:** список стран — держать высоту постоянной во время поиска (`height` вместо `maxHeight`, с усадкой)? Тогда
  поле не прыгает с каждой буквой. Рекомендую — да.

## 5. «AI» → «машинный перевод» в подписях (решение владельца)

- `screens/chat-thread/config/locales`: `translation.byAi` → ключ `translation.machine`, «Machine-translated» (DE
  «Maschinell übersetzt»), `@max 22` во всех 24; `TranslationNote.tsx` — новый ключ.
- `features/chat-settings/config/locales`: `switch.hint` — «Advisors’ replies in your language, machine-translated» (DE
  «…, maschinell übersetzt»).
- Grep по всем locales и `accessibilityLabel`: других «AI» про перевод в `en.ts` нет (только эти три строки, включая
  JSDoc `consent`); по языкам — проверю на «KI / IA / ИИ / TN …» при правке. Прочие упоминания AI не трогаю.

## Тесты

- `useBottomBarInset` — iOS / Android с инсетом 0 / 48 (`isolateModules`).
- `BottomSheet` — внутри `KeyboardAvoider`; на 15+ паддинг по кадру модуля (мок `keyboard-frames`, как в
  `KeyboardAvoider.test`); существующие тесты свайпа зелёные.
- Переводы — тест namespace’ов, `@max`, глоссарий.
- `npm run lint`, `npx tsc --noEmit`, `npm test`.

## Проверка в маноре (после мёржа)

AVD API 36, жесты и 3 кнопки; A50 (Android 11); iOS — при случае.
1. Шторка стран: поиск «sp» → шторка над клавиатурой, заголовок и поле видны; полный список + клавиатура — верх не
   срезан. `BirthDateSheet` (Home), промокод (Profile) — поле и кнопка над клавиатурой. Если шторка на 15+ не
   поднимается — окно активности IME не видит, `004` неверен → отдельный шаг: модуль слушает окно шторки.
2. Book / Review / Session detail / Reschedule / Onboarding — кнопка над панелью навигации с зазором.
3. Тост над таб-баром.
4. Чат: карточка согласия — снизу 14 до линии поля; новый текст; подпись «Machine-translated» и подсказка в профиле.
5. A50 — всё как до задачи.

## Не здесь

Сервер и контракты; иконки строки состояния (`AURAT-0187`); `react-native-keyboard-controller` (после RN 0.86).
