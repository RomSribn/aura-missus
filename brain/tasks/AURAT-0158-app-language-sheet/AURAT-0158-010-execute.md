# AURAT-0158-010 — execute (правки ревью 009)

Дата: 2026-11-05. Не закоммичено — ждёт ревью.

1. `ui/LanguageSheet.tsx`: у radio-`Pressable` — `accessibilityLabel` (самоназвание / «Device language»),
   `accessibilityLanguage` (язык подписи), `accessibilityHint` (имя на языке интерфейса); с вложенных `Text`
   `accessibilityLanguage` снят. Поле `hintLanguage` удалено из `LanguageOption` и `lib/language-options.ts` — у
   подсказки на уровне строки своего языка нет, она читается голосом интерфейса.
2. ✕: `hitSlop={5}` (`CLOSE_HIT_SLOP`) → 44pt.
3. `index.ts`: экспорт `LanguageSheetState` убран (потребителей вне слайса нет).
4. `fi.ts`: «tarotkortit».

Тест листа проверяет подпись, подсказку и язык на пропах radio-элемента (el, bg, device → en) и что подсказка
нарисована. Проверка: `npx tsc --noEmit`, `npm run lint` — чисто; `npx jest --no-watchman` — все зелёные.
