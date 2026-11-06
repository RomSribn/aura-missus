# AURAT-0163-008 — review fixes

Дата: 2026-11-06. Ревью координатора (slave-1-9e: 3 ревьюера + скептики; логика верна, блокеров нет). Владелец:
«передай». Разбор: scratchpad координатора `wf0163-review.md`.

## Переводы
1. **el — подписи полей капсом** (`FormField` рисует `uppercase`): ΟΝΟΜΑ, EMAIL — ΠΡΟΑΙΡΕΤΙΚΟ, ΗΜΕΡΟΜΗΝΙΑ ΓΕΝΝΗΣΗΣ,
   ΤΗΛΕΦΩΝΟ (Email — как было). В JSDoc en.ts пяти подписей — «Drawn in capitals — write Greek in capitals already».
2. **pt — без мужского рода:** create-account body «…vão dirigir-se a si pelo nome…», account-deletion keptBody
   «…sem dados que permitam a sua identificação.» (keptBody остаётся к носителю).
3. fr заголовок удаления — U+00A0 перед «?»; в `translations.test.ts` — проверка fr на обычный пробел перед
   `? ! : ; »` и после `«` (во всём приложении нашёлся только этот).
4. Подсказка имени: fr «Comment doit-on vous appeler ?», ga «Cad a thabharfaimid ort?»; бюджет ~283 pt в JSDoc,
   `@max 34` (замер: все 24 влезают, самая длинная pl — 244 pt).
5. «Keep it» — форма кнопки: hu «Megtartás», el «Διατήρηση».
6. bg editLabel «Редактирай профила» — видимое «Редактирай» входит в a11y-имя (WCAG 2.5.3). Заголовок оставлен
   «Редакция на профила».
7. Top Up: `paddingHorizontal` 26 → 22, `flexShrink: 1`, `marginLeft: 12` — nl «Opwaarderen» (100 pt) влезает рядом
   с «US$ 1.234,56» (≈106 pt места); ga «Cuir airgead leis» (118) в худшем случае переносится, а не вылезает.
   Бюджет в JSDoc en.ts.
8. Расхождения веба (pt ×2, fr, keep hu/el, el подписи) — в `AURAF-0023-glossary.md`.

## Отступление от спеки
«That didn't save. Please try again.» осталось в namespace экранов (`create-account:failed`, `edit-profile:failed`),
а не в `profile-form`: строку рисует подвал экрана, не `ProfileFields`, а чужой namespace слайс не читает
(004 «Наблюдения»). Цена — одна фраза в двух namespace.

## Тесты
- T1: `use-account-deletion.test` под настоящим `ToastProvider`: тост ровно один и только после того, как
  `onDeleted` закончился; нет тоста при live-sessions, сбое и 401 при живой identity.
- T2: `ProfileDeleteAccount` на de (строка, a11y подтверждения, «Dein Konto wurde gelöscht.», нет английского), нет
  тоста при отказе; помощники принимают подпись. `AccountDeletedBootstrap` — язык сменён после подписки → тост на de.
  Найдено попутно: деревья прошлых тестов не размонтировались, их подписка выходила первой и показывала тост в своём
  провайдере — теперь `afterEach` размонтирует.
- T3: заголовок Edit profile — текстовый узел «Edytuj profil», а не a11y ссылки с карточки.
- T4: «Profil» — точный узел и `not.toContain('Profile')`.
- T5: fr — строка в профиле «Supprimer le compte», в листе «Supprimer», заголовок с U+00A0.
- T6: create с `phone` — ни «Telefon», ни номера; edit — без подсказки имени; текст согласия — в общих словах.
- T8: `PhotoSourceSheet.test.tsx` на de: заголовок, строки, подсказки, a11y; без фото — без «Foto entfernen».
- T9: «Sign out failed» на de — заголовок, причина из `shared`, OK.
- T7 (сумма через `formatUsdMinor` на экране) — не сделан: по желанию, лист получает уже отформатированную строку,
  форматтер покрыт в `shared` (`AURAT-0159`).

## Проверки
`tsc` — 0, `eslint .` — 0, Jest — 189 наборов / 2241 тест.

## Вне задачи — отдельной задачей (номер — у координатора)
`shared/config/locales/en.ts:42-45` (`inDays`) говорит переводчику «drawn in capitals by the app (no need to write
them so)» — это противоречит build rules: el «ημέρες» рисуется «ΗΜΈΡΕΣ» с тоном. Проверить все строки под
`textTransform: 'uppercase'` в `shared` и el в них.
