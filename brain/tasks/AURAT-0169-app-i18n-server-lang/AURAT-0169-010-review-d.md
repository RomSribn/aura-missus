# AURAT-0169-010 — дополнения к этапу D (от координатора `slave-1-9e`, 2026-11-06)

Пришли тремя сообщениями после одобрения v2; владелец там сказал «передавай во все нужные слейвы».

1. **Тег `v0.28.0` есть** (main `7055dc9`, `SOURCE_LANGUAGE = 'en' satisfies Language`) — сделано в `009`.
2. **Ключевые слова — в две строки.** `0171` ограничивает `keywords` 48 знаками; стиль `keys` (HankenGrotesk-Bold 12,5 pt,
   letterSpacing 1,63, капс) на экране 360 pt (~304 pt строка): en максимум 305 pt — на границе, de / fr / fi — 388–396 pt.
   `VIEWER_CAPTION_HEIGHT` (`features/tarot-spread/config/spread.ts:124`) закладывает одну строку (16 pt). → `+16`,
   `numberOfLines={2}` в `SpreadCardViewer` и на экране карты дня (`CardReveal`).
3. **Имена не помещаются.** Колода `0171` переведена; таблица длин — `aura-bff-manor` slave-2 missus
   `brain/tasks/AURAT-0171-bff-tarot-deck-i18n/AURAT-0171-009-execute-deck.md`, раздел «Длины» (не закоммичен).
   `name` до 24 знаков (el «Ακόλουθος των Νομισμάτων», fi «Pentaakkelien kuningatar»; en — 19); `keywords` до 47 (pl);
   `daily` до 179 (ga). Артикль: перед словом — de el es fr ga hu it mt nl; приклеен — bg da ro sv; нет — cs et fi hr lt
   lv pl sk sl; регистр обычный.
   - Просмотр карты (34 pt, бюджет — одна строка 38 pt): даже en «Knight of Pentacles» 321 pt > ~304 → `+38`,
     `numberOfLines={2}` для имени.
   - Баннер Home (22 pt, `numberOfLines={1}`, бюджет ~210 pt — оценка, сверить): en 205 впритык; el 301, fi 270, de/nl/mt
     245… — многоточие. Выбор: **две строки** или **`adjustsFontSizeToFit` + `minimumFontScale`** — решение владельца.
   - Проверка в маноре — по строкам таблицы.

Всё это — этап D (после мёржа `0167`), плюс уже записанное в `007` §D (фразы с `{{card}}` — правило формы имени теперь
известно, капс через `upperLabel`, гонка `load`, `replaceSpreads`).
