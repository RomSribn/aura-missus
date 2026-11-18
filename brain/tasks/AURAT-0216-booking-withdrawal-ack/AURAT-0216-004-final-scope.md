# AURAT-0216-004 — Скоуп окончательный: вариант 2+ (правило отмены 24 ч / 50% остаётся)

Дата: 2026-11-17 (`AURAT-0209-011`). Заменяет `002`–`003`. Оба клиента, 24 языка, `@sensitive`.
**Обязательна до live**: без галочки прошедшая сессия уязвима (C-97/22, ст. 14(4)(a)(ii)), если
ст. 16(l) не устоит.

1. **Пустая галочка** перед каждой бронью, сессией «сейчас» и каждым продлением; кнопка неактивна до
   отметки; на сервер — версия текста, время, id брони / продления:
   - бронь: «I want this session at the time I chose. I understand that once it has taken place, I
     can no longer withdraw from it.» + ссылка на Terms §07 (`https://aura-app.cc/terms/#s07`);
   - «сейчас»: «I want this session to start now. I understand that once it has taken place, I can no
     longer withdraw from it.»;
   - продление: «I want these minutes now. I understand that once they have been used, I can no longer
     withdraw from them.»
2. **Строка-информация** (не согласие) об условиях отмены, если на экране брони её ещё нет: «Free
   cancellation up to 24 hours before the start; after that, half the cost is kept. Rescheduling is
   free until 4 hours before.» + ссылка на Terms §06 (`#s06`) — сообщение «права отказа нет» по ст.
   6(1)(k) в момент покупки.
3. **Надписи кнопок с «pay»** — как в `002` п. 2: «Pay {{amount}} & extend», «Pay {{amount}} & start
   now»; проследить цепочку продления в приложении (`features/paid-session`).
