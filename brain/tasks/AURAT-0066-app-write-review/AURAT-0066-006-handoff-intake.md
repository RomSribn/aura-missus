# AURAT-0066-006 — интейк дропа выполнен

Дата: 2026-09-08
Часть 0 спеки. Сделано до апрува кода сознательно: владелец попросил обновить
хендофф прямым текстом, решений это не содержит, а от `AURAD-0014` не зависит.

## Положено как есть

- `REVIEWS.md`
- `screens/37-review-locked.png` … `41-review-sent.png` (5 файлов; в папке
  стало 39, ровно как в дропе — сверено списком, не счётчиком)
- `prototype/reviews.jsx`
- `rn/AuraStarPicker.tsx`, `rn/AuraWriteReview.tsx`, `rn/AuraReviewPrompt.tsx`

## Слито точечно, наши пометки целы

- **`README.md`** — вставлены §15c «Reviews», состояния `reviews` / `toast` и
  строка `reviews.jsx` в списке прототипа. Сохранены три наши правки: ссылки
  на `MOTION_AND_ICONS.md` вместо `CLAUDE.md` (2 места), пометка про занятые
  `video`/`mic`, поправка владельца про «Skip for now». Плюс в перечень
  `rn/` дописаны три новых порта — дизайнер свой же список не обновил.
- **`MOTION_AND_ICONS.md`** — добавлены строка про `REVIEWS.md`, три порта и
  `prototype/reviews.jsx`. **Остальное из дропа взято НЕ было, и это
  осознанно**: дропный `CLAUDE.md` в трёх местах отстал от собственного
  `README.md` того же дропа — «31 custom line icons» против 36, «video/mic
  unused» против занятых вложениями, и нет нашей записки про переименование.
  Взять его целиком значило бы откатить верное на неверное.
- **`rn/README.md`** — три строки таблицы и пример использования формы.
  Сохранены: шапка «Reference ports, not app code», записка про «Skip for
  now» и ссылка на `MOTION_AND_ICONS.md`.

## Взято из дропа целиком (наших пометок там нет, сверено)

`Screens Overview.html`, `Screens Overview-print.html`,
`prototype/{app,screens,settings-chat,tokens.css,Aura - Psychic App.html}`.

## Не тронуто

- `CHAT_ATTACHMENTS.md` — в дропе отсутствует; состав дропа неполон, это не
  удаление.
- `AUTH_PHONE_SMS.md`, `DAILY_CARD_TAROT.md`, `PROFILE_FORMS.md` — расходятся
  с дропом **только** нашими пометками (`AURAT-0044`, `AURAT-0048`,
  `AURAT-0062`); нового содержимого дизайнера в них нет, сверено построчно.

## Заодно

`.claude/aura-build-rules.md` — в таблице хендоффа появилась строка
`REVIEWS.md`, а в описании `rn/` — новые порты.

## Проверка

`diff -rq` дропа против проектной копии оставляет ровно ожидаемое: четыре
`.md` с нашими пометками, `CHAT_ATTACHMENTS.md` только у нас и
`CLAUDE.md` → `MOTION_AND_ICONS.md`. Ничего лишнего и ничего потерянного.
