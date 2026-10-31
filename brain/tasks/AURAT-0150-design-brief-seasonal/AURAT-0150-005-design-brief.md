# AURAT-0150-005 — Бриф для Claude Design: сезонное оформление (`winter`, `valentine`)

Дата: 2026-10-31
Пишет: `aura-app-manor` / `slave-0`
Статус: **утверждён** владельцем 2026-10-31 (`006`) — можно передавать в Claude Design
Фича: `AURAF-0022` строка 008. Источник: `AURAI-0009` §4, §8. Факты: `004-context`.

Файл из двух частей:

- **Часть 1** — промпт для Claude Design. Копируется **целиком**, от `=== BEGIN PROMPT ===` до
  `=== END PROMPT ===`, в проект с хендоффом Aura (дизайнер уже знает токены, экраны 01, 07,
  42, `OFFER.md`, `MOTION_AND_ICONS.md`). Правила в нём самодостаточны.
- **Часть 2** — для владельца: сроки, куда ложатся файлы, как принимаем, что согласовать с
  `AURAT-0147` / `0148` / `0149`, что решить. В Claude Design **не** вставлять.

---

# Часть 1 — промпт для Claude Design

```text
=== BEGIN PROMPT ===

Design SEASONAL VISUALS for the Aura app (React Native, iOS + Android) and the
Aura web app, as an addition to the existing Aura handoff. Same design system,
same tokens, same type (Bricolage Grotesque display, Hanken Grotesk body).

WHAT THIS IS
Around holidays an operator switches on a "season" from the back office. The
app and the web read it from the server (GET /v1/app-config) and change a few
fixed PLACES. They do NOT repaint the whole app. Colours, images and copy for
a season arrive from the server without an app release. The layout of each
place, the particle effects and the motion are built into the app once and
cannot change without a release. So you design two things:
  A. the PLACES themselves (layout, sizes, states, motion), shipped in code;
  B. two PRESETS that fill them, "winter" and "valentine": palette values,
     artwork files and suggested copy, delivered as data.
When no season is on, every place looks exactly like today's design.

HARD RULES
1. Only the places listed below change. Paper, card, ink, lines, scrim,
   chat, prices (PriceTag, OffChip), primary buttons elsewhere, and the
   whole TEAL family (online, presence, chat, send) never change with a
   season. Teal means "communication" and stays teal all year.
2. Keep the two-tone meaning. A seasonal colour on something you tap to act
   or pay plays the coral role (warm, saturated). Nothing seasonal may look
   like an online/presence signal.
3. Colours come only from the token whitelist below. A preset sets values
   for these tokens and nothing else. Artwork sits on the token-coloured
   ground and does not try to match UI colours with its own.
4. Contrast: every text colour is at least 4.5:1 against EVERY ground it sits
   on (for a gradient: against both ends), large text included. Icons and
   other non-text marks that carry meaning are at least 3:1. The exact pairs
   are listed under CONTRAST PAIRS below; the server checks them and will
   not switch on a season that fails one. Report every ratio per preset.
5. No text inside images. All words (title, body, button, code) are live
   text from the server, so they can be translated and their contrast is
   controlled. Artwork is decoration only.
6. Artwork must hold for the WHOLE window of its preset. "winter" runs from
   the week of Thanksgiving (26 Nov) through New Year's Day: no turkeys,
   Santa, nativity, religious symbols, dates or holiday names in the art.
   Snow, frost, stars, a winter night sky, candlelight, evergreen and
   crystal fit, and so do the brand's plum and gold. "valentine" runs about
   7–15 Feb: love and connection, roses, hearts, candlelight. Warm and calm,
   not kitsch. Aura sells on trust; nothing may read as a casino or a sale
   flyer.
7. Reduced motion: with the OS setting on (iOS Reduce Motion, Android
   "Remove animations", web prefers-reduced-motion: reduce) there are NO
   particles at all and nothing loops; entrances become opacity-only. Draw
   that state.
8. Nothing new loops forever (the splash orb pulse already does and stays).
   The existing coupon rule applies: a thing that keeps glinting is a slot
   machine.
9. Everything must work at a content width of 316 pt (360 pt Android phone)
   through 386 pt (430 pt phone). Draw on 390 pt screens (346 pt content)
   and check the narrow end.

------------------------------------------------------------------------
THE PLACES (app; sizes in pt)
------------------------------------------------------------------------
1. HOME HERO: a new card on Home (screen 07), between the greeting and the
   "Daily ritual" banner. Shown only while a season is on.
   - Width: content width (screen − 2×22). Height: pick ONE fixed value in
     136–168 pt; it never grows with the copy. Corner radius 24, like the
     Daily ritual banner (148 pt, radius 24) right under it. The two must
     read as a pair, not as two competing banners. Gap from the greeting
     16 pt; you set the gap to the Daily ritual banner.
   - Ground: linear gradient heroFrom → heroTo (your angle).
   - Art: one transparent illustration anchored bottom-right in a box of
     about 132×132 pt. It may bleed off the right/bottom edge and be clipped
     by the card, like the tarot fan in the Daily ritual banner. Copy keeps
     clear of the art box.
   - Copy (left column, live text): title (display, ~20 pt), body (body
     font, ~13 pt), and a CTA button. Set the character limits you can
     guarantee at 316 pt and write them down. We expect roughly title ≤ 28,
     body ≤ 60, CTA ≤ 16 including the code.
   - CTA, like "Apply WINTER5": it opens the promo-code sheet with the code
     already filled in. Fill heroCta, label heroCtaLabel. When the season has
     no code there is no CTA; draw that variant too.
   - States to draw: with code; without code; art missing or still loading
     (ground + copy only, must still look finished); longest allowed copy at
     316 pt; reduced motion.
   - Entrance: fade + rise, in the family of the screen enter (12 pt,
     320 ms, ease-out). Give the numbers.

2. ADVISORS TICKET: the CouponTicket place above the advisor list
   (screen 42). Keep the ticket's geometry: stub 74 pt, 9 pt notches,
   radius 18, min height 84, dashed perforation, entrance 450 ms + one sheen.
   - Seasonal skin: stub fill ticketStub, stub label ticketStubLabel, body
     gradient ticketSoft → card, eyebrow ticketEyebrow, dash ticketSoft. The
     glyph in the 38 pt white disc on the stub becomes a small seasonal
     image (snowflake, heart…) of about 22–24 pt.
   - Two seasonal variants:
     a) CODE ticket: "$5 on your balance" + the code (e.g. WINTER5) and a
        tap affordance. Tapping opens the promo-code sheet with the code.
     b) DISCOUNT ticket: a seasonal discount on sessions, e.g.
        "20% OFF · Winter sale", "Auto-applied" (no code).
   - Only ONE ticket is ever shown. Rule (draw each case): if a discount
     will apply to this user (the server applies the bigger of the
     first-session −50% and the seasonal one), show the ticket for that
     discount: the welcome ticket in seasonal skin when −50% wins, the
     discount ticket otherwise. If no discount applies and the season has a
     code, show the code ticket. Otherwise, no ticket.
   - The same ticket appears on the web wherever CouponTicket appears today
     (home side column, advisors, advisor page, match, account).

3. SPLASH ORB: the coral orb on the splash (screen 01), 120 pt, pulse
   2.6 s. A season retints it with two colours: orbBase (the saturated rim)
   and orbSoft (the pale pearl highlight). Keep the orb's light: a pale
   pearl with colour on one side, not a flat saturated ball. The splash uses
   the season saved at the previous launch, so the very first launch of a
   season still shows coral. That is expected.

4. DAILY RITUAL BANNER: Home's plum banner (148 pt). A season may change its
   ground gradient bannerFrom → bannerTo and its accent bannerAccent (the
   eyebrow "DAILY RITUAL", the card outlines and star glyphs of the fan;
   today gold). The title stays white and the subtitle white at 70%, so the
   ground must stay dark enough for both. It is still the tarot ritual: keep
   it mystic and recognisably the same banner.

5. TAB BAR: only the active icon and its dot change, via tabActive (today
   coral). Inactive icons (ink-3), the bar and its tint stay. On the web the
   same token colours the active item of the top navigation and of the
   mobile bottom bar, where it also colours the label text; hence 4.5:1.

6. PARTICLE EFFECT: "snow", "leaves" or "hearts", drawn by the app and
   tinted with effectTint. A season picks one or none.
   - Where: inside the Home hero only, clipped by its corners, behind the
     copy layer and never over the text; opacity at most about 0.7.
   - How much: a light touch, about a dozen particles visible at once,
     6–16 pt. Give count, size range, fall time, drift/sway, rotation and
     opacity range.
   - How long: it starts when Home comes into view and settles within 12 s
     (the last particles finish their fall). It plays again each time Home
     is opened, like the coupon's single sheen. No endless loop.
   - Reduced motion: no particles (rule 7).
   - Shapes: single-colour SVG, viewBox 0 0 24 24, one filled path each, no
     strokes, no gradients. Snow ×3 (a soft dot, a small flake, a six-arm
     flake); leaves ×3 (autumn, for a later preset, needed now because the
     shapes ship inside the app); hearts ×2.

------------------------------------------------------------------------
THE WEB (same look)
------------------------------------------------------------------------
The web reads the same season and the same token values as CSS variables
(e.g. --season-hero-from). Its Home differs: greeting, then a two-column row
"Ask | coupon + side stack", then the Daily banner, then advisors.
- Hero: full content width (up to 1220 px) between the greeting and that
  row. About 200 px tall on wide screens, the app's size at ≤ 760 px. Same
  art file, art box about 200 px. The CTA goes to /promo/<CODE>.
- Ticket, Daily banner and active nav item: as in the app.
- Particles: inside the hero, same rules, prefers-reduced-motion respected.
Draw the web hero at 1440 px and at 390 px.

------------------------------------------------------------------------
TOKEN WHITELIST (the only colours a season may set)
------------------------------------------------------------------------
Token            | Where                                 | Today (no season)
heroFrom, heroTo | hero ground gradient                  | none (no hero)
heroTitle        | hero title text                       | none
heroBody         | hero body text                        | none
heroCta          | hero button fill                      | none
heroCtaLabel     | hero button text                      | none
ticketStub       | ticket stub fill                      | #EC5F73 (accent)
ticketStubLabel  | stub label ("SALE" / "CODE")          | #FFFFFF
ticketSoft       | ticket body gradient start, dash      | #FCE4E8 (accent-soft)
ticketEyebrow    | ticket eyebrow text                   | #EC5F73
orbBase, orbSoft | splash orb rim / highlight            | #EC5F73 / #FCE4E8
bannerFrom       | Daily ritual banner gradient start    | #34204A (plum)
bannerTo         | Daily ritual banner gradient end      | #1F122B (plum dark)
bannerAccent     | banner eyebrow, fan outlines, glyphs  | #D9B26A (gold)
tabActive        | active tab icon + dot / web nav item  | #EC5F73
effectTint       | particles                             | none

CONTRAST PAIRS (the server checks exactly these)
The back office computes the WCAG 2.x contrast ratio of every pair below and
refuses to switch on a season that fails any of them. Each row is one check:
foreground on background, minimum ratio. A gradient ground appears twice,
once per end. A fixed ground is given as hex. "#FFFFFF@0.70" means white at
70% opacity composited over that row's background before the ratio is taken.

#   | foreground        | background   | min
P1  | heroTitle         | heroFrom     | 4.5
P2  | heroTitle         | heroTo       | 4.5
P3  | heroBody          | heroFrom     | 4.5
P4  | heroBody          | heroTo       | 4.5
P5  | heroCtaLabel      | heroCta      | 4.5
P6  | heroCta           | heroFrom     | 3
P7  | heroCta           | heroTo       | 3
P8  | ticketStubLabel   | ticketStub   | 4.5
P9  | ticketEyebrow     | ticketSoft   | 4.5
P10 | ticketEyebrow     | #FFFFFF      | 4.5   (card)
P11 | #FFFFFF           | bannerFrom   | 4.5   (banner title)
P12 | #FFFFFF           | bannerTo     | 4.5
P13 | #FFFFFF@0.70      | bannerFrom   | 4.5   (banner subtitle)
P14 | #FFFFFF@0.70      | bannerTo     | 4.5
P15 | bannerAccent      | bannerFrom   | 4.5
P16 | bannerAccent      | bannerTo     | 4.5
P17 | tabActive         | #F4EFE5      | 4.5   (app tab bar)
P18 | tabActive         | #FFFFFF      | 4.5   (web nav item on card)

Not checked: orbBase, orbSoft and effectTint carry no text and no meaning;
make them look right. Report all 18 ratios per preset in SEASONAL.md.
The "Today" column above shows the current look for reference only; several
of its pairs fall short of these numbers. The seasonal values must meet them.

------------------------------------------------------------------------
ARTWORK FILES (served from our CDN by URL)
------------------------------------------------------------------------
Images load over the network by URL, so there are no @2x/@3x variants: each
file is made once, at the largest size it is ever shown.
- hero art: 720×720 px, transparent background, subject within the inner
  90%, clean edges on both light and dark grounds.
- ticket art: 192×192 px, transparent, must read at 22 pt.
- Delivery format: WebP with alpha (lossy, quality about 85), sRGB; hero
  ≤ 150 KB, ticket ≤ 30 KB. Plus a PNG master of each.
- Name by preset: presets/winter/hero.webp, presets/winter/ticket.webp, …
- No text, dates or logos inside the art (rule 5).

------------------------------------------------------------------------
PRESETS TO FILL
------------------------------------------------------------------------
For each of "winter" and "valentine" deliver presets/<id>.json:
{
  "id": "winter",
  "palette": { "heroFrom": "#……", … every whitelist token … },
  "art": { "hero": "presets/winter/hero.webp",
           "ticket": "presets/winter/ticket.webp" },
  "effect": "snow",              // or "leaves", "hearts", null
  "copy": { "heroTitle": "…", "heroBody": "…", "cta": "Apply {code}" }
}
- "palette" lists EVERY whitelist token, all 17, with no omissions. The
  server does not fill gaps with defaults; a preset with a missing token is
  rejected.
- "id" is only a name for the operator and the audit log. The app and the
  web do not look it up: they draw the season from the palette, art, copy
  and effect. So a new preset later (say "autumn" next year with effect
  "leaves") is data only, with no app release, as long as it uses the places
  and particle shapes already built in.
- Copy is a suggestion, in English; {code} is replaced with the live code.
- winter uses effect "snow"; valentine uses "hearts".

------------------------------------------------------------------------
DELIVERABLES
------------------------------------------------------------------------
Add to the Aura handoff:
1. SEASONAL.md: the spec of everything above as you resolved it. Sizes,
   gaps, type sizes, character limits, every state, the ticket rule, motion
   numbers (entrance, particles, timings, easing), reduced-motion behaviour,
   and the per-preset contrast tables. Name it SEASONAL.md, never CLAUDE.md.
2. Screens, continuing the numbering from 67, for example: home-winter,
   home-valentine, home-winter-no-code, home-no-art, home-longest-copy-316,
   home-reduced-motion, advisors-code-ticket, advisors-discount-ticket,
   advisors-welcome-seasonal, splash-winter, splash-valentine,
   tabbar-winter, web-home-winter-1440, web-home-winter-390. Plus one sheet
   comparing each place with no season, winter and valentine side by side.
3. effects/snow-1..3.svg, effects/leaf-1..3.svg, effects/heart-1..2.svg.
4. presets/winter.json, presets/valentine.json, presets/<id>/hero.webp and
   ticket.webp, with their PNG masters.
5. Optional: a prototype screen with a season switcher (none / winter /
   valentine), like the existing Tweaks.

=== END PROMPT ===
```

