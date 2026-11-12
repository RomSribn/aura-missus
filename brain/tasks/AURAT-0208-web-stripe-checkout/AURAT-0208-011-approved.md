# AURAT-0208-011 — Approved

Date: 2026-11-11. Status: **done**.

## Решение владельца

Владелец написал: «Включил на web-dev, проверил». На вопрос о проверке по списку из `007-spec-v2`
(«Проверка в маноре») ответил «Принято», на вопрос об освобождении слота — «Да, release».

## Итог

- В `develop` aura-web это `c7912bc`. Код задачи — в коммитах `0b48100` и `f10a86c`:
  - `0b48100` — контракты `v0.32.0`;
  - `f10a86c` — Stripe Checkout вместе с правкой ревью из `009`.
- web-dev в Coolify: `VITE_PSP_ENABLED=true`. Прод — `false`, пока не пройдены ворота live из
  `AURAD-0023`. `VITE_PSP_FAKE` в Coolify нигде не задаётся.
- `.claude/aura-web-build-rules.md`, раздел «Payments», переписан под `AURAD-0023` с «да»
  владельца. Файл воркспейса, не в git.

## Передать в aura-app-manor (правит пир)

- `AURAF-0020`:
  - 037 — UI ✓: настоящий провайдер карты вместо фейка, Stripe Checkout через BFF;
  - 038 — UI ✓: суммы по правилу $5–$120, лишнее остаётся на балансе, строки `planMin` / `tooMuch`;
  - 040 — UI ✓: отмена `cancelled=1`, сначала `cancel`, потом статус;
  - 041 — UI ✓: Back со страницы Stripe — из bfcache или свежей загрузкой, в обоих случаях
    `/checkout?…&cancelled=1`;
  - 039 — дело BFF (`AURAT-0207`).
- `AURAD-0023`:
  - веб на web-dev работает со Stripe sandbox;
  - фейк только в dev, сборку с ним роняет `build.sh`;
  - прод `false` до ворот live.

## Следующие задачи (выданы в aura-app-manor, запуск — командой владельца)

- `AURAT-0210-web-chat-season-translation` — поля контрактов `v0.30`–`v0.31` (язык сезонных
  текстов, перевод чата).
- `AURAT-0212-web-stripe-embedded-checkout` — встроенная форма Stripe в шторке Book. Начинается
  после выхода контрактов `v0.33.0` (`AURAT-0211`).
