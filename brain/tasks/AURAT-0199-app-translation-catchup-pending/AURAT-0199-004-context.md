# AURAT-0199-004 — context

Дата: 2026-11-08

- `features/chat/lib/translation.ts:141` — `translatedFromOf`: `find` по `pending || failed`, единственный потребитель —
  `ChatProvider.tsx:641` (параметр синка).
- `features/chat/api/chat-api.ts:22` — JSDoc `HistoryParams.translatedFrom`: «still `pending` or `failed`».
- `screens/chat-thread/config/locales/en.ts:107` — JSDoc `translation.failed`: «the server tries again by itself».
- `mergeTranslation` (`pending → failed → translated`, монотонно) — не трогаем: `failed → translated` всё ещё разрешён,
  вреда нет (по заглушке).
- `@aura/contracts` 0.31.0 в lockfile; JSDoc «`failed` окончателен» — в `main` `abafea0` без тега, пакет не поднимаем:
  типы не менялись, только комментарии.
- Тесты: `lib/__tests__/translation.test.ts:142` (`translatedFromOf`), `model/__tests__/ChatProvider.translation.test.tsx:261`
  («asks from the oldest reply still pending or failed», `failed` m2 → якорь m2) и `:288` («nothing unsettled»).
- Остальные «tries again» в `src` — про другое (доставка, согласие, пуш).
