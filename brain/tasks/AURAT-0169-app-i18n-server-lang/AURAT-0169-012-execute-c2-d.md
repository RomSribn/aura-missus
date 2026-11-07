# AURAT-0169-012 — execute: C2 (`Message.marker`) и D (таро)

Дата: 2026-11-06. Решение владельца: баннер Home — имя карты в **две строки** (не уменьшение шрифта).

## C2 — `Message.marker`

`features/chat/lib/map-message.ts`: `MARKER_BY_NAME: Record<MessageMarker, SessionMarkerKind>` (`session_started → started`,
`session_finished → finished`); `markerOf(dto)` решает один раз — известный `marker` важнее текста, неизвестное имя = нет,
точное совпадение строки (`0167`) — запасной путь; тон — из того же вида (`toneOf(marker, content)`); на не-системном
сообщении маркер не читается. JSDoc `features/chat/config/locales/en.ts` обновлён. Тесты: 5 случаев в `map-message.test.ts`.

## D — таро

- **Капс по языку:** `CardReveal` (keywords), `TarotCardFace` (name), `SpreadCardViewer` (keywords) — `upperLabel(text, language)`,
  `textTransform` убран, `accessibilityLabel` — в обычном регистре. Тест: el «Ο Ήλιος» → «Ο ΗΛΙΟΣ», подпись «Ο Ήλιος»
  (`entities/tarot/ui/__tests__/TarotCardFace.test.tsx`); `DailyCardScreen.test` — капс + подпись.
- **Две строки:** `VIEWER_CAPTION_HEIGHT` = gap + 2×38 + 7 + 2×16; `numberOfLines={2}` у имени и keywords в просмотре,
  keywords в `CardReveal`; баннер Home — `numberOfLines={2}` (решение владельца). Цена: на A50 с вырезами iPhone (47/34)
  карта в просмотре теперь упирается в высоту, а не в ширину — тест раскладки «упор в ширину» переведён на A50 без вырезов.
- **Фразы с `{{card}}`** (правило имён `0171`: артикль перед словом в de el es fr ga hu it mt nl pt, приклеен в bg da ro sv,
  нет в cs et fi hr lt lv pl sk sl): `daily-card` `bridge.title` / `draft` переписаны в bg de el es fr ga it mt nl pt ro —
  имя в кавычках после слова «карта» (de «die Karte „{{card}}“», fr «la carte « {{card}} »» с U+00A0, el «η κάρτα
  «{{card}}»», nl ‘…’, ga / mt “…”, ro „…”); `tarot-spread` `open` — de «Karte „{{card}}“ … öffnen», el «της κάρτας «{{card}}»».
  Не менялись: da, sv (ни падежа, ни согласования глагола), hu (уже «ez a kártya: {{card}}»), безартиклевые (уже «karta
  {{card}}»), `youChose` (везде двоеточие или прямое дополнение без падежа). JSDoc в обоих `en.ts`. Тесты-правила:
  `screens/daily-card/config/__tests__/card-name.test.ts`, `features/tarot-spread/config/__tests__/card-name.test.ts`.
  `translate.mjs check`: 0 запрещённых форм. Ревью носителями — желательно (не `@sensitive`).
- **Карта дня:** `shared/lib/i18n/on-language-change.ts` (`onLanguageChange` — только реальная смена `currentLanguage()`, и
  первый язык после старта; псевдоязык = английский). `useDailyCardSync` на смену языка при входе — `load(true)`.
  `daily-card-store`: номер запроса `latest` — ответ устаревшего чтения не ложится. Тесты: гонка, sync-хук, помощник.
  Известное: черновик «I drew …» уйдёт чаттеру с переведённым именем — приемлемо, пока открыто решение 8.
- **Расклады в чате:** `features/chat/lib/replace-spreads.ts` — чистая, меняет только `spread` у держимых id, курсоры не
  трогает, без изменений возвращает тот же массив. `ChatProvider`: `spreadLanguages` (язык первого чтения треда / последнего
  перечитывания), `refreshSpreads(advisorId)` в контексте — другой язык и есть расклады → последняя страница (`limit: 50`, без
  `after`), ответ, обогнанный новой сменой языка, отбрасывается. `use-chat-thread`: зовёт на открытии и на каждую смену
  языка — перечитывается только открытый тред. Карта с сервера и так важнее `spread-store` (`use-spread.ts`). Тесты:
  `replace-spreads.test.ts`, `ChatProvider.spreads.test.tsx` (4), провязка в `ChatThreadScreen.spread.test.tsx`.
  Для `0172`: старые страницы, подгруженные ею, перечитываются только в пределах последней страницы — кто мёржится вторым,
  подключает `replaceSpreads` к перечитыванию загруженных страниц.

## Проверки

tsc — чисто; `npm run lint` — чисто; `npx jest --no-watchman` — 209 наборов, 2882 теста, все зелёные. Prettier: 5 изменённых
файлов были неотформатированы ещё на `develop` — не переформатировал, чтобы не раздувать дифф.

## Осталось (в маноре после мёржа, сборка с `AURA_I18N_ENABLED=true`)

`lang` в логе bff-dev; `DISABLED_LANGUAGES=mt` → `mt` открывается по-английски, Malti нет, сценарий (b); маркеры в истории.
После `0171` на bff-dev: карта дня и расклад на языке, перечитывание при смене языка, длина имён (самые длинные из таблицы
`0171-009`: el «Ακόλουθος των Νομισμάτων», fi «Pentaakkelien kuningatar») в баннере, просмотре, `CardReveal`, el-капс на iOS.
