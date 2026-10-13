# AURAT-0086-001 — initial

Дата: 2026-10-12. Слот `slave-4`, ветка `feature/AURAT-0086-desk-session-label-and-attributes`
(master и missus). ID выдан в `aura-app-manor` 2026-10-12 (здесь не минтим).

Запрос владельца (близко к тексту):

1. **Метка платной сессии.** Пока в диалоге идёт платная сессия (Session `ACTIVE`), на
   диалог Chatwoot автоматически навешивается метка (рабочее имя владельца — «payed»;
   предложить корректное, напр. `paid-session`, согласовать в спеке); по окончании
   (`FINISHED`/`CANCELLED`; extend не снимает) — снимается. Цель — видеть на карточке в
   списке и фильтровать (сайдбар `show_on_sidebar` / расширенный фильтр по Labels).
   Метки по адвайзорам НЕ делаем — владелец отказался.
2. **Определения кастомных атрибутов диалога**, чтобы были видны в панели
   «Conversation information» и фильтровались: существующие `advisor_id`,
   `aura_session_status`, `aura_session_starts_at`, `aura_session_ends_at`,
   `aura_paid_minutes_total` (сейчас невидимы — без definition Chatwoot не показывает)
   + новые данные адвайзора: `advisor_name` и что уместно из `advisors` (role, category,
   цена за минуту…) — состав предложить в спеке.

Факты из исходников Chatwoot v4.15.1 (перепроверить): `POST /conversations/:id/labels`
заменяет весь набор меток (гонка с ручной правкой); `POST /labels` создаёт метку;
`POST /conversations/:id/custom_attributes` заменяет весь хеш (BFF уже шлёт полный набор
в `syncSessionState`), агент может стереть значения — синк переписывает при каждом
событии; `POST /custom_attribute_definitions` (`attribute_model: conversation_attribute`,
ключ ≠ стандартным полям); фильтр берёт тип из definition. Аккаунты: prod — 1, dev — 2.
Метка и definitions — идемпотентный бутстрап (CLI по образцу операторских или при
старте), не ручные клики. Бэкфилл существующих диалогов — решить в спеке.

Параллельно: `AURAT-0083` (slave-2, виджет) — его зону в chatwoot-модуле не трогать
(операторская авторизация, read-эндпоинты, страница виджета); `AURAT-0085` (slave-3).

Вне объёма: email и дата рождения клиента в Chatwoot (privacy policy, `AURAT-0042-118`).

Спека — на одобрение владельца до кода. Merge gate — только с явного подтверждения.
