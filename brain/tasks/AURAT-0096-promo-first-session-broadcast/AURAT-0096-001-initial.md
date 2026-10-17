# AURAT-0096-001 — разовая рассылка промо −50% через Chatwoot

Дата: 2026-10-17
Слот: `aura-bff-manor` / slave-1, ветка `feature/AURAT-0096-promo-first-session-broadcast`
(от `develop` @ `82be18d`). ID выдан в `aura-app-manor` (counter → AURAT-0097).

## Что сказал владелец

> продумай, как мне на проде с чатвута сделать рассылку всем диалогам, где не было
> сессии, т.е. юзерам новеньким красиво сообщение с информацией, что они могут
> обновить приложения для получения оффера в −50%. Приложения нет в App Store, так
> что можно всем рассылать.

Затем: «можно проверить на деве сперва? чатвут у нас только с main идёт, а проектов
в чатвуте 2» → «делай сам, текст утверждаю».

## Согласованный план (из обсуждения в сессии)

- Разовая операторская команда BFF по образцу `desk:setup` / `reviews:*`.
- Кому: юзеры с **неиспользованным** первым оффером (`firstSessionOfferUsed`), не
  удалённые, с ≥ 1 диалогом. Один диалог на юзера — самый свежий по активности.
- Отправка — публичное `outgoing` от service-user → штатный webhook → store → FCM+WS.
- Идемпотентность — метка Chatwoot `promo-first-50`; режимы `--dry-run`, `--only <userId>`,
  полный прогон с троттлингом ~1 msg/s.
- Сначала dev (Chatwoot аккаунт 2, `bff-dev` из `develop`), потом прод (аккаунт 1, `main`).

## Утверждённый текст (EN)

> Good news — your first session with me is now 50% off ✨
> It's applied automatically, no code needed. Update Aura in Google Play to see it right on the booking screen, then pick a time that suits you.
