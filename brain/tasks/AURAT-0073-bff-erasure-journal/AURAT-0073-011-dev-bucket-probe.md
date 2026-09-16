# AURAT-0073-011 — Dev-бакет заведён, токен проверен

Дата: 2026-09-16

Владелец завёл бакет `aura-erasure-journal`, правило хранения и токен, и
передал ключи в сессию. Ключи и id аккаунта сюда не записаны.

## Проверка токена из слота (aws cli, EU-эндпоинт)

**Должно пройти — прошло:**

| Операция | Ответ |
|---|---|
| `put-object probe/probe.txt` | ok |
| `get-object` | ok, содержимое совпало |
| `list-objects-v2` | ok, виден один ключ |
| `delete-object` | ok, бакет снова пуст |

- EU-эндпоинт (`<account>.eu.r2.cloudflarestorage.com`) бакет находит, значит
  юрисдикция EU.
- **Правило хранения работает:** `put` и `get` вернули заголовок
  `Expiration: expiry-date="Sat, 31 Oct 2026 …", rule-id="expire-45d"`, то есть
  ровно 45 дней от записи (16.09 → 31.10).

**Должно отказать — отказало (`AccessDenied`):**

- `list-objects-v2` по `aura-user-media`, `aura-user-media-prod`,
  `aura-backups`, `aura-assets`, `aura-chatwoot`;
- `create-bucket`;
- `get-bucket-lifecycle-configuration` — так и должно быть: токен объектный,
  не админский. Правило подтверждено заголовком `Expiration` выше.

Пробы через эндпоинт без `.eu.` не дошли до R2: на этой машине TLS-ошибка
(`self-signed certificate`), и это не ответ токена. Для области токена
достаточно `AccessDenied` через EU-эндпоинт по всем пяти бакетам.

## Осталось по шагу A

Четыре `ERASURE_JOURNAL_*` в Coolify `development` → `aura-bff` (runtime-only),
затем Redeploy. Потом проверка в маноре по `005`.
