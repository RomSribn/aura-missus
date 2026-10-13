# AURAT-0086-004 — context

Дата: 2026-10-12. База: `aura-bff` `develop` @ `ca2c5a6`; Chatwoot v4.15.1
(`chatwoot-manor/project/manor/master/chatwoot`).

## Код BFF (ground truth)

- Все переходы сессии сходятся в одну точку: `SessionsService.syncState`
  (`sessions.service.ts` ~строка 548) — вызывается из job `announce` (started/finished)
  и job `sync` (booking/reschedule/cancel/extend). Состояние берётся **по диалогу**
  (`findActiveByConversation` → `active`, иначе `findUpcomingByConversation` →
  `scheduled`, иначе `none`) и уходит в `ChatwootMessagingPort.syncSessionState`.
  ⇒ «метка висит ⇔ status === 'active'» вычисляется там же, бесплатно; extend даёт
  `active` → метку не снимает.
- `ChatwootMessagingService.syncSessionState` шлёт полный хеш: `advisor_id`,
  `aura_session_status`, `aura_session_starts_at` / `_ends_at` (пустая строка, если не
  применимо), `aura_paid_minutes_total`. `createConversation` пишет только
  `{advisor_id}`.
- Кроме BFF эти атрибуты никто не читает (grep по `src/` и виджету 0083) — формат
  значений можно менять.
- `AdvisorsModule` экспортирует `AdvisorsRepository.findById` (name, role, category
  LOVE/TAROT/PSYCHIC, priceMinorPerMinute, …); сам ничего не импортирует → chatwoot
  может импортировать его без цикла.
- Операторские CLI: `account:erase`, `contacts:push-names` (`src/contact-names.ts`) и др.
  на `OperatorCliModule`; длинную работу кладут в очередь, делает воркер приложения.
- Сервисный User Chatwoot — **administrator** в аккаунте (`AURAT-0042-007`,
  `deploy/chatwoot/provision-prod.rb:61`) — нужно для создания меток и definitions.

## Chatwoot v4.15.1 — проверено по исходникам

- `POST /conversations/:id/labels` → `update_labels` → `update!(label_list:)` —
  **заменяет** весь набор (`LabelConcern`, `Labelable`). ✔ Добавляющего эндпоинта нет
  (`add_labels` только для автоматизаций).
- **Новое:** каждое изменение `label_list` создаёт строку-активность в ленте
  («<имя сервисного юзера> added/removed paid-session», `LabelActivityMessageHandler`).
  Нормализатор BFF активности отбрасывает — на устройство не попадает; чаттер её видит.
- `POST /labels`: title приводится к lowercase, формат буквы/цифры/`-`/`_`, уникален в
  аккаунте; создавать — только administrator (`LabelPolicy`). Метку можно повесить и без
  записи в `labels` (acts_as_taggable), но тогда нет цвета и пункта в сайдбаре.
- `POST /custom_attribute_definitions` ✔ (поля как в брифе + `attribute_values` для
  `list`, `regex_pattern`); create/update — только administrator; ключ уникален в
  (account, model); стандартные ключи диалога запрещены (`status, priority, labels, …`) —
  наши ключи не конфликтуют.
- Панель «Conversation information» строит строки **из definitions** и подставляет
  значение из `custom_attributes` → без definition не видно. ✔
- Фильтр (`FilterService` + `CustomAttributeFilterHelper`): тип из definition,
  `ATTRIBUTE_TYPES = {date, text, number→numeric, link, list, checkbox}`;
  SQL `(custom_attributes ->> key)::<type>`.
  - **Ловушка 1:** у `currency` и `percent` типа фильтра нет → фильтр по такому
    атрибуту падает. Цену — типом `number`.
  - **Ловушка 2:** тип `date` + наше текущее значение `''` → `''::date` → ошибка
    Postgres на весь фильтр. Если `date` — ключ надо опускать/писать `null`.
  - `date` в панели показывает **только дату** (`toLocaleDateString`) — время начала/
    конца сессии теряется.
- Аккаунты: prod — 1, dev — 2 (из брифа; BFF берёт `CHATWOOT_ACCOUNT_ID` из env).

## Противоречия / уточнения к брифу

- Бриф верен по всем пунктам; добавлены: строка-активность при смене метки, ловушки
  `currency`/`date`, необходимость прав administrator (они есть).
