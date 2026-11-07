# AURAT-0193-002 — execute

Дата: 2026-11-07 · Слот `aura-app-manor` slave-1 (координатор slave-1-ac), ветка
`feature/AURAT-0193-app-screens-fragment-restore-crash` от `develop` @ `0ea88d0`. Застейджено, без коммита — коммит и мёрж
с одобрения владельца.

## Что сделано

- `android/app/src/main/java/cc/silvermind/aura/MainActivity.kt` — `override fun onCreate(savedInstanceState: Bundle?)`:
  `supportFragmentManager.fragmentFactory = RNScreensFragmentFactory()`, затем `super.onCreate(savedInstanceState)`.
  Фабрика react-native-screens (4.25.2, `fragment/restoration/RNScreensFragmentFactory.kt`) для фрагментов библиотеки
  отдаёт самоудаляющийся `AutoRemovingFragment`, остальным — обычное создание; экраны React Navigation строит заново из JS.
  Комментарий — почему (шрифт / масштаб экрана не в `configChanges`, убийство процесса). Так рекомендует README
  react-native-screens (Android).
- `src/app/navigation/__tests__/main-activity-fragments.test.ts` — охранный тест: в `MainActivity.kt` без комментариев
  фабрика ставится раньше `super.onCreate(savedInstanceState)`, импорт фабрики есть.

## Проверки (слот)

`jest` нового теста — 2 / 2; `eslint --max-warnings 0` по тесту — 0; `tsc --noEmit` — 0;
`./gradlew :app:compileDebugKotlin` — BUILD SUCCESSFUL. Полный прогон слота — в отчёте координатора.

## Проверка в маноре (после мёржа, новая debug-сборка)

1. AVD API 36: открыть тред, `settings put system font_scale 1.15` → без падения, экран тот же или стартовый; вернуть 1.0
   → без падения.
2. Home → `am kill cc.silvermind.aura` (процесс в фоне) → вернуться из «Недавних» → без падения.
3. То же с открытой клавиатурой (заодно п. 9 `AURAT-0188-011`: модуль клавиатуры при пересоздании активности).
4. A50 — запуск и навигация как до задачи.
