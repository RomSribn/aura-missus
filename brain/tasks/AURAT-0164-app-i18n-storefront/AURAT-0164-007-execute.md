# AURAT-0164-007 — execute

Дата: 2026-11-06. slave-1, `feature/AURAT-0164-app-i18n-storefront`. Не закоммичено — всё в stage для ревью.

## Сделано

### Строки — 4 namespace × 24 языка (+ 1 ключ shared)
- `screens/home` → `home` (новый): приветствие с именем / без, секции, See all (+ a11y), баннер Daily (eyebrow,
  title, 2 подзаголовка), гороскоп (приглашение, кнопка, загрузка, ошибка, «нет чтения», подсказка a11y), лист даты
  рождения (заголовок, подзаголовок, Day / Month / Year, a11y поля, Save, 2 ошибки), a11y Continue chat.
  `config/constants.ts` — только машинные значения (`HOROSCOPE_DAYS`, `BIRTH_DATE_FIELDS` без подписей,
  `TOP_ADVISORS_COUNT`). Склейки из одних подстановок (`${sign}, ${dates}`, `${title}. ${subtitle}`) остались в коде.
- `screens/advisors` → `advisors` (расширен; `segments` из `0157` не тронуты): заголовок, поиск + Clear, категории
  (`CATEGORY_LABELS` удалены), 3 состояния списка.
- `screens/advisor-profile` → `advisor-profile` (новый): присутствие, About (= «About me» веба), Specialties, статистика
  (капсом; el заглавными), Reviews + Write a review / «You left a review» / Chat first to review, анонимный автор,
  Book, Start free chat, a11y кнопок и фото («действие, {{name}}» — решение 1).
- `screens/daily-card` → `daily-card` (новый): весь экран; `config/copy.ts` удалён, `copyForPhase` отдаёт ключ;
  черновик в чат — `t('draft')` на языке интерфейса (решение 2).
- `shared:price.perMinute` — «/min» (как у веба); `AdvisorRow` — и в строке «роль · цена», и суффиксом `PriceTag`.
  Бронь и оплата перейдут на него в своих задачах.
- Переводы: Daily card — с веба (`daily-page`) с правками по глоссарию (кнопка `ask` в форме кнопки языка, ga
  «comhairleoir», ga / da / sv / el eyebrow); категории, Top advisors, See all advisors, подзаголовок баннера, Book,
  Reviews, Specialties, «Anonymous · Verified client» (разрезано на два ключа), «/min» — с веба; остальное — по
  глоссарию и регистру. Без глагола прошедшего времени с родом (pl, cs, hr, sk, sl — «Opinia wystawiona», «Recenze
  odeslána»), без рода у «Away» (fr «Indisponible», pl «Poza siecią», ro «Nu e online», sl «Ni na spletu»…).
- `app/i18n/namespaces.ts` +3; `.eslintrc.js` — `i18next/no-literal-string` на `error` для четырёх слайсов;
  `SAME_AS_ENGLISH` +38 (`/min`, «Tarot», da «Book», nl «Reviews», nl / sv «Per min»).

### Вёрстка (замер шрифтами, opentype.js по бандл-TTF, 360 / 375 / 393 pt)
- Укорочено по замеру: «Start free chat» — de «Gratis chatten», el «Δωρεάν chat», ga «Comhrá in aisce», hu «Ingyen
  csevegés», sl «Klepet zastonj»; ga Book «Áirithigh»; de «Bewertung abgegeben», mt «Reċensjoni wara chat»,
  el «Προσθήκη γενεθλίων», et «Tõmba kaart».
- `ReviewCard`: строка автора переносится (`flexWrap`) — «· Verified client» уходит под «Anonymous», а не режет его
  (на 360 pt не влезает в 10 языках).
- `StatsCard`: подпись — одна строка, `adjustsFontSizeToFit` — ga «LÉIRMHEASANNA», mt «REĊENSJONIJIET» на
  360–375 pt шире ячейки на 1–5 pt. (Порога «≥ 0,85» нет: Fabric не читает `minimumFontScale` — исправлено в `008`.)
- `@max` выставлены по самому длинному переводу, прошедшему замер; в JSDoc — ширина места.

### Тесты
- Обновлены под новые a11y-подписи (ReviewsHeader, AdvisorHero, AdvisorProfileScreen, campaign), AdvisorsScreen —
  без удалённых констант.
- Новые: `ReviewCard` — анонимный отзыв по-немецки и перерисовка memo-карточки при смене языка; `DailyCardScreen` —
  черновик на немецком.
- `tsc` — 0, `eslint .` — 0, Jest — 187 наборов / 2154 теста. `translate.mjs check` — 0 запретных форм; советы —
  шум star ↔ start, составные слова, мутации ga, el «Δωρεάν chat» вместо «συνομιλία» (сознательно, по ширине).

### Документы
- `AURAF-0023-glossary.md` — расхождения веба (`daily-page:ask` и eyebrow, specialties, `write-review:title`).

## Не сделано / проверить в маноре
- ~~Кнопка Start free chat на телефонах ≤ 375 pt~~ — бюджет не учитывал обводку 1,5 pt: lt переносится до 440 pt,
  lv до 406 pt, hu / ga — на 360–375, bg Book рвался посреди слова. Решено в `008` (владелец, вариант «б»: панель
  переносится).
- Вёрстка на устройстве: псевдоязык и de / fi / hu / el / ga — баннер Daily, панель кнопок профиля, строка Reviews,
  статистика, лист даты рождения.
- Поиск советников идёт по английской роли — до шага 5.
- Общие файлы с `AURAT-0163`: `namespaces.ts`, `.eslintrc.js`, `shared/config/locales/*`, `translations.test.ts`.
