# AURAT-0136-011 — Fix: ревью манора — пережатие фото и мелочи

Date: 2026-10-25

Ревью манора (вставлено владельцем): до коммита — пережимать фото в браузере, как приложение
(aura-app `features/profile-photo/config/photo.ts`: 1024 px, JPEG 0.9; у сервера нет обработки
картинок, `AURAT-0064-004`). Без этого 24-Мп снимок iPhone получает отказ (> 4096 px), координаты
из EXIF уходят на сервер и в Chatwoot, поворот остаётся только в EXIF, аватар весит мегабайты.

## Фото

- `features/edit-profile/lib/prepare-photo.ts` — `preparePhoto(file)`: декод через `<img>`
  (`decode()`; ориентация EXIF применяется и при отрисовке), canvas с длинной стороной ≤ 1024
  (`fittedSize`), заливка белым (PNG с прозрачностью), `toBlob('image/jpeg', 0.9)` → `File`
  `avatar.jpg`. Не прочитался / не закодировался → null → «That photo could not be read»
  (`empty`, без новых строк).
- `lib/photo-refusal.ts`: `pickedPhotoError` (пустой, тип — на исходнике), `preparedPhotoError`
  (8 МБ — на результате); `localPhotoError` удалён.
- `model/use-profile-photo.ts`: проверка исходника → пережатие → превью пережатого → `PUT`.
- `config/photo.ts`: `PHOTO_MAX_SIDE`, `PHOTO_TYPE`, `PHOTO_QUALITY`, `PHOTO_NAME`,
  `PHOTO_BACKDROP`.
- Тесты: `prepare-photo.test.ts` (canvas и `Image` замоканы — в jsdom их нет),
  `photo-refusal.test.ts`; в `profile.test.tsx` `preparePhoto` замокан, проверено, что уходит
  пережатый `avatar.jpg`, и отказ нечитаемого файла без запроса.
- Поворот на портретном снимке iPhone — проверка в маноре (раздел 9 спеки).

## Мелочи из ревью

- Account и карточка: пока профиль не прочитан — пустые значения, без «Add …» и без Edit;
  чтение упало — строка «Your profile didn't load.» + «Try again» (повторное чтение
  `useReadViewer`). Строки `account.failed`, `account.retry` — en + 23 языка.
- Длина полей: имя ≤ `MAX_DISPLAY_NAME_LENGTH` (64), почта ≤ `MAX_EMAIL_LENGTH` (254) — `maxLength`
  в `ProfileFields` (и в «Tell us who you are»).
- Разметка Account: Edit / Add и замок — внутри `dd`; у `dd` и `dl` сброшены отступы браузера
  (был лишний отступ 40 px у значений).
- Текст FAQ («the chat opens when the session starts» рядом с «message an advisor for free») — не
  трогал, ждёт решения владельца (правка в 24 языках).

Проверки: typecheck, lint, vitest (88 / 1574), build — зелёные.
