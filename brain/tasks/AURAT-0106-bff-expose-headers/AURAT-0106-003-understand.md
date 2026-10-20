# AURAT-0106-003 — understand

Браузер веб-клиента должен видеть из JS заголовки ответа BFF `Date` и `Retry-After`.
Сейчас CORS их не открывает, и `serverNow()` в вебе молча идёт по часам устройства.
Нужно добавить `exposedHeaders: ['Date', 'Retry-After']` в `webCorsOptions`, остальную
политику CORS не трогать, покрыть тестами в `web-origins.spec.ts`, в том числе 429.
