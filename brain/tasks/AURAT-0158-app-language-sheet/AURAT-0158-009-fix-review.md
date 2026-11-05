# AURAT-0158-009 — fix: ревью до коммита

Дата: 2026-11-05. Владелец передал ревью:
1. VoiceOver: `accessibilityLanguage` на вложенных `Text` теряется — `Pressable` собирает подпись из детей
   (RN 0.85, `RCTViewComponentView.mm`). `accessibilityLanguage` и `accessibilityLabel` (самоназвание) — на сам
   radio-`Pressable`, подсказка — в `accessibilityHint`; тест — на пропы radio-элемента.
2. ✕ 34×34 — `hitSlop` до ≥ 44pt.
3. Убрать `LanguageSheetState` из `index.ts` (правило 5 — экспорт без потребителей).
4. `fi.ts`: «tarotkortit» слитно.
