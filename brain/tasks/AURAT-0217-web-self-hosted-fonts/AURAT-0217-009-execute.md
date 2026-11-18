# AURAT-0217-009 — execute

Дата: 2026-11-18. slave-1, `feature/AURAT-0217-web-self-hosted-fonts`. По `005` + `007`, решение
владельца — вариант 1 (`008`). Не закоммичено, всё в индексе — на ревью владельцу.

## Файлы (aura-web)

- `scripts/fonts/` — новое: `build_fonts.py`, `sources.json` (google/fonts `bbda7253` — 2 вариативных TTF;
  aura-app `e155f11` — 6 TTF, 3 OFL, `exemplars.json`; всё с sha256), `requirements.txt` (fontTools 4.60.2,
  brotli 1.2.1), `README.md`; сгенерированное `exemplars.json` (фикстура теста).
- `public/fonts/` — выход сборки (≈ 230 КБ):
  - `bricolage-grotesque-latin.woff2` (94 КБ, `wght 600–800`, `opsz 12–96`);
  - `hanken-grotesk-latin.woff2` (30 КБ, `wght 400–700`);
  - 6 × `*-greek-cyrillic.woff2` (13–14 КБ);
  - `fonts.css` — 14 `@font-face` (7 весов × латиница + el/bg);
  - 3 OFL.
- `src/features/pay/config/stripe-fonts.ts` — сгенерировано: 8 лиц Hanken для Elements.
- `src/features/pay/lib/stripe-fonts.ts` — лица → `CustomFontSource` с абсолютным URL;
  `model/page-fonts.ts` — на `window.location.origin`; `ui/card-elements.tsx` — `fonts: pageFonts()`;
  из `config/pay.ts` удалён `STRIPE_FONT_CSS`.
- `index.html` — без Google; `preload` двух латинских файлов + `/fonts/fonts.css`.
- `deploy/web/nginx.conf` — `location /fonts/`: `headers.conf`, `Access-Control-Allow-Origin "*"`,
  `no-cache`, `=404`.
- `deploy/web/headers.conf` — `style-src 'self' 'unsafe-inline'`, `font-src 'self'`, из `connect-src` убран
  `fonts.googleapis.com`; комментарий переписан.
- Тесты:
  - `src/app/__tests__/fonts.test.ts` — новый: чтец woff2 → `cmap` (brotli из `node:zlib`); 7 весов × 24
    языка + обязательные знаки; непересечение диапазонов; диапазон ⊆ `cmap` файла; состав
    `public/fonts`; семейства = `--font-d` / `--font-b`; preload; нигде нет `fonts.googleapis/gstatic`;
  - `src/app/__tests__/headers.test.ts` — `font-src` / `style-src` только свои, CORS и 404 у `/fonts/`;
  - `src/features/pay/lib/__tests__/stripe-fonts.test.ts` — список Elements = лица Hanken из `fonts.css`,
    абсолютные URL.
- `.gitignore` — `scripts/fonts/.cache/`, `scripts/fonts/__pycache__/`.

Вне aura-web: `aura-web-manor/.claude/aura-web-build-rules.md` — Payments (шрифт Elements — наш, не
`cssSrc`, CORS у `/fonts/`) и Design system → Type (свои шрифты, `scripts/fonts`, Google Fonts не
подключать). Workspace aura-web-manor — не git-репозиторий, правка видна только в самом файле.

## Решения по ходу

- Сгенерированные `fonts.css` и `stripe-fonts.ts` разложены так, как их разложил бы Prettier:
  `format:check` на них проходит, `--check` сборки их сверяет.
- U+0301 нужен не только bg: в CLDR он есть у nl (ij́). В латинских файлах Google его нет — берётся из
  el/bg-файла, как U+2010 / U+2011 и (у Hanken) U+202F.
- Лица Elements несут `display: 'swap'` из той же константы сборки, что и `fonts.css`.
- Строк интерфейса задача не добавляет — переводы не нужны.

## Проверено (slave)

- `build_fonts.py --check` в чистом venv только из `requirements.txt`, с пустым кэшем: «Up to date» —
  побайтно воспроизводимо.
- `npm run lint` — чисто; `npm run typecheck` — 0 ошибок; `npm test` — 128 наборов, 2219 тестов, зелёные;
  `npm run build` — собрано, в `dist/fonts` 12 файлов, в `dist/index.html` Google нет.
- `prettier --check .` — замечание только на `src/pages/booked/config/locales/el.ts` (было до задачи, не
  тронуто).
- Негативная проверка: без el/bg-лица Bricolage 600 и с латинским файлом вместо el/bg Hanken 700 —
  `fonts.test.ts` падает (bg, el, nl, обязательные знаки, диапазон вне `cmap`, состав папки); восстановлено.

## Открыто — проверка в маноре после merge

По `005` § «Проверка» и `007`: Network `fonts.g` пусто (страницы, Book с картой, Top up); во фрейме Stripe
woff2 с нашего домена, 200, без ошибок CORS; Console без CSP; Rendered Fonts — Hanken в Elements,
Bricolage / Hanken на el и bg; fr — U+202F; латиница до/после без изменений. reCAPTCHA — что грузит её фрейм
при входе.
