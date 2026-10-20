# AURAT-0102-012 — approved

2026-10-20. Владелец принял задачу после живой проверки в маноре (`011`).
Status: **done**.

Итог: BFF доступен браузеру — CORS и `Origin` на `/ws` по `WEB_ALLOWED_ORIGINS`
(пока только `http://localhost:5173`), гостю открыты каталог, слоты и цена;
мобильное приложение не затронуто. `@aura/contracts` без изменений.
Код — `aura-bff` `develop` @ `4bc1504`.

За владельцем (ops): веб-домены в `WEB_ALLOWED_ORIGINS` dev/prod и в Firebase
Authorized domains, когда появятся; App Check — по желанию.
