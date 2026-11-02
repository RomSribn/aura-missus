# AURAT-0153-002 — check

Новая задача, папки под `AURAT-0153` не было. Пара в приложении — `AURAT-0152`
(`aura-app-manor` slave-1), на 2026-11-02 у неё только `001-initial`.

Похожие задачи раньше:
- `AURAT-0087` (приложение): страна по умолчанию берётся из локали устройства, если туда можно
  отправить SMS; иначе Испания. Это `deviceCountry()` в
  `aura-app/src/screens/phone-auth/lib/device-country.ts`.
- `AURAT-0104` (веб): вход по телефону, порт того же правила, `preferredCountry(navigator.languages)`
  в `features/auth-by-phone/lib/countries.ts`.