---

# Часть 2 — для владельца (в Claude Design не вставлять)

## Сроки

| Что | Нужно к | Почему |
|---|---|---|
| Места (`SEASONAL.md`, экраны), частицы `effects/*.svg`, правило билета | **~09.11** | `AURAT-0148` закладывает места и частицы в сборку ~15.11; чего нет в сборке, то без релиза не появится |
| Пресет `winter` (палитра, `hero`, `ticket`, тексты) | **~18.11** | кампания должна встать до Thanksgiving 26.11 / Black Friday 27.11; это данные, релиз не нужен |
| Пресет `valentine` | **~25.01.2027** | окно ~07–15.02; можно сдать вместе с первой частью |

Если дизайнер сдаёт всё одной поставкой — к ~09.11.

## Куда ложится сдача

- Хендофф — в `.claude/design_handoff_aura/` как обычно: `SEASONAL.md` (не `CLAUDE.md`),
  экраны `screens/67…`, `effects/`, `presets/`. Строку про `SEASONAL.md` добавить в таблицу
  документов `.claude/aura-build-rules.md`.
- Картинки — в R2 под версионным путём, например `seasonal/winter/v1/hero.webp`. **Файл по
  тому же URL не перезаписывать**: приложение кэширует и прогревает картинки по URL, поэтому
  новая версия = новый путь (`v2`).
