# AURAT-0137-004 — Context

Date: 2026-10-23

## Источники

| Источник | Что взято |
|---|---|
| `@aura/contracts` v0.24.0 `src/tarot.ts` | `TarotCard {id, name, keywords, daily, imageUrl}`, `DailyCardQuery {tz?}`, `DailyCardResponse {card, localDate, drawn}`, `MarkDailyCardDrawnRequest {tz?}` |
| aura-bff `modules/tarot/tarot.controller.ts` | `GET /v1/tarot/daily` (200), `POST /v1/tarot/daily/drawn` (204, идемпотентно); оба за Firebase-токеном; неизвестная/пустая зона → UTC, не 400 |
| aura-app `entities/tarot` | Стор: читает один раз (повтор — no-op), `markDrawn` — сначала локально, запись следом, ошибка записи молча; сброс при смене uid; `tz` — зона устройства, даты клиент не шлёт |
| aura-app `screens/daily-card` | Таймлайн `stack 0 → fan 420 → shuffle 1000 → gather 1560 → pick 1960 → flip 2360 → done 2820`; 660 мс на ход, 28 мс задержка на карту, переворот 620 мс; сцена 262 → 300, перспектива 1000, опора веера `50% 116%`; «дыхание» колоды 3 с; герой 176×270 `pop-in` 500 мс; float-in .1/.18/.26/.3 с; повторный вход — сразу раскрытие; reduce motion — сразу карта; ошибка — «Your card didn’t arrive.» + Try again, без запасной колоды |
| aura-app `screens/daily-card/config/copy.ts` | Тексты экрана (eyebrow, три фразы фаз, мост, «Ask an advisor», «Chat is free to start», черновик «I drew {card} today. What could it mean for me?», ожидание, ошибка) |
| aura-app `screens/daily-card/lib/tarot-advisor.ts` | Кому «Ask an advisor»: таро онлайн → таро → любой онлайн → первый в каталоге |
| aura-app Home `DailyCardBanner` | Eyebrow «Daily ritual», «Draw your card» / «One free pull every day»; вытянута — имя карты / «Drawn today · tap to revisit» |
| Мобильный хендофф `DAILY_CARD_TAROT.md` §1–4, §9 | Ритуал, раскрытие, «гайд никогда не закрыт оплатой»; в §4 — sys-строка и реплики советника в треде (приложение заменило черновиком, `AURAT-0048`) |
| Веб-хендофф README §2, NAVIGATION §2.1 | Home: «slim Daily Card banner» между героем и советниками; «Daily Card banner · Draw today’s card — (app feature, v2 on web) → Daily Card ritual». `web-kit.jsx DailyBanner`: веер из 3 рубашек, «Draw your card of the day», «One free pull every day», «Free», коралловая «Draw today’s card». Страницы ритуала в веб-хендоффе нет; `web-chats.jsx` — `SysLine «Started from your Daily Card · The Sun»` |
| aura-web develop `280988a` | `features/tarot-pick` — рубашка/лицо карты своей разметкой (`.back` / `.face` в CSS пикера), токены `--plum`, `--plum-2`, `--gold`, `--shadow-tarot`, `--on-plum-2/3`, `--ease-settle`, `--ease-flip`; `entities/tarot` нет; `AuthReason = 'ask' \| 'book' \| null`; `PrivateRoute` + `GuestGate` по `handle.gate`; composer — локальный `useState('')`, черновика снаружи нет; присутствие — `chat-live.presence` |

## Находки

1. **Тексты карты — только английские** (контракт: `name` — «English name»). Пикер в чате
   (`AURAT-0105`) показывает их как есть. Перевод колоды (78 × 3 поля × 23 языка) — задача
   contracts + BFF, не веба.
2. **Страницы ритуала в веб-хендоффе нет** — только баннер. Вид страницы берём с приложения
   (экраны 30–31 мобильного хендоффа), раскладку desktop решаем сами.
3. **Гость.** Оба роута требуют вход. В вебе есть два готовых механизма: `PrivateRoute` +
   GuestGate (страница) и `gate(reason)` (кнопка).
4. **Передача в чат.** Писать в историю клиент не может (как в приложении); веб-хендофф
   рисует sys-строку — её нет и в приложении. Черновик в composer в вебе сейчас не
   поддержан — нужен вход в `features/send-message`.
5. **Повтор визуала.** Рубашка и лицо карты понадобятся второй раз → по правилу 3 их надо
   вынести в общий компонент до второй копии (`entities/tarot/ui`), пикер переходит на них.
6. **Контраст.** Строка даты в приложении — 40% белого на плюме; по `AURAT-0123` такие
   значения пойдут через токены. Берём только токены темы.
7. **Совместимость с параллельными задачами.** Общие файлы: `app/router/router.tsx`,
   `app/config/i18n.ts`, `vitest.setup.ts`, `shared/config/routes.ts`, `tokens.css`,
   `shared/model/dialog.ts` (`AuthReason`). Конфликты — манор при мёрже.

Противоречий между источниками, кроме §4 хендоффа (sys-строка) и отсутствия веб-страницы, нет.
