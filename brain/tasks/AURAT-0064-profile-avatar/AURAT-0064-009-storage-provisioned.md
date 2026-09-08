# AURAT-0064-009 — Хранилище заведено и проверено

Дата: 2026-09-08

Бакет **`aura-user-media`**, R2, юрисдикция **EU** (`Specify jurisdiction`, а не
подсказка размещения — в нём фотографии людей). Storage class `Standard`.
Публичного доступа нет: ни custom domain, ни `r2.dev`.

Токен `aura-user-media-storage`, `Object Read & Write`, область — **только этот
бакет**, TTL `Forever`, фильтра по IP нет (проба и проверка в маноре идут не с
адреса сервера).

Эндпоинт несёт юрисдикцию: `https://<account_id>.eu.r2.cloudflarestorage.com`.
Форма без `.eu.` в этот бакет не попадает.

## Проверка

**Отрицательная — то, ради чего заводился отдельный бакет:**

| Операция | Ответ |
|---|---|
| `list-objects-v2 --bucket aura-assets` | `AccessDenied` |
| `list-objects-v2 --bucket aura-backups` | `AccessDenied` |
| `head-object aura-assets tarot/major-19-sun.png` | `403 Forbidden` |
| `create-bucket` | `AccessDenied` |

**Положительная — на `aura-user-media`:** `put` (вложенный ключ вида
`avatar/<userId>/<avatarId>.jpg`, `image/jpeg`) → `get` (тип и длина сошлись) →
`list` по префиксу → `delete`. Бакет после проверки пуст.

## Что поймала проверка

**Первый выписанный токен был на весь аккаунт.** «Apply to all buckets in this
account (including newly created buckets)» — `list-objects-v2` спокойно отвечал
по `aura-assets` и `aura-backups`. Права объектные, не админские
(`create-bucket` отказал), так что публичным бакет он сделать не мог — но писать
в колоду, в портреты советников и в дампы обеих баз мог.

Положительная проверка такой токен **пропускает**: с ним всё работает. Заметить
можно только пробой по чужому бакету. Область исправлена, ключи те же.

## Осталось

Четыре переменные в Coolify, **runtime-only** (`AURAS-0004`, ловушка 2 — иначе
секрет запекается в метаданные образа). Эндпоинт **без** хвоста с именем бакета:
Cloudflare показывает их склеенными, а схема окружения теперь такой адрес
отвергает при старте.
