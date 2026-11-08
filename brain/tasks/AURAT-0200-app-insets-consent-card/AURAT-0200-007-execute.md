# AURAT-0200-007 — execute

2026-11-08, slave-0, `feature/AURAT-0200-app-insets-consent-card` (от `develop` @ `351e209`). По спеке `005` с решениями
`006`. Не закоммичено, всё застейджено.

## Файлы

Отступы и нижние панели:
- `shared/config/theme.ts` — `spacing.footer: 26`, `spacing.thread: 14`.
- `shared/lib/bottom-bar-inset.ts` (новый) — `bottomBarInset(base, inset)` (iOS — `base`; Android —
  `max(base, inset + spacing.md)`), `useBottomBarInset(base)`; из `@/shared` — только хук.
- Футер `paddingBottom: 26` заменён на `useBottomBarInset(theme.spacing.footer)`: `BookSessionScreen`, `BookReviewScreen`,
  `SessionDetailScreen`, `RescheduleScreen`. `OnboardingSliderScreen` — `useBottomBarInset(theme.spacing['4xl'])`
  вместо 40.
- `shared/ui/toast/Toast.tsx` — по умолчанию `96 + insets.bottom` на Android, 96 на iOS.
- `features/chat-settings/ui/ChatConsentCard.tsx` — `paddingHorizontal` и новый `paddingBottom` — `spacing.thread`.
  `ChatInputBar`, `DraftAttachmentBar` — 14 → `spacing.thread`.

Шторки:
- `shared/ui/bottom-sheet/BottomSheet.tsx` — `KeyboardAvoidingView` → `KeyboardAvoider legacyAndroid="padding"`,
  `styles.avoider` (`flex: 1`, `flex-end`, `pointerEvents: 'box-none'`), `paddingTop` = `insets.top` (iOS) /
  `StatusBar.currentHeight` (Android: модаль под строкой состояния); `sheet.flexShrink: 1`.
- `shared/ui/keyboard-avoider/KeyboardAvoider.tsx` — `legacyAndroid?: 'height' | 'padding'`.
- `screens/phone-auth/ui/CountryPickerSheet.tsx` — `body`: `height` 70 % окна + `flexShrink: 1` (вопрос A, «верх на
  месте»).

Строки (24 языка):
- `chat-settings` `consent.text` — EN и DE владельца; 22 перевода мои, первое лицо, без рода говорящего; JSDoc в `en.ts`
  — пять пунктов «что держит текст», без «AI» и провайдера; заголовок namespace переписан (было про Anthropic).
  Остаётся `@sensitive legal`: `native-review.json` пуст, `translate.mjs review` выдаёт namespace сам.
- `chat-settings` `switch.hint` — «…, machine-translated».
- `chat-thread` `translation.byAi` → `translation.machine`, «Machine-translated», все ≤ 22; `TranslationNote.tsx`.
- Других строк про перевод с «AI» / «KI» / «IA» / «ИИ» … в locales и `accessibilityLabel` нет. Push-тексты шлёт сервер,
  в приложении их нет.

Тесты: `shared/lib/__tests__/bottom-bar-inset.test.ts` (новый, 4); `bottom-sheet/__tests__/BottomSheet.keyboard.test.tsx`
(новый, 3: avoider с `padding`, во весь экран и `box-none`, скрим вне его, `flexShrink` у шторки); ожидания строк в
`MessageBubble.translation.test.tsx` и `ChatThreadScreen.consent.test.tsx`.

## Регрессия на A50 — что нашёл

Статически виновника нет. Проверено:
- нативное окно шторки не менялось с июля: `ReactModalHostView` (RN 0.85.3 с первого коммита, версия не поднималась) —
  `ADJUST_RESIZE`, `disableEdgeToEdge()` (`setDecorFitsSystemWindows(true)`), `setStatusBarTranslucency`; флаг
  edge-to-edge RN выключен (`setEdgeToEdgeFeatureFlagOn` вызывает только entry point при `edgeToEdgeEnabled=true`);
  в `android/app` нет ни `setDecorFitsSystemWindows`, ни `enableEdgeToEdge`; манифест и тема — без изменений по окну
  (0181 — только `locale|layoutDirection`);
- `0188`: модуль создаёт слушатель только при SDK ≥ 35, на A50 его нет; это `OnPreDraw`, инсеты он не съедает;
- `0186`: экран телефона под шторкой — тот же KAV `height`, что был; `edges` с `bottom` на Android к окну шторки
  отношения не имеет;
- `0158`, `0120`: дерево шторки то же с октября (`GestureHandlerRootView` → скрим → KAV без `behavior` → шторка),
  добавились `PanGestureHandler` всегда и `LegacyFlatList` — на раскладку не влияют; RNGH не обновлялся.

Остаётся гипотеза на устройстве. Новый путь не зависит от того, сжимается ли окно шторки: на ≤ 14 avoider — RN KAV
`padding` во весь экран, отступ = часть экрана под клавиатурой (`frame.y + height − screenY`). Окно сжалось — 0, не
сжалось — высота клавиатуры. Нужны лишь события клавиатуры корня активности, пока фокус в шторке; если их нет, лучше не
станет, но и хуже не будет.

## Проверки в слоте

`npx tsc --noEmit` — 0; `npm run lint` — 0 (`--max-warnings 0`); `jest --no-watchman` — 247 наборов, 3292 теста, все
зелёные (финальный прогон после правки ожиданий строк). `translate.mjs check` —
0 запрещённых форм, советы только про склонения (bg «гадания», it «letture», ga мутации). Prettier: мои строки чисты; 5
файлов были не по prettier ещё на `develop`, не переформатировал.

## Проверка в маноре (после мёржа)

Новая debug-сборка не нужна (натив не менялся), хватит JS. AVD API 36 (жесты и 3 кнопки), **A50 обязательно**, iOS по
возможности.
1. Шторка стран: открыть, тапнуть поиск, ввести «sp» — шторка на клавиатуре, заголовок и поле на месте, высота не меняется
   при вводе; полный список с клавиатурой — верх не срезан, шторка не выше строки состояния. Дата рождения (Home), промокод
   (Profile) — поле и кнопка над клавиатурой. Тап по скриму закрывает.
2. **A50**: те же три шторки. Если не поднимаются — диагностика: `adb shell dumpsys window windows | grep -A3 Dialog` при
   открытой клавиатуре (сжалось ли окно диалога), и бисект только JS через Metro по `1ce6ba9` (до 0158) / `307bb14` (после
   0158) / `71e03d2` (0186) — натив тот же, APK не пересобирать.
3. Шторка языка в Profile (AVD и A50): тяга вниз, прокрутка списка, тяга со списка с верха, повторное открытие — зона
   0158.
4. Book / Review / Session detail / Reschedule / Onboarding — кнопка над панелью навигации с зазором; A50 и iOS — как
   было.
5. Тост (например, после отзыва) — над таб-баром.
6. Чат: карточка согласия — снизу 14 до линии поля, новый текст; «Machine-translated» под переведённым ответом; подсказка
   переключателя в Profile.
7. Перед проверкой согласия — координатор сбрасывает тестовые согласия на dev.