- Палитра, URL и тексты из `presets/<id>.json` — во вкладку «Кампании» бэкофиса (`AURAT-0147`).
  Новый пресет потом (например, `autumn` с `leaves` следующей осенью) — тоже только данные,
  без релиза, пока он укладывается в места и частицы, уже собранные в приложении.

## Приёмка

1. Все 18 пар P1–P18 на каждый пресет в `SEASONAL.md`; пересчитываем сами (тот же расчёт, что
   в `004-context`), и бэкофис проверит их ещё раз при включении кампании. В
   `presets/<id>.json` — все 17 токенов, без пропусков. Веб дополнительно гоняет
   `contrast.test.ts` на каждую тему (`AURAT-0149`).
2. Размеры и формат файлов (WebP с альфой, sRGB, ≤ 150 / 30 KB), в картинках нет текста.
3. Есть экран «без картинки» и экран Reduce Motion.
4. Самые длинные тексты помещаются на 316 pt; лимиты символов записаны — их же проверяет
   бэкофис.

## Что согласовать со смежными задачами

- **Решение владельца 2026-10-31** (передано из манора): палитра приходит с сервера по белому
  списку этого брифа; бэкофис `AURAT-0147` считает WCAG по парам P1–P18 и не даёт включить
  кампанию, которая хоть одну не проходит. Тон орба — палитрой (`orbBase` / `orbSoft`).
