# AURAT-0184-010 — fix: ревью кода и переводов координатора

Дата: 2026-11-07 · Ревью: координатор `slave-1-ac`; владелец: «передавай замечания». 17 замечаний (1 major), все
приняты; где был CORRECTED_FIX — взят он. Отброшено ревью: сверка отпечатков при запросе, «later … later», bg
«Експертизата ми». Подробности (англ.): `…/aura-app-manor-project-slave-1/…/scratchpad/wf-code-0184-findings.txt`.

## Переводы
1. **[major] Sunshine, недописанная фраза** — достроена главным предложением («если вы обратитесь… и дадите мне шанс,
   я смогу принести…») в lt / lv / et / fi и de / fr / it / es / pt; fr — U+00A0 перед двоеточием сохранён, pt — без
   «Sinto-o assim:». Отпечатки не меняются (от английского).
2. pt «curadora» (pt-PT — «куратор») → Veronica «consultora e terapeuta»; Marta «na cura de separações» (слоган и био).
3. ro «psihice» → «extrasenzoriale» (May ×2, Alisher; общая фраза одинакова); заметка в шапке `ro.ts`.
4. fr Alisher слоган → «J’ai frôlé la mort à quatre ans – depuis, je vois au-delà du voile».
5. nl Veronica «opgetild» → «opgebeurd».
6. et Marta: «Kas me läheme uuesti kokku?» (био и приветствие), «Kas peaksin sellesse suhtesse jääma?».
7. et Sunshine «tasunud» → «tasustanud».
8. sl Ivan «so se obrnila stotine» → «so se obrnile stotine».
9. fr / it / es / pt Sunshine «si / così / tan / tão simples» → «très / molto / muy / muito».
10. de Veronica «Ich bin direkt mit dir» → «Ich sage dir alles geradeheraus»; de Olivia слоган → «30 Jahre Deutungen, aus
    einer langen Ahnenreihe von Hellsehern und Medien» (самый длинный слоган de — таблица в `009` обновлена, 6 строк в
    117px); nl Olivia «uit een lange lijn» → «uit een lang geslacht» (слоган и био).
11. cs / sk May: «která se skládají z mocných energetických paprsků přenášených…» / «ktoré sa skladajú z mocných
    energetických lúčov prenášaných…».

## Тест текстов
12. Обращение: it — `formalCased('Lei', 'Suo', 'Sua', 'Suoi', 'Sue')`; hu — `ön / önnek / önök / önnel / öné` без
    регистра + `formalCased('Önt')` («önt» — «льёт»); множественное обращение — своя проверка «plural address — the app
    speaks to one person» (de Euch / Euer / Eure, es ustedes / vosotros / vuestro / vuestra, ga sibh / bhur, it voi /
    vostro…, mt intom / tagħkom / lilkom); pl окончания `łeś, łaś, łbyś, łabyś, ieneś, nnaś`, причина — «past or
    conditional form».
13. Шапка fixtures: hr / sl «ti», pl «ci», it «Lei» / «Sua» многозначны — такое предложение идёт в `ALLOWED`.
14. sl avoid `bralc` (local, мужские косвенные); шапка `glossary-avoid.spec-fixtures.ts`; пример в `it.each`; в
    передачу глоссария v4.
15. Кавычки — по порядку: счётчик глубины слева направо по закрывающему знаку (не ниже 0, в конце 0); fi / sv ”…” —
    чётность; nl — оба открывающих к ”.

Проверено порчей: перевёрнутые кавычки da, it «Suo», hu «önnek», pl «Mogłabyś», sl «bralca» — все пойманы.

## Документы
16. `009`: раздел de / nl / ro / mt / ga (ручная проверка (a) / (b) / (c), сомнения: mt «qari» / «kuxjenza», ga
    «tionscanta» / «siúl amach» и др.); hu достроен сразу — исправлено; таблица ширин обновлена.
17. `009`: раздел «Ревью `010`: сомнения, которые оставляем»; передача приложению — текст замены комментария
    `use-advisor-profile.ts:42`.

## Проверки
typecheck ✓ · lint ✓ · build ✓ · `npm test` — 154 набора, 2067 тестов, все зелёные. Всё застейджено, не закоммичено.
