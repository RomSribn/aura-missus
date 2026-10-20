# AURAT-0106-010 — verify (bff-dev)

2026-10-20. `develop` `edd751e` выкатился на `bff-dev.aura-app.cc` сам (Coolify
следит за `develop`), заголовок появился через ~10 с после начала опроса.

- `curl -H 'Origin: http://localhost:5173' https://bff-dev.aura-app.cc/v1/advisors` →
  200, `access-control-allow-origin: http://localhost:5173`,
  `access-control-expose-headers: Date, Retry-After`.
- Настоящий браузер (headless Chrome, страница `http://localhost:5173` — локальный
  dev-сервер `aura-web`): `fetch('https://bff-dev.aura-app.cc/v1/advisors')` →
  `status 200`, `headers.get('Date')` = `"Tue, 20 Oct 2026 16:40:42 GMT"` (раньше
  `null`). `Retry-After` на 200 — `null`, как и должно быть.
- 429 на bff-dev не вызывали: бюджет rate-limit общий на IP, это заблокировало бы
  на минуту устройства владельца в той же сети. 429 в браузере проверен на
  продовой обвязке в `008` (`Retry-After` = `"50"`).
- Стек манора (`:3010`) не пересобирался — проверка на bff-dev идёт по тому же коду
  через настоящий прокси, это сильнее.

`AURAF-0020-017`: BE ✗ → ✓. Веб менять не нужно — `serverNow()` начнёт сверяться с
сервером сам.

Дальше: финальное одобрение владельца → коммит missus → `wts-release slave-2`.
