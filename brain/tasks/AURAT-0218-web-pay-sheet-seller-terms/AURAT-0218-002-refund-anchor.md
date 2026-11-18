# AURAT-0218-002 — Скоуп дополнен: якорь у ссылки «Refund & cancellation policy»

Дата: 2026-11-18 (`AURAT-0209-015` п. 4).

`pages/me/ui/me-sections.tsx:265`: «Refund & cancellation policy» ведёт на `LEGAL_URLS.terms` без
якоря, а надо на `https://aura-app.cc/terms/#s07` (решение владельца `AURAT-0209-006` п. 2). Лучше
завести в `shared/config/legal.ts` отдельный URL `refunds`, тот же, что и в ссылках шторки оплаты.
