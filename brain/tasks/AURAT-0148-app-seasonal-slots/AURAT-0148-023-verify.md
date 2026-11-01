# AURAT-0148-023 — проверка на устройстве

Дата: 2026-11-01. Сборка staging с `755d6c5` (develop), bff-dev (winter, `WINTER5`, скидка 20 %).
Проверял владелец по списку из этого шага сессии (разделы 1–6: промо-пуш поверх модалок и при
открытой шторке, 409 `session_price_changed`, скидки в каталоге и бронировании, кэш конфига и орб,
внешний вид — снег по кругу, Daily Card и расклад в цветах сезона). Итог владельца: «все работает».

- FCM-токен A50 для «Send test message» взят из bff-dev `device_tokens` (read-only, по SSH,
  контейнер БД dev BFF `mcsybichhmrfwclma4pbzgnr`); промо-пуш с custom data `action=promo`,
  `code=WINTER5` из Firebase Console открывает шторку с кодом.
- Замечаний нет. Дальше — `wts-release slave-1` по отдельному «да» владельца.