- **`AURAT-0147`** (BFF, `aura-bff-manor` slave-2): спека
  `AURAT-0147-005-spec.md` есть и дорабатывается под форму этого брифа — белый список (17
  токенов, все обязательны), пары контраста, `art.hero` + `art.ticket` (ключи в бакете,
  версионные пути), `copy.cta` с `{code}`, `effectTint`, лимиты символов из `SEASONAL.md`,
  пресет `halloween` убирается; `preset` / `id` — только имя для журнала.
  **Белый список и пары P1–P18 становятся контрактом `@aura/contracts` `v0.27.0`.** После
  сдачи дизайнера менять их можно только через `0147` (новая версия контракта и проверки
  бэкофиса), не правкой брифа или `SEASONAL.md`.
- **`AURAT-0148`** (приложение): места 1–6, правило одного билета, частицы только в hero, не
  дольше 12 с, без частиц при Reduce Motion. `react-native-reanimated` в зависимостях нет:
  там решить, делать на `Animated` или добавлять зависимость (натив — только в этой сборке).
- **`AURAT-0149`** (веб): те же токены как `--season-*`, hero над рядом «Ask | купон».

## Решено владельцем (2026-10-31, `006`)

1. Правило одного билета на месте `CouponTicket` — как в части 1, место 2.
2. Частицы — только внутри hero, конечные (до 12 с), повтор при каждом заходе на Home.
3. Сроки сдачи — как в таблице выше.

## Замечено попутно (вне задачи)

Текущий вид приложения порог 4.5:1 не держит: coral текстом на card — 3,3, белый на coral —
3,3, «See all» на paper — 2,8, активная иконка таб-бара — 2,8 (ниже 3:1), teal «Auto-applied» —
3,1. На вебе это закрыл `AURAT-0123`, в приложении такой задачи нет. Бриф обязывает сезонные
значения держать порог; вид «без сезона» остаётся как есть.
