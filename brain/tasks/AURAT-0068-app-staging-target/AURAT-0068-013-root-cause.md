# AURAT-0068-013 — Причина по аватару и план

Дата: 2026-09-14

## Аватар: RN 0.85 на Android теряет `headers` у объектного `source`

Прочитано в `node_modules/react-native` (0.85.3):

- `ImageSourceUtils.getImageSourcesFromImageProps` оборачивает `{ uri, headers }`
  в массив, только если заданы `crossOrigin` / `referrerPolicy`. Иначе
  возвращает объект как есть (`sources = source`).
- `Image.android.js` достаёт `headers` **только в ветке массива**
  (`headers_ = source_[0].headers`); в ветке объекта берёт `uri`, `width`,
  `height` — и нативный проп `headers` не выставляется.
- `ReactImageView` берёт заголовки только из этого пропа
  (`setHeaders` → `ReactNetworkImageRequest.fromBuilderWithHeaders` →
  `ReactOkHttpNetworkFetcher`).
- iOS (`Image.ios.js`) приводит source к массиву всегда и читает заголовки из
  элементов — поэтому на iPhone аватар показывался.

Итог сходится с логами `012`: 10 из 10 запросов с Android без `Authorization`.
Сборка 17 вела бы себя так же — это дефект `AURAT-0065`, а не этой задачи;
найден её проверкой.

**Исправление:** `ProfileAvatar` отдаёт `source={[{ uri, headers }]}`. Массив из
одного источника на iOS равнозначен объекту; на Android включает ветку с
заголовками. Тест — под массив, с комментарием, зачем он.

## Карты: перезалив колоды

Арт на диске: `/Volumes/Work/personal/lightseerstarot/`. Скрипт —
`AURAD-0012-upload.sh` (сверяет sha256 с манифестом). Нужны ключи R2 на запись
в `aura-assets`. Запись в хранилище — только с разрешения владельца.

## Вложения

Запросов к `/v1/attachments` с телефона не было — нужен пример от владельца.
