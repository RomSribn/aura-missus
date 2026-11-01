# AURAT-0148-014 — 0147 на bff-dev (проверка манора)

Дата: 2026-11-01. Со слов манора: bff-dev выкатил 0147; правки `-013` манором приняты.
- `GET /v1/app-config` → 200 `{"season":null,"promo":null,"discount":null}`, `Cache-Control: public,
  max-age=60`, слабый ETag, `If-None-Match` → 304. Совпадает с разбором приложения (все части `null` → нет кампании).
- Pricing (sunshine): `blocks[].discount = {kind: "first_session", pct: 50, label: null}` → у приложения вид `offer`.
- Бронь с неверным `expectedCostMinor` → 409 `session_price_changed`; с верным при балансе $0 → 402; без списаний.

Дальше: владелец создаёт кампанию (сезон + витрина + скидка) в бэкофисе → экраны 67–80 на A50 и
10 проверок из `-013` — в маноре после мёржа. Открыто: подтверждение владельцем M-2 (поправка §6 в `-006`),
ревью диффа и коммит в ветку.

## Живая кампания (2026-11-01, проверено из слота, только чтение)

`GET https://bff-dev.aura-app.cc/v1/app-config` → 200, ETag, `max-age=60`: сезон `winter` (палитра
`presets/winter.json`, `snow`, 9 текстов, `art: null`), `promo` WINTER5 / 500, `discount` 20 % «Winter sale»,
окно до 2026-11-04T00:00Z. Ответ прогнан через код приложения (временный тест, удалён):
- разбор: все три части приняты, палитра проходит P1–P20;
- hero: «Long nights, clear answers» / «$5 on us for a winter reading.» / кнопка «Apply WINTER5», без арта
  (экран 70), эффект `snow`;
- билет: свежий аккаунт (оффер 50 > 20) — welcome в коже winter; оффер использован — discount «Winter sale ·
  20% OFF sessions · Any advisor · applied at checkout»; code-билет «Winter gift · $5 on your balance»;
- кожа билета: стаб `#A82A40`, тень `rgba(168, 42, 64, 0.22)`, глиф — иконка (арта нет).
Замечание: `heroBodyNoCode` на bff-dev — «Cosy up with a reader tonight» (без «Chat is free.»), это текст кампании.

## Арт (2026-11-01, проверено из слота, только чтение)

`art.hero` = `https://assets.aura-app.cc/seasonal/winter/v1/hero.webp` (200, image/webp, 121 830 B — вариант
Canva), `art.ticket` = `…/winter/v1/ticket.webp` (200, image/webp, 3 746 B). Разбор приложения принимает обе
ссылки: hero рисует арт (экран 67), глиф билета — картинка вместо иконки. Ключи с версией `/v1/` — как
требует 0147. На устройстве — п. 10 списка `-013` (WebP и `Image.prefetch` на Android) и проявление арта 400 мс.
