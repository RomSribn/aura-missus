# AURAT-0199-001 — initial (заглушка)

Дата: 2026-11-08
Репо: `aura-app-manor` (приложение). Выдан координатором (сессия «Локализация i18n для aura-app»). Фича `AURAF-0024`;
решение 1 «А» спеки конвейера `AURAT-0198-005` §6, одобрено владельцем (`AURAT-0198-006`): «Малую задачу приложения
(«якорить догонку только на `pending`») выдаёт координатор после мёржа».

Владелец: «запускай 0199, Originaltext оставляем».

## Что нужно

`failed` у перевода ответа советника теперь окончательный. Всё, что сервер ещё может дозаполнить, — `pending` (не дольше
~20 мин: повторы задачи и один перезапуск сторожем). JSDoc контрактов — `main` `abafea0` (без тега): «`failed`
окончателен; `translatedFrom` — самое старое `pending`». Приложение якорит догонку на самом старом `pending` **или**
`failed`: окончательный `failed` держит якорь вечно — каждый синк просит `translations` от него, и окно только растёт.

- `features/chat/lib/translation.ts` — `translatedFromOf`: самое старое серверное сообщение советника с переводом
  `pending`; `failed` не якорит. JSDoc — по контракту.
- `features/chat/api/chat-api.ts:24` — JSDoc `translatedFrom` («`pending` or `failed`» → `pending`).
- `screens/chat-thread/config/locales/en.ts` — JSDoc ключа `translation.failed`: «the server tries again by itself» уже
  неверно — перевода не будет, остаётся английский. Только комментарий для переводчика: строка и 23 перевода не меняются.
- Тесты:
  - `features/chat/lib/__tests__/translation.test.ts` — `translatedFromOf`: `failed` старше `pending` → якорь на
    `pending`; только `failed` → без догонки;
  - `features/chat/model/__tests__/ChatProvider.translation.test.tsx` — «asks from the oldest reply still pending or
    failed».
- Монотонное слияние `mergeTranslation` не трогать.

## Не здесь

- Сервер и контракты — готовы (`AURAT-0198`, JSDoc `abafea0`).
- Подпись «Originaltext» (de) — владелец: оставляем.
- Перевод при чтении — бэклог (`active-work.md`, «Paused»).

## Контекст слота

Заполняется при запуске: свободный слот `aura-app-manor`, ветка `feature/AURAT-0199-app-translation-catchup-pending` от
`develop`. ID уже выдан — не резервировать.
