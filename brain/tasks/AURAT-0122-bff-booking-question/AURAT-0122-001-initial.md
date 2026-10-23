# AURAT-0122-001 — Initial (исполняется в `aura-bff-manor`)

Date: 2026-10-22
Слот: `slave-1`, ветка `feature/AURAT-0122-bff-booking-question` (обе репы).
Фича: `AURAF-0020` (веб-клиент), строка **028**, колонка BE.

Слова владельца (о вебе, `aura-web-manor`): «воронка когда юзер после get started
зарегался и перешел на выбор адвайзора выглядит по другому, у нас нет такой навигации,
кажется нет best match и я явно просил именно на этом шаге воронки убрать кнопку free
chat» + скриншот «Matched advisors» хендоффа.

Выбор владельца в `aura-app-manor`: «Да + строка 028 в BFF». ID `AURAT-0122` выдан там
(счётчик поднят); здесь новых ID не выдаём.

Строка `AURAF-0020-028`: «В брони есть поле „вопрос советнику" (Ask этапа 2): вопрос из
`/match` уходит вместе с бронью и показывается советнику».

Контекст из `aura-app-manor` (не слова владельца):
- Воронка веба по хендоффу (`aura_web/design_handoff_aura_web/NAVIGATION.md` §2.1–§2.3,
  Booked; README §4.1): вопрос на Home → вход → `/match` (3 советника, только Book session,
  без free chat) → шторка Book с карточкой вопроса («will be shared with the advisor») →
  оплата → Booked «{name} has your question and will prepare before you meet».
- Параллельно `AURAT-0121` (`aura-web-manor`): `/match` и UI вопроса в Book / Booked — ждёт
  форму поля из этой спеки (через общий brain).
- Сейчас (`aura-bff` `develop` @ `215896b`): `BookSessionRequest` = `{ startsAt?, startNow?,
  minutes, idempotencyKey }`, вопроса нет; формы — `@aura/contracts` v0.23.0.
- Решить в спеке: форма поля (необязательный `question`, 250 символов как у Ask веба);
  хранение на сессии (миграция); как вопрос видит чаттер (без дубля); отдаётся ли вопрос
  в `Session`; идемпотентность; текст не в логах; версия contracts и порядок с вебом.
- Спека — на одобрение владельцу до кода. Merge gate — только с разрешения владельца.

Next: 002-check.
