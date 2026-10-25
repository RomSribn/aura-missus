# AURAT-0136-010 — Fix: автокомплит — общий компонент

Date: 2026-10-25

Владелец: «да, выноси в shared». Правило, по которому это нужно: build rules 3 — «a visual value
needed twice becomes … a shared component before the second copy merges»; рамка поля пикера была
копией `Field`. Запрета на `shared` с одним потребителем нет (правило про один потребитель — о
срезах `entities` / `features`).

- `shared/ui/combobox` — `Combobox<Value>`: рамка, метка и ввод — стили `Field`
  (`field.module.css`), строка с поиском и шевроном, список (desktop — поверх, телефон — в потоке,
  колонка: задай высоту — скроллится только список), «ничего не найдено». Props: `label`,
  `options`, `value`, `onChange`, `placeholder`, `emptyText`, `className`.
- `shared/model/use-combobox.ts` — состояние и клавиатура (APG list autocomplete), тип
  `ComboboxOption` (`value`, `label`, `hint`, `keywords`, `lang`); `shared/model/combobox-search.ts`
  — поиск без регистра и диакритики. В `shared/model`, а не `lib`: steiger ограничивает
  `shared/lib` 15 модулями.
- `pages/me`: `model/use-languages.ts` (варианты: своё имя, имя на языке экрана, английское — в
  `keywords`; выбор), `ui/language-picker.tsx` — `Combobox` + ширина 440 / высота на телефоне.
  Удалены `use-language-picker.ts`, `lib/match-language.ts`.
- Тесты: `shared/ui/__tests__/combobox.test.tsx`, `shared/model/__tests__/combobox-search.test.ts`;
  тесты Language в `profile.test.tsx` — без изменений.

Проверки: typecheck, lint (eslint + steiger), vitest (87 / 1568), build — зелёные.
