# AURAT-0188-006 — ревью спеки (slave-1-ac) и решения владельца

2026-11-07. Ревью `005` координатором: 11 замечаний, блокеров нет. Отчёт —
`…/slave-1/1d7b6620-…/scratchpad/wf-spec-0188-findings.txt`. Владелец: «Передавай все».

## Решения владельца

1. «Да, модуль» — `AuraKeyboardFrame` в пакете приложения, `MainActivity` не трогаем.
2. «Оставить» — запасной путь на событиях RN для сборки без модуля.

## Замечания (все приняты → `007-spec-v2`)

1. Натив: VTO нельзя хранить в поле — после пересоздания активности (шрифт / язык / плотность не в `configChanges`)
   `onHostResume` приходит до присоединения decor, VTO плавающий, `remove` через него бросает → падение релиза.
   WeakReference на decor + listener, `decor.viewTreeObserver` в момент add / remove; null-guard `rootWindowInsets`;
   при отключении сбросить кадр и px-ключ.
2. `needsEagerInit` у legacy-модуля в bridgeless ничего не делает — модуль создаётся при первом чтении `NativeModules`
   (первый avoider на 15+), `current()` в этом же эффекте `null`. Убрать; первый pre-draw после attach всегда шлёт кадр.
3. Reload: старый контекст получает только `onHostPause`, `invalidate()` — на bgExecutor. Флаг «мёртв», сброс кадра,
   отключение через `UiThreadUtil.runOnUiThread`, проверка флага в `onPreDraw`, `removeLifecycleEventListener`.
4. Тип `currentFrame(): WritableMap?`; в `@Volatile` — data class, `Arguments.createMap()` заново на каждый возврат и emit.
5. Причина «модуль, не MainActivity» — настоящая: наличие модуля отличает новую сборку от старой (на этом держится
   решение 2) и синхронный `current()`.
6. Пороги SDK натива и JS сверяет охранный тест; `edgeToEdgeEnabled=true` / расширение `ANDROID_EDGE_TO_EDGE` — только
   вместе с удалением модуля.
7. Jest: мок `../keyboard-frames` геттером с фейком на настоящем EventEmitter; отдельный `keyboard-frames.test.ts`
   с `isolateModules`; в режиме модуля слушателей `keyboardDidShow/Hide` нет; `listenerCount` 1 → 0, 2 → 0; охрана —
   ключи payload, порог SDK, `add(KeyboardFramePackage())` не в комментарии; кейс «current() null + metrics, событие
   перекрывает».
8. Чек-лист манора: п. 0 (новый JS на старом APK), пересоздание активности, Home → назад, способ для «один / два
   прыжка» (`screenrecord`), три кнопки — пп. 1–4.
9. §5: «поле всегда видно» → оговорка про split screen.
10. TECH-DEBT 17: фраза о повороте; список всего, что удаляется вместе; правило очерёдности — в одном месте.
11. Дубль п. 2.

Пересечение с `AURAT-0181` (slave-0): строка в `MainApplication.kt` рядом с `DeviceCountryPackage` — конфликт в одну
строку при втором мёрже, ничего не делать.
