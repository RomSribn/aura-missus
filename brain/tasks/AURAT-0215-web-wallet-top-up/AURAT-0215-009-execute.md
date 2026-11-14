# AURAT-0215-009 — Execute: правки после ревью

Date: 2026-11-14. Slave `slave-1`, ветка `feature/AURAT-0215-web-wallet-top-up`. Не закоммичено — всё
застейджено в master и missus, на ревью владельцу.

Находки трёх раундов и что с ними сделано — в `008-fix-review.md`. Здесь — итог по файлам.

## Код
- `features/pay/model/use-card-top-up.ts` — при открытии шторка доводит свою оставшуюся запись
  (`resumes`) через `/checkout?…&cancelled=1` до любой новой сессии Stripe;
  `model/pending-store.ts` — `keptPayment()`.
- `features/pay/lib/pending.ts` — запись `extend` получила `sessionId`.
- `features/pay/lib/return-path.ts` (+ тест) — `from` пополнения никогда не `/checkout`.
- `features/pay/ui/top-up-sheet.module.css` — суммы 2 × 2 на ≤ 760 px.
- `features/extend-session/model/use-extend-session.ts`:
  - экран конца сессии считается, а не хранится: деньги карты на балансе, или «processing»;
  - после потерянного ответа и конца сессии сессия перечитывается один раз; если и это не
    удалось — шторка закрывается;
  - если продление прошло, `creditedMinor` сбрасывается;
  - новое поле `overCardMax`.
- `features/extend-session/ui/session-block-sheet.tsx` — строка `tooMuch` при включённой карте и
  экран `overProcessing`.
- `app/layouts/app-layout/*` — класс `withTopUp` (оплата включена и вход выполнен): на 761–1180 px
  ссылки шапки — иконки. Телефон не затронут. `entities/wallet/ui/balance-chip.tsx` — без
  `data-top-up`.

## Строки (24 языка)
- `extend-session`: `tooMuch` («…Pick a shorter block, or top up your balance first.»),
  `overProcessing`.
- `pay`: de / fr `topUp.planExact` — нейтрально, без слова «сессия».
- ga: чип — «Cuir leis», кнопка в профиле — «Cuir airgead leis».

## Тесты
- `top-up.test.tsx` — 30 тестов. Добавлены:
  - processing в шторке пополнения;
  - Back посреди оплаты в обеих шторках: ждут дольше паузы 300 мс;
  - шаг карты в Extend;
  - конец сессии при processing;
  - потерянный ответ, конец сессии — по трём исходам чтения: не прошло, прошло, не прочиталось.
- Исправлена гонка в проверке шапки: `waitFor` по самой шапке. «Старая сессия закрыта» проверяет id.
- Мутационные проверки: защита `kept`, `!unsettledAfterCredit`, `setCreditedMinor(null)` и
  ожидание чтения — каждую ловит хотя бы один тест.

## Проверки
- `typecheck` чисто; `lint` (eslint + steiger) чисто; `prettier --check` по изменённым — чисто.
- `test` — 119 файлов, 2007 тестов, все зелёные.
- `build` — ок. `card-elements` 17,5 kB отдельно; основной чанк 955,5 kB, на develop 943,3 kB.

## Закрыто из `007` «Открыто»
Запись пополнения после свежей загрузки (Back из банка без bfcache) теперь доводится: шторка
делает это при следующем открытии.

## Открыто / владельцу
- Default card / Apple Pay при выключенной оплате — **решено владельцем 2026-11-14: «Убрать везде
  (Recommended)»**. Строки убраны во всех сборках, как сейчас в коде. Пункт 4 спеки `005` действует
  и без флага.
- Компромисс шапки: при включённой оплате у вошедшего подписи вкладок — иконки на 901–1180 px (в проде
  без флага не меняется ничего); если биллинг выключен (404), подписи там тоже скрыты.
- Back закрывает любой диалог, даже во время оплаты; запись доводится при следующем открытии. Так же
  ведёт себя Book. Держать диалог открытым при Back — отдельная задача для `dialog-host`, если
  понадобится.
