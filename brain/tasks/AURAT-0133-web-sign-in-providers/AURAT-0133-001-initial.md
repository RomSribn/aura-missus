# AURAT-0133-001 — Initial (исполняется в `aura-web-manor`)

Date: 2026-10-23
Решение: `AURAD-0021`, разбор `AURAI-0008` (`brain/investigations/AURAI-0008-web-sign-in-methods/`).
Выдан в `aura-app-manor` по просьбе владельца («давай, выдавай», 2026-10-23). Не начата, слот не назначен.

Google, Apple, Facebook на вебе (`AURAD-0021` Р1, Р2, Р4, Р8). Зависит от `AURAT-0128` (консоли)
и `AURAT-0129` (дизайн).

- Синхронизировать хендофф в `.claude/design_handoff_aura_web` (README §4.4 от 2026-10-23).
- `deploy/web/nginx.conf`: прокси `/__/auth/` и `/__/firebase/init.json` →
  `aura-2781b.firebaseapp.com`, без `frame-ancestors 'none'`; `VITE_FIREBASE_AUTH_DOMAIN` = домен
  веба; CSP — `apis.google.com`, `frame-src 'self'` и что покажет консоль браузера.
- `shared/api/firebase.ts`: `popupRedirectResolver` (лениво); popup на desktop, redirect на
  телефоне и во webview; `getRedirectResult` + resume через `aura.auth`.
- Распознавание webview — чистая функция с тестами на реальные UA; ряд кнопок по таблице Р2.
- Вопрос «уже есть Aura в приложении?» при `isNewUser` до первого запроса к BFF; ветка «да» —
  удалить пустого пользователя, SMS, `linkWithCredential`.
- **Первым делом на web-dev:** впускает ли Firebase Google / Apple в uid с той же подтверждённой
  почтой (от этого зависит `link-by-email` в `AURAT-0132`).
- Строка «One account for the app and the web…» уточняется (Р7). Шаг имени без Skip (Р8). Строки
  на 24 языках. Проверка — манор: redirect, Instagram-webview на телефоне, Safari с блокировкой кук.
