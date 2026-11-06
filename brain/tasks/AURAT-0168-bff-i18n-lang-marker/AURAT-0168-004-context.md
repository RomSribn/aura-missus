# AURAT-0168-004 — context

Дата: 2026-11-06

Карта кода из `001` перепроверена по `develop` @ `c8d78cf` — номера строк сходятся. Дополнительно:

- **Query не мешает `lang`.** Схемы query — нестрогие `z.object` (лишний ключ отбрасывается), `.strict()` только в
  `campaigns/campaign-preset.ts` (тело). Маршруты без `@Query` query не читают. Глобальных хуков, кроме `APP_GUARD`,
  нет.
- **Маркеры.** Пишет только `SessionsService.announce` (`MARKER_CONTENT`, `sessions.service.ts:83-86`); все DTO
  сообщения — одна функция `toDto` (`chat.service.ts:337`): история, сокет, ответ отправки. Удалённое сообщение:
  `deletedAt` + `content: ''` (`prisma-messages.repository.ts:293`) — точное совпадение текста на нём не сработает.
  Пользователь может сам набрать «Your session has started» → маркер выводить **только** для `direction: 'system'`.
- **Сокет.** Рукопожатие читает из URL только `token` (`chat.gateway.ts:59`); серверного текста, кроме `Message`,
  в сокет не идёт → `lang` в сокете не нужен.
- **Chatwoot.** Атрибуты разговора: запись заменяет всю карту (`chatwoot.client.ts:424`), определения создаёт
  `desk:setup` только для `conversation_attribute` (`chatwoot.client.ts:470-479, 695`). Атрибуты **контакта** при
  `PUT /contacts/:id` **сливаются** с текущими — проверено по исходнику Chatwoot в `chatwoot-manor`
  (`contacts_controller.rb:177-193`, `contact_custom_attributes` → `merge`). Пуш имени в контакт уже есть: очередь
  `contact-name` → `ProfileService.pushNameToDesk` (читает строку пользователя при запуске; ставится и при первом
  создании контакта — `provisioning.service.ts`).
- **Пользователь.** У `User` нет поля языка (`schema.prisma:14-59`); удаление аккаунта обнуляет профиль через
  `CLEARED_PROFILE` (`prisma-account-erasure.repository.ts:37`).
- **App-config.** Тело собирает чистый `buildAppConfig`; ETag — sha256 от тела (новое поле покрывается само); кэш
  30 с в процессе, `invalidate()` при переключении кампании.
- **Контракты.** Порядок выпуска (память `aura-contracts-release-flow`): ветка → правка → версия + README →
  typecheck/build → `main` + тег `v0.28.0` → push (с одобрения владельца) → `npm install …#v0.28.0` в BFF.

Противоречий между брейном и кодом нет. Пункт NOT in scope `AURAF-0023` «язык в аккаунте или на сервере в v1»
сталкивается с атрибутом языка для чаттеров — вынесено владельцу (спека, решение 2).
