# AURAT-0216-107 — Приложение: замечания манора к `106` и строка «сейчас»

Дата: 2026-11-18. slave-1, ветка `feature/AURAT-0216-app-withdrawal-ack`.

Манор проверил застейдженный срез `106`: блокеров нет, 9 замечаний. Владелец передал через манор:
- «по строке да» — строка о досрочном завершении для «сейчас»;
- «передавай все замечания и если можно, мерж».

Всё внесено одним заходом. Код закоммичен на ветку. Мёрж делает манор (`wts-finish`) после «да»
владельца.

## Строка «сейчас»

«A started block can’t be refunded. Unused credit always stays on your balance.» Теперь стоит:
- на Review «сейчас», под «The session starts as soon as it's paid.»;
- в быстрой брони «сейчас», на месте строки отмены у слота.

Ключ `paid-session:sheet.note` — те же 24 перевода, что в шторке продления. Нового перевода и копии
текста нет. Ключ берут экраны, не `session-consent`, чтобы между срезами не было скрытой связи.

## Замечания

1. Убраны экспорты без потребителей:
   - `GivenConsent`, `SessionConsentState`, `SessionConsentKind` из `features/session-consent/index.ts`;
   - `ConsentCardTone` из `shared` — тип теперь только внутри `ConsentCard.tsx`.
2. `useSessionConsent(kind)` — без `| null`. Убраны проверки в экранах и тест «no act known yet».
3. Состояние галочки передаётся целиком: `<SessionConsentBox consent={box} disabled={paying} style={…} />`.
   `paying` возвращают `use-book-review`, `use-quick-book` и `use-extend-checkout`.
4. У `SessionConsentBox` нет своего внешнего отступа. Review ставит 10 снизу, шторки — 12 сверху.
5. Состояние называется `box`. На трёх экранах одинаково: `consent: box.consent`, `locked: !box.ticked`.
6. Ссылка §07 перенесена в `LEGAL_URLS.refunds = 'https://aura-app.cc/terms/#s07'` — имя и URL как
   на вебе. В `versions.ts` остались только версии.
7. `live` убран, хук возвращает `ticked`. Сброс в рендере и так не даёт кадра со старой галочкой.
8. Новый `shared/ui/FinePrint` — мелкий шрифт 11.5/17/ink3. Его используют `CancellationTerms`,
   `policyNow` на Review и строка «сейчас». Экраны передают только отступ.
9. `sheet.note` — в экранах (Review, chat-thread), см. выше.

## Тесты и проверки

- `SessionConsentBox`: проп `consent`, новый тест «нажатие переключает».
- `use-session-consent`: без `null`.
- Тесты хуков экранов читают `box`.
- Результаты:
  - `tsc` — чисто;
  - `eslint --max-warnings 0` — чисто;
  - jest — 253 файла, 3373 теста, все зелёные (один тест убран, один добавлен);
  - steiger — нового нет.
- Экранного теста строки «сейчас» нет: у Review нет теста отрисовки. Проверка — в маноре.

## Проверка в маноре (дополнение к чек-листу `106`)

- Review «сейчас» и быстрая бронь «сейчас»: строка о начатом блоке на языке экрана.
- Отступы галочки: на Review — 10 до кнопки, в шторках — 12 сверху.
