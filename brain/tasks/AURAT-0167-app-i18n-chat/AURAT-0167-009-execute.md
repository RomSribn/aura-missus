# AURAT-0167-009 — execute: правки по ревью кода (`008`)

Дата: 2026-11-06. slave-0, всё в stage, не закоммичено. Итог: `tsc` 0, `eslint .` 0, Jest 196 наборов / 2761
тест, `translate.mjs check` — 0 запретных форм. Дифф к `develop`: без постороннего форматирования (п. 18).

## По пунктам
1. **Статус картинки по высоте.** `STATUS_COMPACT_BELOW = 110` (`config/attachments.ts`): ниже — значок 28, gap 6,
   без строки имени файла (имя — в доступной подписи), повтор одной строкой с `adjustsFontSizeToFit`
   (`minimumFontScale` 0.8). Высоты при 360 pt: битая / удалённая ≈ 74 pt, ошибка ≈ 73 pt — в плитки 81–100 pt
   входят. Полный вариант (одиночная картинка) — ≈ 109 pt. JSDoc `image` — ширина и высота.
2. **Аватар в строке списка** скрыт от чтеца (`accessibilityElementsHidden` + `no-hide-descendants`); тест — первым
   читается имя, затем превью.
3. **Неотправленное.** Слова Photo / Video / Voice message переехали в `chat:attachment.*` (переводы перенесены из
   `chats`, ключи там удалены); `features/chat` — `attachmentWordOf` / `nameOfAttachment` (документ — имя файла,
   остальное — слово). Подпись: `delivery.failedLabel` с текстом / именем / словом, иначе `delivery.failedBare`.
   `failedBare` в каждом языке — первые слова видимого `delivery.failed`, `failedLabel` собран из него (sv — «Ej
   levererat», fr — U+00A0 перед двоеточием). Тест на все 24 языка: оба начинаются с видимого.
4. **iOS:** `AccessibilityInfo.announceForAccessibilityWithOptions(…, { queue: true })` один раз на отказ (по
   `error`, не по смене языка); Android — live region. Тест с шпионом.
5. **Имя карты** в разделителе — `upperLabel(name, language)`; тест el «ΕΠΙΛΕΞΑΤΕ: Ο ΕΡΗΜΙΤΗΣ».
6. **Подпись ошибки картинки** — `${image.failed} · ${file}` из видимого заголовка; ключ `image.failedLabel` удалён;
   тест на все 24 языка. У битой / удалённой — та же схема (бокс `accessible`).
7. **Строка файла** — без подмены подписи (читаются имя и мета), при ошибке — подсказка `retryHint` (общий ключ
   `chat-thread:retryHint`, бывший `image.retryHint`). Готовая картинка — подпись словом («Photo»).
8. **Шапка:** статус в одну строку; у имени `minWidth: 80`, кнопка `flexShrink: 1` (длинная — в две строки).
9. cs / sk `refused.desk` — «Zprávu nebylo možné poradci doručit» / «Správu nebolo možné doručiť poradcovi».
10. «No longer available» — полная форма веба (`message:attachment.gone`) в 15 языках для `image.gone` и (кроме el)
    `voice.gone`; `@max voice.gone` 22 → 28 (ga 27 знаков; замер — все ≤ 125 pt).
11. **Тесты:** заголовок списка на fi / pl, пустой экран и превью приглашения на de — положительные проверки;
    плюралы lt 1 / 3 / 10 / 21 («Session live», тост продления), pl 3 «Dodano 3 minuty»; подписи неотправленного
    (текст, фото, документ, пусто); компактный бокс; объявление на iOS.
12. Дыра линтера — в строке 4 `AURAF-0023` («линт везде — `List*Component` в `jsx-attributes.include`, `.ts`,
    `src/app/**`»).
13. `dismissHint` — «уведомление» (pl komunikat, nl melding, hu értesítés, bg известие, cs upozornění, sk
    upozornenie, hr obavijest, sl obvestilo, el ειδοποίηση, ro notificare, it / es / pt avviso / aviso, fr
    notification, mt avviż, ga fógra, lv paziņojums, da meddelelsen, sv notisen); JSDoc — уведомление над полем.
14. sk `invite.cta` — «Rezervovať súkromné sedenie».
15. `tarot-spread:youChose` fr / sk / sl — с веба («Vous avez choisi {{card}}», «Vybrali ste si: {{card}}», «Izbrali
    ste: {{card}}» — вежливое мн. ч., рода нет).
16. JSDoc `invite.cta` — ~200 pt, длинная переносится.
17. «online» — в ряду с именем: имя сжимается (`flexShrink: 1`, «…»), статус — нет.
18. Откат постороннего форматирования: 15 файлов целиком к `dc98590` (ChatProvider, fan-layout, viewer-layout,
    TypingIndicator, MessageRow, RevealCard, SpreadStage, AttachmentBlock, use-spread, 6 тестов), в остальных —
    42 хунка только с переносами; `MessageBubble.tsx` пересобран от оригинала (дифф 239 → 43 строки).
    Перестроенные тела `AttachmentSourceSheet` / `SessionInviteCard` — по делу (стрелка → тело с `useTranslation`).

## Проверка в маноре после мёржа
- Группы из 3 и 4 картинок с ошибкой / удалённой — en / pt / nl / el (п. 1).
- Шапка треда в живой сессии — el / ro (п. 8); строка списка с длинным именем и «online».
