# AURAT-0150-007 — сдача Claude Design: приёмка и перенос в хендофф

Дата: 2026-10-31
Сдача: владелец положил в `/Volumes/Work/personal/aura_seasonal/` (40 файлов, 7,2 МБ):
`SEASONAL.md`, `README.md`, `presets/` (2 JSON + hero/ticket WebP и PNG), `effects/` (8 SVG),
`screens/67…81`, `code/` (веб-референс: `seasonal.jsx`, `seasonal.css`, `season-shapes.js`,
`season-presets.js`, новый `offer.jsx`).

## Приёмка по части 2 брифа

| Пункт | Итог |
|---|---|
| Все 17 токенов в обоих `presets/*.json`, без лишних | ✓ |
| Пары P1–P18, пересчитаны независимо | ✓ все проходят. Минимумы: winter — P17 5,97; valentine — P7 4,23 (порог 3), P4 7,24, P17 5,48. Совпадает с таблицами `SEASONAL.md` §9 до сотых |
| Картинки: размер, альфа, вес | ✓ hero 720×720 (WebP 132 / 88 КБ ≤ 150), ticket 192×192 (WebP 4 / 3 КБ ≤ 30), альфа есть, текста нет |
| Частицы: 1 залитый path, viewBox 24, без stroke и градиентов | ✓ все 8 |
| Экран «без картинки», Reduce Motion, самый длинный текст на 316 | ✓ `70`, `72`, `71` |
| Лимиты символов записаны | ✓ hero: title 26, body 50, cta 16; билет: eyebrow 22, title 22, sub 36 |
| Правило одного билета (`006` п. 1) | ✓ §2, экраны `73–75`, `80` |
| Частицы только в hero, ≤ 12 с, без цикла (`006` п. 2) | ✓ §6: 14 шт., 4,6–6,8 с, за текстом, над колонкой текста × 0,45 |
| Орб | ✓ та же формула, что в `Orb.tsx` (white → soft 55 % → base) |
| Веб: экраны hero 1440 и 390 | **✗ нет.** `SEASONAL.md` ссылается на прототипы `Aura Web - Seasonal.html` и `Aura - Psychic App.html` с Tweaks → Season — в сдаче их нет (остались в проекте Claude Design). Есть веб-код в `code/` |

## Замечания

1. **Картинки — заглушки, нарисованные кодом** (`SEASONAL.md` §10, README). На вид пригодны
   (снежинка-кристалл, сердца), но дизайнер прямо просит заказать финальные иллюстрации того
   же размера и композиции. Решает владелец: запускать `winter` с ними или заказывать.
2. **Контракт шире брифа** — для `AURAT-0147`:
   - `copy`: кроме `heroTitle` / `heroBody` / `cta` ещё `heroBodyNoCode`, `ticketCodeEyebrow`,
     `ticketCodeTitle`, `ticketDiscountEyebrow`, `ticketDiscountTitle`, `ticketDiscountSub`;
     подстановки `{code}`, `{amount}`, `{pct}`; лимиты выше (вместо 60 / 160 / 24 в `0147-005`).
   - Форма `season: { preset, code, codeValue, discount: { pct } }` — предложение дизайнера;
     где лежат код, сумма и процент, решает `0147` (клиенту нужны все три).
   - §12 «проверки сервера» совпадают с решением владельца.
3. **Мелочи для `AURAT-0148`:** hero 164 pt (в диапазоне брифа), отступ до баннера 12; у билета в
   варианте брони сезонная скидка не показывается («booking → welcome или ничего») — цену всё
   равно показывает `PriceTag`, но стоит решить в спеке 0148; при Reduce Motion билет
   проявляется 320 мс (сейчас в приложении — сразу); тень билета `ticketStub` 22 %.
4. Тексты: «chat is free to start» уже есть в приложении (`FREE_TO_START`), утверждение верно.

## Перенос в хендофф (часть 2 брифа)

В `.claude/design_handoff_aura/` (репо воркспейса, не закоммичено):
- `SEASONAL.md`, `screens/67…81`, `effects/*.svg`, `presets/` (JSON, WebP, PNG);
- `code/*` → `prototype/`: добавлены `seasonal.jsx`, `seasonal.css`, `season-shapes.js`,
  `season-presets.js` (пути `../presets/` сходятся); `prototype/offer.jsx` **заменён** новым —
  он надмножество старого и без `seasonal.jsx` ведёт себя как прежний (`window.useSeason`
  с запасным значением);
- `README.md` пакета не переносился (дублирует `SEASONAL.md`);
- строка `SEASONAL.md` добавлена в таблицу документов `.claude/aura-build-rules.md`.

Дальше: решения владельца (заглушки, веб-экраны), затем закрытие задачи.
