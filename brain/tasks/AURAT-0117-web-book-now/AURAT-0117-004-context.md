# AURAT-0117-004 — Context

Date: 2026-10-21

## Контракты (`@aura/contracts`, веб уже на `v0.23.0`; `startNow` — с `v0.6.0`)

- `AvailabilityResponse.instantAvailable: boolean` — один на ответ, рядом с `days`; «сессия на
  `minutes` запроса может начаться сейчас». Веб всегда шлёт `minutes` выбранного блока и при смене
  блока читает заново (`useAvailability` берёт `currentData` — чужой блок не подсовывается).
- `BookSessionRequest`: ровно одно из `startsAt` / `startNow: true` (иначе 400); ключ — в теле;
  повтор ключа — исходная сессия, тело не сравнивается (`AURAF-0020-024`).
- Ответ — `{ session, balanceMinor }`; для `startNow` сессия сразу `ACTIVE`, `startedAt` = `startsAt`
  = часы сервера, `endsAt` = + minutes.

## BFF (без правок)

- `instantAvailable` = окно `[now, now+minutes)` не пересекает живые (`SCHEDULED`/`ACTIVE`) сессии
  советника и свои живые сессии человека; lead на него не действует; присутствие (online) не
  проверяется. Гость — без своих сессий.
- Бронь `startNow`: сессия создаётся идущей, задача завершения, «started» в треде, `session.updated`
  по сокету. Отказы общие: 409 (слот занят / вы заняты), 402, 400, 404 — особых кодов нет.

## Приложение

- «Now» есть только в Quick book чата (`use-quick-booking.ts`: `instant = instantAvailable === true`,
  `startsAt: null`; `use-booking-confirm.ts`: тело `{ startNow: true }`, ключ — как у слота).
  Успех моментальной — без экрана Booked: шторка закрывается, человек в треде с баннером.
  На экране с сеткой (`BookSessionScreen`) «Now» нет — это `AURAT-0116` (не начата).
- Копия приложения (англ., без i18n): CTA «Start now · {cost}», «Starts immediately».
  Хендофф `CHECKOUT.md`: «Start now · $X» / «Pay … & start now».

## Веб (ground truth, develop `d70639f`)

- `features/book-session/model/use-book-session.ts` — выбор (блок, день, время), черновик
  (`sessionStorage`, `{advisorId, minutes, startsAt}`), `initialChoice` (ссылка → черновик → из чата
  ближайший). `instantAvailable` не читается нигде.
- `entities/session/ui/session-time-picker.tsx` — дни + сетка; общий с Reschedule.
- `features/pay` — `PayAttempt.startsAt: string` обязателен; `BookSessionArgs.startsAt` с комментарием
  «веб не стартует сейчас (`AURAT-0107-005` §7)»; `pending.ts` (карта) — `startsAt` обязателен.
  Ключ попытки — до определённого исхода, не сбрасывается при смене выбора.
- После брони: `widgets/book-sheet` и `/checkout` → `/booked/:id` всегда («Go to session»,
  «Add to calendar», строка про отмену за 24 ч) — для идущей сессии не годится.
- `AURAT-0107-005` §7: «Now» отложен, потому что в треде веба не было баннера / таймера / Extend.
  Это даёт **`AURAT-0114`** (slave-4, на ревью владельца, не в develop): баннер с отсчётом по
  `serverNow`, Extend, End early, список сессий как источник. Он же правит
  `features/book-session/ui/booking-form.tsx` (`DurationOption` → `shared/ui/ChoiceCard`) —
  будущий конфликт слияния.

## Противоречий нет

Бриф владельца совпадает с заглушкой `001` и с кодом BFF.
