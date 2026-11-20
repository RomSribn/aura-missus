# AURAT-0223-010 — неразрывный пробел в `shared:minutes`

2026-11-20, по просьбе манора `manor-8e`. Пока жду 5556.

- **Зачем.** На скриншоте `after-12` (детали сессии, ×2.0) «12:00 – 12:10 · 10 Min.» переносилось между «10» и «Min.».
  Та же строка стоит в чипах QuickBookSheet, SessionBlockSheet и BookReview.
- **Что сделано:**
  - `{{count}} <единица>` во всех формах `minutes_*` (one / few / many / two / zero / other) во всех 24 языках
    `shared/config/locales` — 71 строка;
  - JSDoc `minutes` в `en.ts` дополнен;
  - `pastMeta` (sessions/lib) больше не обрабатывает минуты: они приходят уже склеенными. `noBreakSpaces` остался
    только для даты «9. Nov.».
- **Тесты.** Обновлены ожидания: `format-session.test`, `SessionBlockSheet.test` (2), `paid-session-language.test` (1).
- **Не трогал.** Остальные ~19 строк «{{count}} min» (booking, paid-session, chat-thread, chats, session-detail,
  promo-code) — манор предложит владельцу отдельную задачу (проверка в тесте переводов + массовая правка).

tsc чисто, lint чисто, jest 279 / 3524 зелёные. Застейджено, не закоммичено.
