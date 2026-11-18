# AURAT-0209-016 — Открытый пункт `015` закрыт: веб выходит из аккаунта после удаления

Дата: 2026-11-18. Манор проверил, слот сверил по `aura-web` develop `60bf412`.

`features/delete-account/model/use-delete-account.ts:68` при исходе `deleted` вызывает `signOut()` —
Firebase signOut, `shared/api/firebase.ts:58`. То же при 401 `ACCOUNT_DELETED` (`:63`), если удаление
уже прошло. Шторка показывает «Your account has been deleted.» уже после выхода.

Фраза промпта 3 «…your account is deleted straight away and you are signed out.» остаётся как в
`015`. Манор принял `015`, `AURAT-0216-006` и `AURAT-0218-002`.

Открыто:
- ворота публикации `015` п. 5: прод-веб → `AURAT-0217` → `AURAT-0216` в проде → номер телефона;
- ответ владельца по ст. 8(7) — передаст манор.
