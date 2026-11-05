# AURAT-0157-010 — fix: review notes

Дата: 2026-11-05. Ревью дифа `009` (сессия-ревьюер по просьбе владельца) — правки до коммита.

**Major — исправлено.** `screens/profile/model/use-profile.ts`: после `AuthError(code)` алерт «Sign out failed»
показывал бы сырой код (`auth/network-request-failed`) — потребитель `error.message`, пропущенный в `004`.
Теперь `t(authErrorKey(error))`: сетевой сбой — «No connection. Check your network and try again.», прочее —
`error.generic` (раньше любой `Error` показывал свой текст как есть — сырое сообщение больше не доходит до
экрана). Тест `screens/profile/ui/__tests__/ProfileSignOut.test.tsx`: Firebase `signOut` падает с сетевой
ошибкой → в алерте эта фраза и кнопка «OK». Поиск других мест: `error.message` на экран больше нигде не
выводится; `getIdToken` ошибок не бросает (возвращает `null`).

**Nits — исправлено.**
- el `auth.appNotVerified`: «ενημερώστε την στην» → «ενημερώστε τη στην».
- Правило 5: `SegmentOption` — локальный тип `SegmentedControl.tsx` (убран из трёх index); `AUTH_SUPERSEDED` —
  без `export`.

Проверка: `npx jest --no-watchman` — 172 / 172 наборов, 1522 / 1522; lint 0 / 0; `tsc` чисто. Всё staged, не
закоммичено.
