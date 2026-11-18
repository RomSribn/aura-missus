# AURAT-0217-005 — spec (draft)

Тип: задача (`AURAF-0020`, выдана из `AURAT-0209`). Только aura-web; BFF и контракты не меняются.
Основание — бриф `001`, `AURAT-0209-008` п. 2; замеры — `004-context`.

## Что видит человек

- Страницы и форма оплаты выглядят как сейчас: те же Bricolage и Hanken, на латинице те же глифы и
  оптический размер, что отдаёт Google сегодня.
- На греческом и болгарском заголовки и текст — фирменными шрифтами, как в приложении (`AURAT-0156`), а не
  системным посреди слова.
- Браузер не обращается к Google Fonts ни на одной странице, ни в шторке оплаты.

## Решение владельца (нужно до кода)

**Из чего собрать латиницу.** Рекомендую **вариант 1**.

1. **Латиница — вариативные файлы Google как сейчас, el/bg — из шрифтов приложения.**
   - Латиница не меняется ни на пиксель: тот же файл google/fonts, оптический размер заголовков как в
     дизайне (`Aura Web*.html` тоже грузит `opsz 12..96`).
   - Греческий и кириллица — из 6 статичных файлов `AURAT-0156`, подгружаются, только когда на странице
     есть такие буквы (12–14 КБ на начертание).
   - Первая загрузка: 124 КБ латиницы.
2. **Все 7 статичных файлов приложения целиком.**
   - Веб = приложение побайтно, сборка проще.
   - Но заголовки шире: статика — оптический размер 14, на 32px строка шире на ~2,4%, на 44px — на ~4%
     (возможны новые переносы в hero).
   - Hanken 500 (счётчик отзывов) станет 400.

## Что меняется

1. **Сборка — `scripts/fonts/`** (Python, руками, не в CI и не в `npm`; как в приложении):
   - `build_fonts.py`, `requirements.txt` (fontTools 4.60.2 — как у приложения, brotli), `sources.json`,
     `README.md`; `.cache/` в `.gitignore`;
   - источники с sha256:
     - google/fonts `bbda7253` — `BricolageGrotesque[opsz,wdth,wght].ttf`, `HankenGrotesk[wght].ttf`;
     - aura-app `e155f11` — 6 TTF (Bricolage 600/700/800, Hanken 400/600/700) и `exemplars.json`,
       читаются через `git -C <aura-app> show` (путь — аргумент);
   - латиница: Bricolage `wght 600–800`, `opsz 12–96`, `wdth 100`; Hanken `wght 400–700`; диапазоны
     Google latin + latin-ext;
   - el/bg-файлы: греческий U+0370–03FF, кириллица U+0400–045F и Ґ ґ, плюс знаки, которых нет в латинских
     файлах (U+0301, U+2009, U+2010, U+2011, U+202F);
   - `unicode-range` каждого `@font-face` скрипт пишет из настоящего `cmap` файла — диапазоны не
     пересекаются;
   - падает, если хоть одна буква 24 языков (CLDR 48.2) не покрыта;
   - `--check` — ошибка, если что-то на диске отличается; повторный запуск даёт те же байты.
2. **`public/fonts/`** (выход сборки, ≈ 210 КБ):
   - 2 латинских файла и 6 el/bg woff2;
   - `fonts.css` — `@font-face` на каждый вес: Bricolage 600/700/800, Hanken 400/500/600/700,
     у каждого пара «латиница + el/bg» с одинаковыми дескрипторами;
     - иначе браузер не сложит их в один шрифт и греческий в заголовке 600 уйдёт в системный;
     - Hanken 500 на el/bg берёт файл 400 — 500 в приложении нет;
     - `font-display: swap`, как у Google сейчас;
   - `OFL-BricolageGrotesque.txt`, `OFL-HankenGrotesk.txt`, `OFL-Commissioner.txt`.
3. **`index.html`.**
   - Убрать preconnect и stylesheet Google.
   - Добавить `<link rel="stylesheet" href="/fonts/fonts.css">` и `preload` двух латинских файлов.
4. **Elements.** `STRIPE_FONT_CSS` = `/fonts/fonts.css` (Stripe принимает относительный URL). Остальное в
   `pay` не меняется.
5. **nginx — `location /fonts/`.**
   - `Access-Control-Allow-Origin: *`: файлы грузятся во фреймах Stripe с `js.stripe.com`.
   - `Cache-Control: no-cache`, как у остального `public/`.
   - Нет файла — 404, не `index.html`.
6. **CSP (`headers.conf`).**
   - `style-src 'self' 'unsafe-inline'`, `font-src 'self'`.
   - Из `connect-src` убрать `fonts.googleapis.com`.
   - Комментарий про шрифт Elements переписать.
7. **Тесты (Vitest).**
   - `headers.test.ts` — Google Fonts нет ни в одной директиве, `font-src` = `'self'`; в `nginx.conf` у
     `/fonts/` есть CORS.
   - Новый `app/__tests__/fonts.test.ts` — свой чтец woff2 (`node:zlib` brotli → `cmap`, ~60 строк, без
     зависимостей):
     - каждая пара «семейство × вес» из `fonts.css` покрывает все буквы 24 языков и обязательные знаки
       (U+00A0, U+202F, U+2212, U+2010, U+2011) с учётом `unicode-range`;
     - диапазоны внутри пары не пересекаются;
     - каждый `url()` существует, каждый файл `public/fonts` на что-то ссылается;
     - семейства `fonts.css` = `--font-d` / `--font-b` из `tokens.css`;
     - `fonts.googleapis.com` / `fonts.gstatic.com` нет в `index.html`, `src/**`, `deploy/web/*.conf`.
8. **Правила.** `aura-web-build-rules.md` (workspace-репозиторий):
   - Payments: вместо «`fonts.googleapis.com` в `connect-src`» — шрифт Elements из `/fonts/` с CORS;
   - Design system → Type: шрифты со своего домена, `scripts/fonts`, Google Fonts не подключать
     (Privacy §12, `AURAT-0217`).

## Чего задача не делает

- reCAPTCHA остаётся: её фрейм — Google, создаётся только при входе по телефону и описан в §12 (B8). Если
  этот фрейм сам грузит шрифты Google, это видно только во время входа; в отчёте проверки скажу, что видел.
- Банковские методы и остальное в оплате — без изменений.

## Проверка

- Slave: `npm run lint`, `npm run typecheck`, `npm test`, `npm run build`. `build_fonts.py --check` в чистом
  venv из `requirements.txt` — «Up to date».
- Манор после merge (web-dev):
  - DevTools → Network, фильтр `fonts.g`, Disable cache: пусто на главной, `/advisors`, профиле советника,
    в шторке Book с картой (Elements, оба шага), в Top up;
  - Console: нет нарушений CSP;
  - Elements: подписи и поля Hanken (Computed → Rendered Fonts);
  - язык el и bg: заголовок Bricolage 800 и текст Hanken 400 — Rendered Fonts без системного шрифта;
  - fr: цена с U+202F;
  - латиница: главная desktop 1440 и phone 390 до/после — без изменений.
