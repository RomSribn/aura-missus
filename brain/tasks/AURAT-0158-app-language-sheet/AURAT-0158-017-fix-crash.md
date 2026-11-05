# AURAT-0158-017 — fix: dev-сборка падает на листах (детектор gesture-handler 3 на RN 0.85.3)

Дата: 2026-11-05. Сессия-рецензент (по поручению владельца), A50, Android, debug из develop `35e0572`: лист,
~3 с тяги/прокрутки, тап → SIGABRT `YogaLayoutableShadowNode.cpp:709 assertion failed (YGNodeGetOwner(childYogaNode)
== &yogaNode_)` из `RNGestureHandlerDetectorShadowNode::layout`. Известная ошибка: gesture-handler #4241 / #4051,
причина в RN (PR 57103), исправлено в RN 0.86.2+ / 0.87, в 0.85 не перенесено; RNGH 3.4.0 не помогает. До `013`
приложение не монтировало v3-детектор вовсе.

Решение владельца (вариант 1, передано рецензентом): `BottomSheet` и списки — обратно на legacy-API
(`PanGestureHandler`, `LegacyScrollView` / `LegacyFlatList`), ни одного v3-детектора в дереве; логика и правки
ревью `014` сохраняются; тест-страж — в дереве листа нет хоста детектора v3.
