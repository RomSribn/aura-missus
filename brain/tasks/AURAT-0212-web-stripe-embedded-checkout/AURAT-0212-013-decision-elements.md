# AURAT-0212-013 — Решение владельца: Elements в этой задаче

Date: 2026-11-12

На выбор из `012` (принять + Elements отдельно / держать открытой и делать Elements в ней /
оставить как есть) владелец, дословно: «держим открытой и делаем elements в ней».

- AURAT-0212 не закрывается. Embedded Checkout (develop `0e7b88d`) остаётся рабочим, пока не
  готов новый путь.
- Веб переходит на Elements с Checkout Sessions (`ui_mode: 'elements'`):
  - кнопки Apple Pay / Google Pay / Link (`ExpressCheckoutElement`) — в шторке Book у «Pay»;
  - карта — `PaymentElement` с нашей кнопкой и нашими текстами;
  - вид — Appearance API на наших токенах.
- BFF и контракты (новое значение `ui`) — отдельная задача BFF. ID выдаёт `aura-app-manor`, через
  координатора. Поправку `AURAD-0023` тоже делает `aura-app-manor`.

Дальше — контекст по Elements, затем спека v2 на одобрение.
