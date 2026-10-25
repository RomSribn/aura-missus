# AURAT-0134-001 — Initial (исполняется в `aura-web-manor`)

Date: 2026-10-23
Решение: `AURAD-0021`, разбор `AURAI-0008` (`brain/investigations/AURAI-0008-web-sign-in-methods/`).
Выдан в `aura-app-manor` по просьбе владельца («давай, выдавай», 2026-10-23). Не начата, слот не назначен.

Вход почтой на вебе (`AURAD-0021` Р3). Зависит от `AURAT-0131` (BFF) и `AURAT-0133`.

- Почта по умолчанию: поле + «Continue with email» → «Check your inbox» (Open Gmail / Outlook,
  «Enter code instead», повтор через 0:48, спам, сменить почту) → код из 6 ячеек, авто-проверка,
  «← Use the login link instead». Во webview Meta основная кнопка — «Enter code».
- Страница `/auth/email?t=…`: вход по нажатию «Log in to Aura», не на загрузке; впускает только
  этот браузер — ждущая вкладка того же браузера подхватывает вход сама; иначе «вы вошли здесь —
  на том устройстве введите код».
- `signInWithCustomToken`; `isNew` → вопрос «уже есть Aura?» (`AURAT-0133`) → «Tell us who you
  are» с заблокированной «Verified» почтой.
- Попытка переживает reload (`sessionStorage`, как SMS). Строки на 24 языках.
