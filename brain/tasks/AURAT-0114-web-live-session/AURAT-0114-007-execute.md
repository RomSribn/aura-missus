# AURAT-0114-007 — Execute

Date: 2026-10-21

Ветка `feature/AURAT-0114-web-live-session` перемотана на `develop` `d70639f` (влиты `AURAT-0108`,
`AURAT-0112`) до начала работы — кода в ветке ещё не было. Сделано по спеке 005 (решения 1–9 по
рекомендациям, правки ревью 006).

## Файлы

**entities/session**
- `config/sessions.ts` — `EXTEND_PROMPT_SECONDS`, `COUNTDOWN_TICK_MS`, `STARTING_SOON_HOURS`,
  `SESSION_LIST_TICK_MS`.
- `lib/countdown.ts` (+ тест) — перенос `formatCountdown` копией.
- `lib/live-session.ts` (+ тест) — `liveSessionFor` (live / soon ≤ 24 ч / null), `elapsedShare`
  (доля прошедшего, тесты процентов баннера приложения), `liveMinutesByAdvisor`.
- `model/use-live-session.ts` — `useLiveSession` (тик 1 с при live/soon, иначе 60 с),
  `useLiveMinutes` (30 с), `useListedSession`, `useRereadSessions` (принудительная перечитка списка).
- `ui/session-banner.tsx` + css — live (plum, gold, точка-пульс, счётчик `role="timer"`, полоса,
  коралл в последние 120 с, скрытые polite-объявления «N minutes booked in total» и «Less than 2
  minutes left») и soon («Session scheduled», «Until start», «Starting…»); вся карточка — `<Link>` на
  `/sessions?id=`.
- `config/locales/*` — блок `banner`.

**entities/wallet** — `model/wallet-cache.ts`: `walletBalanceUpdated` (баланс из ответа продления в
кэш `getWallet`).

**features/extend-session** (dialog `extend`) — `api/extend-api.ts`; `lib/blocks.ts` (+ тест; перенос
с поправкой цены: `minutes × session.priceMinorPerMinute`); `lib/attempt.ts` (+ тест);
`model/attempt-store.ts` (попытка в `sessionStorage`, переживает шторку и перезагрузку);
`model/use-extend-session.ts`; `model/extend-sheet.ts`; `ui/extend-sheet.tsx`; 24 языка.

**features/finish-session** (dialog `finish`) — api, model, `FinishSheet`, 24 языка.

**shared** — `ui/choice-card` (`ChoiceCard`, `ChoiceCards`): карточка выбора, вынесенная из Book
(правило 3 — второй копии не делаем); `model/dialog.ts` — виды `extend`, `finish`;
`config/tokens.css` — `--on-plum-3`, `--on-plum-tile`, `--on-plum-track`, `--dur-live-dot`,
keyframes `live-dot`.

**features/book-session** — `DurationOption` на `ChoiceCard`, стили карточки убраны из своего css.

**widgets/chat-thread** — баннер между шапкой и лентой; календарь ↔ «Extend +N min» (soft,
cross-fade `--dur-fast`); статус «Online · paid session» / «Paid session».
**widgets/conversation-list** — пилюля «Session live · N min left», живые сверху (и на главной —
тот же виджет).

**app** — `dialog-host/extend-dialog.tsx` (Extend → «End session early» открывает `finish`),
`config/dialogs.ts`, `config/i18n.ts`, `vitest.setup.ts`.

**Тесты** — `app/__tests__/live-session.test.tsx`, 14 сценариев: баннер, шапка, статус, пилюля и
порядок, один запрос списка; отсчёт по часам сервера; последние 2 мин и снятие в 0 без запроса;
цена по сессии и ответ в кэш; потеря ответа — блоки заблокированы, повтор тем же ключом и
минутами; «Choose another block» — перечитка, `endsAt` сдвинулся → «10 minutes were added»;
попытка переживает закрытие, `endsAt` не сдвинулся → новый ключ; 402; 409 при идущей / кончившейся
сессии; 404; End early; soon ≤ 24 ч; > 24 ч — ничего.

## Проверки

`npm run lint` (eslint + steiger) — чисто; `npm run typecheck` — чисто; `npm test` — 74 файла,
1294 теста, все зелёные; `npm run build` — собран (предупреждение о чанке > 500 kB — как было).
Живой BFF — в маноре после merge.

## Решения по ходу

- `smallestBlockMinutes` не переносил: в вебе уже есть `shortestBlockMinutes` (`entities/session`,
  `useSessionPricing().shortestMinutes`).
- Блоки — кнопки с `aria-pressed` / `aria-disabled` (как длительности в Book), а не radiogroup;
  причина недоступности — в `aria-label`.
- Прогресс-функция живёт в `live-session.ts`, отдельного `progress.ts` нет.
- Строка «Top up in the Aura app — it’s the same balance here.» показывается всегда под балансом;
  нехватка — отдельной строкой «Your balance is $X short for N min.» для наименьшего непокрытого
  блока.
- «Added N minutes» после успеха: шторка закрывается, а «N minutes booked in total» объявляется
  из баннера (polite); видимая плашка «N minutes were added» — когда потерянная попытка оказалась
  успешной.
- Переводы делали 4 агента по языкам; общие фразы скопированы из существующих файлов языка,
  строка пополнения везде называет баланс существительным; fi «Jatka» → «Pidennä».

## Открыто

- Строку `AURAF-0020-029` (UI ✓) и бэклог 042 «PSP при продлении» пишу при закрытии, после
  слияния `origin/master` в missus (там `AURAF-0020` новее локального).
- teal на teal-soft в пилюле ниже 4.5:1 — так же, как в существующих местах (Cancel «Full refund»).
- Узкое окно второго списания при «Choose another block» (ревью владельца 2026-10-21, принято для
  v1): после обрыва связи веб сразу перечитывает сессию; если сервер в этот момент ещё не
  закоммитил продление, `endsAt` не сдвинут, попытка снимается, и следующая уходит с новым ключом —
  два продления, два списания (время человек получает за оба, деньги не пропадают, но второе
  списание неожиданно). Возможное усиление: если перечитка в первые 10–15 с после обрыва и `endsAt`
  не сдвинулся — перечитать ещё раз через паузу и только потом снимать попытку.
