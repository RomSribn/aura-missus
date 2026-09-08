# AURAT-0062-004 — Хэндофф синхронизирован, и одна правка в него внесена

Дата: 2026-09-08
Источник: `/Volumes/Work/personal/design_handoff_aura`
Наша копия: `<workspace>/.claude/design_handoff_aura`

## Синхронизация добавляющая, не зеркальная

Источник моложе нашей копии по новой работе (профильные формы) и **старше** по
нашим интейк-пометкам: в нём нет `CHAT_ATTACHMENTS.md`, нет отметок «superseded»
в `AUTH_PHONE_SMS.md` и `DAILY_CARD_TAROT.md`, а в `README.md` ссылки на
`MOTION_AND_ICONS.md` откатились к `CLAUDE.md`. Поэтому копирование целиком
стёрло бы записанное. Синхронизация шла пофайлово.

### Взято целиком

`PROFILE_FORMS.md`, `doc-page.js`, `Screens Overview.html` (+ новая печатная
версия), `screens/28-create-account.png`, `screens/29-edit-profile.png`,
`prototype/profile-forms.jsx`, `prototype/app.jsx`,
`prototype/settings-chat.jsx`, `prototype/Aura - Psychic App.html`, папки `rn/`
и `web/`. Экранов стало **34**.

### Слито вручную

- `README.md` — добавлены §15b, строка `profile` в модели состояния, `rn/` и
  `profile-forms.jsx` в списке файлов прототипа, из `sheet` убран `edit`.
  Наши ссылки на `MOTION_AND_ICONS.md` и заметка про `video`/`mic` сохранены.
- `MOTION_AND_ICONS.md` — три новых пункта в «Quick reference: files». Имя файла
  не тронуто: вложенный `CLAUDE.md` в этом воркспейсе подхватывается как
  *инструкции*, и правил ровно два источника.

### Не взято

`CLAUDE.md` источника — это и есть наш `MOTION_AND_ICONS.md`.
`AUTH_PHONE_SMS.md` и `DAILY_CARD_TAROT.md` оставлены нашими: источник по ним
позади. `CHAT_ATTACHMENTS.md` на месте.

## Правка спеки под слова владельца

`PROFILE_FORMS.md` §2 у дизайнера даёт «Skip for now». Владелец просит обратное:
экран — ворота, без skip и без навигации. Спека приведена к словам владельца
врезкой вверху файла (в том же виде, в каком мы уже отмечали расхождения в
`AUTH_PHONE_SMS.md`), плюс правки в §0 (диаграмма), §2 (лид и футер), §4
(состояние) и §7 (чек-лист). Текст дизайнера зачёркнут, а не удалён — видно, что
было и что решили.

То же расхождение живёт в `rn/AuraCreateAccount.tsx`. Файл — запись того, что
прислал дизайнер, и он оставлен как есть; пометка «не портируй ссылку» стоит в
`rn/README.md`. Туда же добавлена шапка: `rn/` — референс, а не код приложения
(там свой `theme.ts` и Expo-библиотеки, у нас ни того, ни другого).

## Заодно

`.claude/aura-build-rules.md` — в таблицу документов хэндоффа добавлены строки
`PROFILE_FORMS.md` и `rn/`.
