# AURAT-0096-009 — проверка на development (сессия по SSH)

Дата: 2026-10-17. Владелец: «посмотри в брейне доступ» → `ssh root@37.27.199.90`
(`AURAS-0004`, `AURAT-0073-016`). Секреты не выводились: токен Chatwoot брался из env
dev-контейнера внутри него самого.

## Окружение
- Dev BFF `mtnsnawmogikfwm0uvl1g1yc-184310516172`, образ `bc38e62` (выкатился сам после
  `wts-finish`); `CHATWOOT_ACCOUNT_ID=2`, inbox 3, Postgres `mcsybichhmrfwclma4pbzgnr`.
  Прод-BFF `de0sra2t…` остался на `30930a2`. Мерж в `main` для теста не нужен:
  Chatwoot из `main` обслуживает оба аккаунта, dev-BFF из `develop` ходит в аккаунт 2.

## `--dry-run`
`recipients: 7 · skipped: 4 offer used, 0 no thread, 0 already sent · would send: 3 (0 without device)`.

## `--only cmvcngelf00iz01nj2lxjwxw3` (тестовый юзер владельца, оффер использован)
`sent: 1`. Диалог — sunshine, Chatwoot conversation 25.
- store: message `2836`, `ADVISOR`, `sessionInvite = true`, токен вырезан, текст — утверждённый;
  записан в ту же секунду, что создан в Chatwoot (webhook).
- Chatwoot: `message_type` outgoing, `private: false`, отправитель — service-user;
  метка `promo-first-50` на диалоге; на аккаунте создана, `show_on_sidebar`.
- assignee — `null` (наш ответ не назначил диалог на service-user); статус `open`,
  activity-строки о смене статуса нет.

## Ждём
Владелец смотрит на телефоне (staging): пуш, персона, карточка записи с «−50%».
Затем — полный прогон на dev (3 юзера) и повторный (`sent: 0`).
