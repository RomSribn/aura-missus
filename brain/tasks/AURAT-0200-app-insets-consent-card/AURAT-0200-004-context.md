# AURAT-0200-004 — context

2026-11-08, код `develop` @ `351e209`.

## Причина общая — принудительный edge-to-edge (гипотеза координатора подтверждается кодом)

`targetSdkVersion = 36` с первого коммита; `edgeToEdgeEnabled=false`. На Android 15+ окно рисуется под системными
панелями и не сжимается под клавиатуру (`ANDROID_EDGE_TO_EDGE`, `shared/ui/keyboard-avoider/edge-to-edge.ts`). На
Android ≤ 14 панель навигации вне окна, `useSafeAreaInsets().bottom` = 0 — поэтому на A50 всё было ровно.

## Нижние панели — обход всех экранов

| Экран | Как сейчас | Под панелью на 15+ |
|---|---|---|
| `booking/BookSessionScreen` | `edges={['top']}`, `footer.paddingBottom: 26` | да (скрин 17) |
| `booking/BookReviewScreen` | то же | да (скрин 18) |
| `session-detail/SessionDetailScreen` | то же, таб-бар скрыт | да |
| `reschedule/RescheduleScreen` | то же, таб-бар скрыт | да |
| `onboarding-slider/OnboardingSliderScreen` | `edges={['top']}`, `bottomContainer` absolute, `paddingBottom: 40` | частично (40 < 48 у кнопок) |
| `shared/ui/toast/Toast` | `bottom: 96` — «над таб-баром» | на 3 кнопках таб-бар ≈ 103 → тост наезжает |
| `advisor-profile` (`ctaBar`) | `max(insets.bottom, 14)` | нет, учитывает |
| `Booked`, `CreateAccount`, `EditProfile`, `WriteReview`, `DailyCard`, `ChatThread`, `PhoneAuth` (Android) | `edges` с `bottom` | нет |
| табы (`Home`, `Chats`, `Advisors`, `Sessions`, `Profile`) | низ — `AuraTabBar` с `max(insets.bottom, 10)` | нет |
| `VerifyOTP`, `Splash` | внизу кнопок нет | — |
| `ImageViewer`, `SpreadCardViewer`, `ProfilePhotoViewer`, `BottomSheet` | инсет уже учтён | нет |

## Шторка стран — механизм

- `0186-011` шаг 0: поиск был над клавиатурой, но шторка **не двигалась** — просто полный список высокий
  (`body.maxHeight` = 70 % окна). После поиска список короче → шторка ниже → целиком под клавиатурой (скрин 19). «Раньше
  оставалась» = полный список.
- `BottomSheet.tsx:626`: `KeyboardAvoidingView behavior={isIOS ? 'padding' : undefined}` — на Android ничего не делает.
  Окно `Modal` на 15+ не сжимается.
- Затронуты все шторки с полем: `CountryPickerSheet`, `BirthDateSheet` (Home, автофокус, цифровая клавиатура),
  `PromoCodeSheet` (Profile). Две последние короткие — на 15+ поле, скорее всего, под клавиатурой целиком.
- Источник высоты клавиатуры внутри `Modal`: модуль `AuraKeyboardFrame` слушает decor **активности**, шторка — своё окно
  диалога. На скрине 19 экран телефона за шторкой поднят `KeyboardAvoider`-ом ровно на 16 dp над клавиатурой, пока фокус
  в поиске шторки → окно активности видит IME. Значит, `KeyboardAvoider` в шторке получит кадр без доработки модуля.
  Координаты: `keyboardTop` — от верха контента активности, `measure().pageY` в `Modal` — от верха окна диалога; оба окна
  во весь экран (`statusBarTranslucent`, edge-to-edge) → совпадают. **Не проверено на устройстве** — первый пункт
  проверки в маноре.
- Высокая шторка + клавиатура: 70 % окна + клавиатура > экрана → верх (заголовок, поиск) уходит за край. Так и сейчас
  на iOS (`padding`) и, вероятно, на A50 (окно сжимается, шторка выше окна). Нужна усадка шторки под доступную высоту.

## Карточка согласия

`ChatConsentCard.wrap`: `paddingHorizontal: 14`, `paddingTop: 10`, снизу 0 → карточка встык с верхней линией
`ChatInputBar`. 14 — боковой отступ треда ещё в `ChatInputBar.bar` и `DraftAttachmentBar.bar`; токена нет
(`spacing`: 12 / 16 / `screen` 22).
