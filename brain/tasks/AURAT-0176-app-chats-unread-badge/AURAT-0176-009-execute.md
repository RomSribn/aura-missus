# AURAT-0176-009 — execute (fix по `008`)

2026-11-07, slave-2. Всё в stage, не закоммичено.

1. `app/navigation/AuraTabBar.tsx` — у Chats `accessibilityValue` всегда `{ text }`, при 0 — `''` (Android пересчитывает
   contentDescription только при ключе `text`). Тест: 2 → 0, `{ text: '' }`; при 0 label «Chats».
2. `ChatProvider.unread.test.tsx` +5: медленное первое чтение + сокет → 1; удалено до прихода → 0; `deletedIds` догона
   после засчёта → 0 и `unreadThreads` 0; отказ первого чтения + `onOpen` → 0; `loadOlder` → 0. Каждая регрессия из
   ревью (решение «при слиянии», нет фильтра удалённых, нет очистки в `removeServerMessages`) проверена мутацией —
   тест падает. Попутно: деревья теперь размонтируются в `afterEach` — мок `AppState` хранит всех слушателей, и
   провайдер прошлого теста перезаписывал пробу текущего (на этом сперва упал тест «удалено до прихода»).
3. `ChatListRow` — `paddingLeft: theme.spacing.sm`.
4. «Влетание» (`use-thread-scroll.ts`): `lastAdvisor` в ref — при смене `advisorId` мемо прибытий считает это
   открытием, `seen` / `arrivedAt` очищаются до разметки B. Эффект смены `advisorId` перенесён ниже, перед эффектом
   старых страниц, и дополнительно сбрасывает `firstArrivals`, `metrics` (offset / content 0), `wanted`, `nearTop`,
   `jumping`. Тест экрана: A у верха с запрошенной страницей → B: ни одна строка не `popIn`, `before` для B не
   спрашивался; обе части проверены мутацией.

lint, tsc — чисто; Jest — 221 сьюта, 3029 тестов, всё зелёное. TalkBack 2 → 0 — проверить в manor.
