# AURAT-0207-002 — check

Date: 2026-11-11. Слот `slave-1`, ветка `feature/AURAT-0207-bff-stripe-checkout` (master и missus от
develop `0638f5b` / missus `a4b8cdc`).

Свежая задача: в этом missus папки `AURAT-0207-*` не было. Шаг 001 скопирован как есть из
`aura-app-manor/project/manor/missus/brain/tasks/AURAT-0207-bff-stripe-checkout/` (там missus не
синхронизирован с origin с 2026-11-07). Основания (`AURAD-0023`, `AURAI-0013`, `AURAF-0009`,
`AURAF-0020`) читаются по путям `aura-app-manor` и сюда не копируются.

Родственные задачи в этом брейне (все закрыты), образцы для нового вида пополнения:

- `AURAT-0007` — кошелёк и заглушка пополнения;
- `AURAT-0027` / `AURAT-0030` / `AURAT-0077` — Google Play: проверка покупки, подписчик RTDN,
  возвраты (`AURAD-0010`);
- `AURAT-0081` / `AURAT-0082` — App Store (`AURAD-0017`);
- `AURAT-0100` — лестница сумм пополнения;
- `AURAT-0108` — веб-заглушка PSP (`TopUpProvider`, `/checkout`, опрос статуса);
- `AURAT-0109`, `AURAT-0119` — бронь после пополнения, быстрое пополнение.

Stripe в коде BFF нет. Дальше — 003 (понимание), 004 (контекст по коду).
