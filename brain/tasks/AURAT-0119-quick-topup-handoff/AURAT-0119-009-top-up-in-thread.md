# AURAT-0119-009 — Top Up в самом треде

Date: 2026-10-22

## Обратная связь владельца

На устройстве (Android) после `008`: переход Quick book → Top Up «такой же, как был», плавно
только из Review.

Владелец также спросил про «новую кнопку» и про оплату картой в Quick book. Это AURAT-0099
(плитки Balance / Google Play, «Top up to book»). На прошлой сборке плитка Google Play не
показывалась, после перезапуска появилась: Billing подключается, в логах Finsky есть
`Billing preferred account … cc.silvermind.aura`. Причина не установлена; ветка не отстаёт от
`origin/develop` (`caf8736`).

## Почему `007` не помог

Из Review уход в Profile прячется за анимацией pop стека Booking (JS stack, slide). Из треда
это переключение вкладки Chats → Profile, а у bottom tabs анимации нет: жёсткая смена кадра.
Убранное в `007` ожидание 200 мс этого не меняло.

## Решение (владелец, AskUserQuestion): Top Up прямо в чате

Варианты: Top Up в чате (выбран) / fade при смене вкладки / оставить как есть.

- `TopUpSheet` перенесён из `screens/profile/ui` в `features/store-topup/ui`. Логика тиров,
  Pay (store / stub), pending / failed и `trackTopUpOpened` перенесена из `use-profile` в
  `features/store-topup/model/use-top-up-sheet.ts` (`useTopUpSheet(visible, close)`). Profile
  использует его же, поведение не изменилось.
- Тред держит свой `TopUpSheet`. `useChatThread`: `openTopUp` передаётся в `usePaidSession`
  (Extend) и третьим аргументом в `useQuickBook`. Навигации в Profile из треда больше нет.
- Передача между шторками: на Android Top Up выезжает, пока уезжает Quick book / Extend. На iOS
  Top Up ждёт `onClosed` (AURAT-0020), как и раньше. Комментарий
  `SHEET_HANDOFF_WAITS_FOR_CLOSE` переписан.
- Review → Profile → Top Up не менялся: там переход плавный.

Поведение после покупки как в Profile: на store rail шторка остаётся открытой, баланс
обновляется; закрывает пользователь. Автовозврат в Quick book в задачу не входит.

## Тесты

- `use-quick-book.test.tsx` — iOS ждёт `closed`, Android открывает сразу и один раз; навигации
  нет.
- `ChatThreadScreen.session.test.tsx` — новый тест: при пустом кошельке Extend → «Top up your
  balance» показывает «Top up balance» в самом треде.
- tsc и eslint чистые; jest: 129 suites, 954 tests пройдены.

Дальше: APK из слота на устройство и проверка владельцем.
