# AURAT-0185-002 — execute

Дата: 2026-11-07 · Слот: `aura-app-manor` slave-1 (координатор slave-1-ac), ветка
`feature/AURAT-0185-app-language-sheet-note` от `develop` @ `a91fde1`. Не закоммичено — коммит и мёрж с одобрения
владельца.

## Решение владельца

«за это однострочный фикс, можешь в слейве задачи 0184 сделать?» — правка мелкая, без отдельной спеки. Строка живёт в
`aura-app`, а слот `0184` — `aura-bff`, поэтому правка сделана в слоте приложения координатора. Выбрано **удаление**
строки (а не перевод нового текста): после `0171` (колода) и `0184` (профили) она ничего верного не говорит, а флаг
языков в проде выключен до `AURAT-0182` — к моменту, когда шторку увидят люди, `0184` уже будет на сервере.

## Что сделано

- `src/features/app-language/ui/LanguageSheet.tsx` — убрана строка под заголовком (`t('untranslated')`) и её стиль
  `subtitle`; у шапки — `marginBottom: theme.spacing.md`, чтобы список не прилипал к заголовку (прежний отступ строки).
- `src/features/app-language/config/locales/*.ts` (24 языка) — ключ `untranslated` удалён, в `en.ts` — вместе с JSDoc.
- `ui/__tests__/LanguageSheet.test.tsx` — тест «says what does not change…» → «is one labelled radio group, with no
  promise of English content»: строки «stay in English» в шторке нет.
- Других строк, обещающих английский с сервера, в `src` нет (поиск «stay in English», «tarot cards stay»).

Отличие от макета `15-sheet-language.png`: там под заголовком подзаголовок «You can change this later in your
profile.» — в приложении его место занимала эта строка; новый подзаголовок не добавлен (это новая строка на 24 языка,
вне «однострочного фикса»).

## Проверки

tsc, eslint, Jest, `translate.mjs check` — в слоте (результат — в отчёте координатора владельцу).
