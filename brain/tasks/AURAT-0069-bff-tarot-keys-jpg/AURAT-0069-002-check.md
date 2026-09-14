# AURAT-0069-002 — что уже есть

Дата: 2026-09-14 · slave-2 · `feature/AURAT-0069-bff-tarot-keys-jpg`

## Где лежит 001

`AURAT-0069-001-initial.md` заведён из `aura-app-manor` и уже в `aura-missus`
(`098f446`) — в этой папке он есть. ID выдан там; здесь новый не резервируется
(`AURAD-0006`). Нумерация продолжается с `002`.

## Что нашлось в brain

| Документ | Комментарий |
|---|---|
| `tasks/AURAT-0069-bff-tarot-keys-jpg/001-initial` | бриф: 78 ключей `.png` → `.jpg`, спеки, манифест, upload-скрипт |
| `decisions/AURAD-0012-tarot-deck-storage.md` | правило «живой ключ не перезаписывают, новый арт — новыми объектами»; описывает PNG 413×712 |
| `decisions/AURAD-0012-deck-manifest.json` | 78 строк с `key` / `sha256` / `bytes` под `.png` — после перезалива неверен |
| `decisions/AURAD-0012-upload.sh` | ищет `*.png`, ставит `image/png` |
| `tasks/AURAT-0049-tarot-deck-backend/` | колода на сервере; `AURAT-0049-deck.json` с `.png` — история задачи, не правится |
| `tasks/AURAT-0051-*` | расклад в чате — ссылается на карту по FK |

Задача не начиналась: ни ветки, ни шагов, кроме `001`.

## Состояние слота

- Манор синхронен с origin: `aura-bff` `develop` = `daf42bd`,
  `aura-missus` `master` = `098f446`.
- `wts-start slave-2 feature/AURAT-0069-bff-tarot-keys-jpg` отработал, обе ветки
  от манора, preflight пустой.
- `active-work.md`: slave-2 → busy.

## Дальше

`003-understand`.
