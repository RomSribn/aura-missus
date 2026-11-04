# AURAT-0155-004 — context

Дата: 2026-11-04. aura-app `feature/AURAT-0155-app-i18n-glossary` @ `40d0ee7`; aura-web манор `develop` @ `88dd553`.
Замеры — свежим проходом по вебу (скрипты в scratchpad сессии, не в репо).

## Источники
- `AURAF-0023` (план шагов), `AURAI-0010` §5, §9, Recommendation 1b, решения владельца 7 (ревью носителей не
  блокирует, кроме оплаты / возвратов / отмены / удаления / юр. текстов).
- `AURAI-0010-evidence.json`: `web-i18n` (46% строк приложения дословно есть в вебе), `tooling-quality` (82 коротких
  термина, 78 расхождений, болгарский «ты/вы», FR/PT «chat»; 24% точных совпадений по грубой эвристике).
- `.claude/aura-build-rules.md` «Translations» — регистр уже записан (AURAT-0154): «ты» — de es nl sv da fi et hu
  ro it pl mt ga; «вы» — bg cs el fr hr lt lv pt sk sl; не согласовывать с родом; бренды; греческие заглавные;
  ș/ț; NFC; без U+00AD; `SAME_AS_ENGLISH`.
- Код: `src/shared/config/locales/*` (пространство `shared`, 24 языка, часть взята у веба);
  `src/app/i18n/__tests__/translations.test.ts` (полнота, плюралы, плейсхолдеры, теги, типографика,
  `SAME_AS_ENGLISH`); `scripts/i18n/generate-plural-rules.mjs` (образец скрипта, ESM, без новых зависимостей).

## Веб сейчас (39 пространств, 751 строка, 631 уникальный английский текст)
- **Точные дубли с разным переводом в одном языке:** 95 пар по 18 английским строкам. Большая часть — законные
  (плюральная форма в неплюральном ключе: «{{count}} min left» → resta/restano; род объекта «Keep it» —
  сессия/аккаунт; существительное vs глагол «Book» — шаг «Бронь» vs кнопка «Забронировать»). Настоящий дрейф:
  bg «Опитай / Опитайте отново», «Резервирай / Резервирайте сесия»; hu «Újrapróbálás / Próbáld újra»;
  fr «Ouvrir le chat / la discussion»; pt «Abrir chat / conversa»; ro «chatul / conversația»;
  lt «Užsisakyti / Rezervuoti seansą»; es «Hecho / Listo»; lt «Gerai / Atlikta»; da «Redigér / Rediger»;
  «Browse advisors» в 6 языках двумя глаголами.
- **Термины в контексте** в основном ровные: session — fr séance, hu konzultáció, lt/et seansas/seanss,
  sk sedenie, sl seja, cs sezení; chat — el συνομιλία, et vestlus, hu csevegés, lt pokalbis, lv saruna, sl
  klepet, ga comhrá, sk čet; при этом fi chat/keskustelu, pt chat/conversa, ro chat/conversație, nl chat/gesprek
  смешаны. reading — fr consultation/voyance, de Deutung, lt būrimas, lv zīlēšana — без единой формы.
- **Обращение (местоимения на вебе):** таблица build rules подтверждается. bg — «Вие/ваш» во всех предложениях
  (129, «ти» — 0), а короткие кнопки — императив ед. ч. («Опитай», «Резервирай», «Запази»; 97 против 28
  «-йте»). Так же устроены hr и sl (текст на «vi», кнопки «Pokušaj ponovno», «Rezerviraj sejo»): кнопка-команда в
  ед. ч. — обычная конвенция южнославянских интерфейсов. Дрейф bg — это кнопки в форме «-йте», а не «ты» в
  тексте. В `shared` приложения bg уже так: «Затвори», «Изпрати кода отново», в тексте «Натиснете…».
- **Форма кнопки по языкам** (по вебу): инфинитив — cs sk lt lv fr pt es de nl; существительное — el hu (и
  el — повелительное на «-στε» в «Δοκιμάστε ξανά»); императив ед. ч. — bg hr sl it pl ro; императив (одна форма) —
  da sv fi et mt ga.

## Приложение
- ≈ 523 строки-кандидата (AST, без тестов и locales); чаще всего: session 32+15, advisor 22+11, balance 19,
  chat 15, free 14, card 13, review 11, top up 10, book/booked 16, promo 5, reschedule 5, horoscope 3, voice 3,
  credit 3, «Google Play» / «App Store».
- В вебе нет терминов приложения: top up, store / IAP, voice note, video, attachment, horoscope, zodiac,
  daily ritual, seasonal, anonymous — их переводим сами.

## Противоречия
- `AURAI-0010` говорит «болгарский смешивает ты/вы» — по замеру в тексте смешения нет, смешаны формы кнопок.
  В спеке — правило «текст на Вие, кнопка — ед. ч.».
- «78 расхождений» (`tooling-quality`) считались по коротким терминам на старом вебе; сейчас по всем строкам —
  95 пар / 18 строк, настоящего дрейфа ≈ 15 пар. Порядок тот же, вывод не меняется.
