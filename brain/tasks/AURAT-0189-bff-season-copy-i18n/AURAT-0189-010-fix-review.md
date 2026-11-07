# AURAT-0189-010 — правки по ревью кода

Дата: 2026-11-07 · Ревью координатора (`slave-1-ac`): 5 мелочей, блокеров нет. Владелец: «передать». Всё
застейджено, без коммитов.

1. **[minor] Лимит подзаголовка 40 — в контракте.** `aura-contracts` `src/season-copy.ts`: новый экспорт
   `SEASON_COPY_TRANSLATED_LIMITS` (`SEASON_COPY_LIMITS`, но `ticketDiscountSub` = 40: приложение сжимает, веб
   переносит). JSDoc `SEASON_COPY_LIMITS` ссылается на него, README — строка таблицы и абзац v0.30.0. BFF:
   `TRANSLATED_COPY_LIMITS` — это он (`localize-campaign.ts`). OpenAPI у `ticketDiscountSub`: «At most 36 once
   filled in English, 40 translated (the line shrinks or wraps)».
2. **[minor] Сводка места под код — по длинам.** `codeRoom` теперь `{ english, byLanguage }`, а
   `codeLossByLength` группирует языки по самой короткой длине кода, на которой кнопка теряет код. Бэкофис: «Код в
   кнопке на всех языках — до 7 знаков (по-английски до 10). Длиннее — кнопка без кода: с 8 — hu; с 9 — bg, es, et,
   fr, hu, it, lt, mt, nl, pt; с 10 — … (18)». Спеки: `campaign-translations` (+1), `campaigns.view`.
3. **[нит] Пресет и `{pct}`.** «Вставить пресет» берёт надзаголовок в пустую подпись, только если в нём нет
   плейсхолдеров (`seasonPlaceholdersIn`). Спека — случай `{pct}% off` → подпись пустая.
4. **[нит] ETag по языку через HTTP.** `app-config.controller.spec`: Fastify `inject` с настоящими пайпом и
   сервисом, кампании подделаны. `?lang=de` → 200 и `copyLanguage: de`; повтор с его ETag → 304; `?lang=en` с ETag
   de → 200 и другой ETag.
5. **[нит] «Normal case».** JSDoc `AppConfigDiscount.label` (контракты) и OpenAPI (app-config): «the server's
   translation, in normal case, in the request language — or, without one, as the operator typed it».

Проверки: lint, typecheck и build чистые; jest — 158 наборов, **2124** теста, все зелёные; контракты — `tsc` чистый
(dist пересобран и подложен в `node_modules` BFF).

Дальше — мёрж с одобрения владельца (за координатором), порядок из `009`: тег контрактов `v0.30.0` → переключение
BFF на тег → typecheck / test → коммит → проверка на bff-dev.
