# AURAT-0186-010 — fix по ревью кода (slave-1-ac)

2026-11-07. Владелец: «передавай замечания все». Отчёт координатора:
`…/slave-1/…/scratchpad/wf-code-0186-review.md`. Все 4 замечания сверены и подтверждены.

1. **Крит.** `measureInWindow` и `screenY` в разных пространствах: Fabric `measureInWindow` =
   layout + `viewportOffset` корня (`DOM.cpp`, `includeViewportOffset = true`; `RootShadowNode.cpp:36-38`), а на
   Android `viewportOffset = locationOnScreen − getWindowVisibleDisplayFrame().top` (`ReactSurfaceView.kt:48-60`) =
   −строка состояния при edge-to-edge. Отступ был меньше на её высоту — поле всё ещё частично под клавиатурой.
   → `measure(…pageY)` (`includeViewportOffset = false`). Тест: мок, где `measureInWindow` y на 40 меньше `pageY`;
   отступ от `pageY` (300, не 260). Проверено: возврат к `measureInWindow` роняет 4 теста.
2. **Минор.** Поворот при открытой клавиатуре оставлял старый отступ (на API 30+ событие только при смене
   видимости IME). → `Dimensions` `change` + клавиатура открыта → `Keyboard.dismiss()`; два теста. Split-screen без
   поворота — в `TECH-DEBT.md` 17.
3. **Нит.** Колбэки измерения на Fabric синхронные (`SyncCallback`, `NativeDOM.h:24-26`) → «билет» `latest` был
   мёртвой логикой; удалён вместе с комментарием.
4. **Нит.** Тест «second show measures the same frame» переименован в «re-measures on every show».

Поправки в `004` («Поправка 2»), `007`, `009` — дописаны внизу.

В чек-лист манора (`007`) добавляется: на AVD API 36 залогировать у `SafeAreaView` треда `measure().pageY` и
`measureInWindow().y` — разница ровно высота строки состояния (делает координатор).

Проверки: tsc 0, eslint 0, jest --no-watchman — 226 наборов, 3089 тестов, все зелёные. Всё застейджено, без коммита.
