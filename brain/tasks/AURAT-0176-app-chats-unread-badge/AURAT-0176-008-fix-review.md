# AURAT-0176-008 — fix: ревью кода координатора

2026-11-07. Ревью slave-1-ac (три направления, у каждого проверяющий; прогон в слоте зелёный). Владелец: «передавай всё,
влетание поправь в 0176».

1. [major] Android TalkBack: на вкладке Chats остаётся старое значение после N → 0 (`accessibilityValue` undefined —
   `BaseViewManager` пересчитывает contentDescription только при ключе `text`) → всегда `{ text: … | '' }` у Chats;
   тест 2 → 0.
2. [minor] Тесты провайдера: медленное первое чтение + сокет; удаление до догона и `deletedIds` после засчёта; отказ
   первого чтения + `onOpen`; `loadOlder` со старыми сообщениями советника.
3. [nit] `ChatListRow` `paddingLeft: 8` → `theme.spacing.sm`.
4. [решение владельца] «Влетание» при открытии треда поверх треда: мемо прибытий не знает смены `advisorId` → все
   строки B «влетают», `advisorArrivals` +1; переезжают `wanted` / `nearTop` / `metrics` / `jumping` → `lastAdvisor` в
   ref: `opening = true`, очистка `seen` / `arrivedAt` / базы `firstArrivals`; в эффекте — `metrics`, `wanted`,
   `nearTop`, `jumping`. Тест: после A → B ни одна строка не live, `loadOlder(B)` не вызывался.
