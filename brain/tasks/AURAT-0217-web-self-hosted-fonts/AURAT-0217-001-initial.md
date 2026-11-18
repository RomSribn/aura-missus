# AURAT-0217-001 — Initial: шрифты веба со своего домена, включая форму Stripe Elements

Date: 2026-11-17
Выдана в `aura-app-manor` slave-0 из `AURAT-0209` (`AURAT-0209-008`, владелец: «Задача веба: свои
шрифты»). Исполняется в `aura-web-manor`.

## Зачем

`aura-web/index.html:10–14` грузит Bricolage Grotesque и Hanken Grotesk с `fonts.googleapis.com` /
`fonts.gstatic.com` на каждой странице, а Elements — через `cssSrc` (`features/pay/config/pay.ts:47`).
IP каждого посетителя уходит Google без согласия (LG München I, 20.01.2022, 3 O 17493/20). Новая
Privacy §12 (`AURAT-0209` B8) пишет, что веб-приложение этого не делает — значит, до её публикации
шрифты должны идти со своего домена.

## Что нужно

- Файлы шрифтов (woff2, нужные начертания и наборы символов — все 24 языка, в т.ч. греческий и
  кириллица, как в приложении `AURAT-0156`) — в бандле веба, `@font-face` вместо ссылок Google.
- `cssSrc` для Elements — CSS со своего домена (публичный URL, Stripe его загружает в своём фрейме),
  либо `fonts: [{ family, src }]` с URL своего домена.
- CSP: убрать `fonts.googleapis.com` / `fonts.gstatic.com`.
- Проверка: в сети браузера ни одного запроса к Google Fonts, ни на страницах, ни в шторке оплаты.

## Срок

До публикации `AURAT-0209` (Privacy B8) — иначе B8 придётся дописывать Google Fonts.
