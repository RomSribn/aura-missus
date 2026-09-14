# AURAT-0069-007 — сделано

Дата: 2026-09-14 · slave-2 · `feature/AURAT-0069-bff-tarot-keys-jpg`

Не закоммичено — на ревью в IDE (оба репозитория застейджены).

## `aura-bff` — 10 файлов, 94 замены

| Файл | Что |
|---|---|
| `src/modules/tarot/tarot-deck.data.ts` | 78 `imageKey` → `.jpg`; шапка: перезалив JPEG 10.09, ключи переставлены в `AURAT-0069`, порядок нарушен и чем это кончилось |
| `src/modules/tarot/tarot-deck.data.spec.ts` | `` `tarot/${row.id}.jpg` `` |
| `src/modules/tarot/daily-card.spec.ts`, `tarot.service.spec.ts`, `tarot.smoke.spec.ts`, `src/modules/chat/chat.service.spec.ts`, `src/contracts/tarot.spec.ts` | фикстуры таро и регэксп `imageUrl` → `.jpg` |
| `prisma/schema.prisma`, `.env.example`, `src/common/assets/asset-url.ts` | пример ключа таро в комментарии → `.jpg`; аватарные примеры не тронуты |

Миграции нет (в схеме изменился только комментарий). `src/generated/` в
`.gitignore` — встроенная копия схемы обновится при `prisma generate` на сборке.

## `aura-missus` — `AURAD-0012`

- `AURAD-0012-deck-manifest.json` — 78 строк: `key` → `.jpg`, `sha256` / `bytes`
  сняты с объектов публичного домена (ETag = MD5 сошёлся 78/78), `sourceFile` →
  `<card>.jpg`, `originalFile` сохранён (переэкспорт того же дропа — `006`).
  78 различных хешей, 13 608 226 байт всего. Формат файла (отступ 1) прежний.
- `AURAD-0012-upload.sh` — `*.jpg`, `--content-type image/jpeg`.
- `AURAD-0012-tarot-deck-storage.md` — дописан раздел «Перезалив в JPEG —
  2026-09-10»: что в тексте выше устарело (таблица), правило «новые объекты»
  выдержано / порядок нет, уточнение «старые объекты удаляются только после
  деплоя, переставившего ключи», заметка для приложения про пропорцию 1,467.
  Текст выше и статус решения не менялись.

## Проверки в слоте

| Ворота | Результат |
|---|---|
| `npm run lint` | exit 0 |
| `npm run typecheck` | exit 0 |
| `npx jest` | 64 набора, **855 тестов, все зелёные** |
| `grep` таро-`.png` в `src/`, `prisma/`, `.env.example` (без `generated`) | пусто |
| ключи `TAROT_DECK_SEED` против ключей манифеста | 78 = 78, множества совпадают |
| 78 × `https://assets.aura-app.cc/tarot/<card>.jpg` | 200 (проверено в `004`) |

## Открытое

- Живая проверка только после мёржа (= деплой, `AURAS-0004`): в логе старта
  `seeded 78 tarot cards`, на устройстве арт у карты дня и у раскладов в
  истории чата.
- Не наша правка: устаревший комментарий о пропорции в
  `aura-app/src/entities/tarot/config/card.ts` и `cover` теперь режет бока —
  за `aura-app-manor`.
- Старые PNG-объекты уже удалены владельцем; в бакете держать нечего.

Дальше: ревью владельца в IDE.
