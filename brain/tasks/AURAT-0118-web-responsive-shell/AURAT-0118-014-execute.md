# AURAT-0118-014 — Execute (шторка входа на всю высоту)

Date: 2026-10-21

- `shared/ui/sheet`: проп `fullOnPhone` — на телефоне слой без подъёма над клавиатурой
  (`.fullLayer { bottom: 0 }`), шторка — `height: calc(100% * var(--sheet-phone-share))`, контент сверху.
  Desktop не меняется.
- `tokens.css`: `--sheet-phone-share: 0.92` — доля высоты телефона у шторки (была литералом `92dvh` /
  `0.92`); обычная шторка — `max-height: calc(var(--visible-h, 100%) * var(--sheet-phone-share))`.
- `features/auth-by-phone/ui/auth-dialog.tsx`: все три шага (телефон, код, имя) — `fullOnPhone`.
- Тест `sheet.test.tsx`: `fullOnPhone` ставит классы, по которым работает CSS телефона; без него — нет.
- Проверки: lint, typecheck, prettier — чисто; 77 файлов / 1329 тестов; build — ок. Коммит в ветку, мёржа нет.

## Проверка на iPhone (iOS 26)

Вход из Book и из шапки: шаг телефона — шторка от верха (8% страницы видно), поле и Send code над
клавиатурой, страница не едет; Send code → «Enter the code» на том же месте, поля кода видны, код из
SMS предлагается над клавиатурой; «Tell us who you are» — поля прокручиваются внутри шторки.
