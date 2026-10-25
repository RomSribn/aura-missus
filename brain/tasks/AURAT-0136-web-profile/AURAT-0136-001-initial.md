# AURAT-0136-001 — Initial (исполняется в `aura-web-manor`)

Date: 2026-10-23
Фича: `AURAF-0020` (веб-клиент), строка плана `AURAF-0020-010` — «Человек правит профиль,
видит баланс и купоны, настраивает уведомления, удаляет аккаунт, выходит». ID выдан в
`aura-app-manor/active-work.md` (абзац «AURAT-0136 / AURAT-0137»), новых не минтить.

## Слова владельца

> давай тогда занесем это в беклог и продолжим работу по вебу за планом, что там еще осталось по
> имплементации, кроме платежки?

> а как же профайл, редактирования данных?

> Профиль /me (010), Карта дня (013), Контраст (AURAT-0123)

## Контекст из `aura-app-manor` (не слова владельца)

- Три задачи параллельно: 0136 (`/me`) — slave-1, 0137 (карта дня) — slave-2, 0123 (контраст) —
  slave-3. База: aura-web develop `280988a`, brain master `9210fc3`.
- Способы входа (`AURAD-0021`) — в бэклоге: вход только по телефону, раздела «Способы входа» нет
  (строки 050…052). Оплаты на вебе нет до PSP (`AURAF-0009`): при нехватке — «пополните в
  приложении».
- 0123 может поменять токены цвета текста; 0136 берёт цвета только из токенов. Общие файлы
  (router, locales, layout) — конфликты решает манор при мёрже.
- Сейчас `/me` временная (имя, телефон, Log out — `AURAT-0104`). Цель — веб-хендофф §4.7
  («Aura Web - Sessions - Profile.html»): Account (Name, Phone locked, Email, Date of birth;
  пустые — «Add …»), Balance и купон, шторка Edit profile (фото и поля, Save — только при
  изменениях), разделы Payments, Coupons, Notifications, Language, Privacy & legal (Terms,
  Privacy, Refund policy, Delete account), Help (FAQ, Contact support).
- BFF: `GET`/`PATCH /v1/me` (`ProfileResponse` / `ProfilePatchRequest`, лимиты), аватар
  `PUT`/`DELETE /v1/me/avatar`, `GET /v1/avatars/:avatarId`, `DELETE /v1/me` (`AURAT-0042`),
  `GET /v1/wallet`. Истории платежей и промокодов нет; push нет, есть только `marketingOptIn`;
  карта / Apple Pay — PSP (вне задачи). Что показывать — решить с владельцем на спеке.
- Почта — контактное поле без подтверждения; телефон менять нельзя.
- Поведение и валидация — как в приложении: `src/screens/profile`, `src/screens/edit-profile`,
  `src/features/profile-form`, `profile-photo`, `account-deletion`, `sign-out`; хендофф
  `PROFILE_FORMS.md`.

## Слот

`slave-1`, ветка `feature/AURAT-0136-web-profile` (master и missus) от develop `280988a` /
missus `9210fc3`.
