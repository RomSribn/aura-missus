# AURAD-0019 — Веб-клиент: свой репозиторий `aura-web` и свой манор; Vite SPA на строгом FSD; общий с приложением только `@aura/contracts`; оплата балансом с заготовкой под PSP

Date: 2026-10-20
Status: accepted (owner-ratified 2026-10-20)

## Decision

Веб-версия Aura — четвёртый deploy-unit: отдельный репозиторий
`RomSribn/aura-web` (ветка `develop`) и отдельный манор `aura-web-manor`, который
клонирует общий brain `aura-missus` — расширение `AURAD-0006`, а не его замена.
Стек — Vite + React 19 SPA + react-router, Redux Toolkit + RTK Query, CSS Modules
на переменных `tokens.css`, строгий FSD со слоем `pages`. С приложением на старте
общий только `@aura/contracts`. Оплата на запуске — с баланса; способы PSP
(карта, Apple Pay / Google Pay) заготовлены за флагом до выбора провайдера
(`AURAF-0009`).

## How it works

- **Манор** — как `aura-bff-manor`: brain вложенно в
  `project/manor/missus/aura-missus`, `PROJECT_PREFIX=AURA`. **AURA-ID минтятся
  только в `aura-app-manor/active-work.md`**; веб-манор исполняет спеки, у его
  задач префикс стороны `…-web-…` (как `app-` / `bff-`).
- **Правила сборки** — `.claude/aura-web-build-rules.md` в веб-маноре: те же пять
  hard rules `aura-build-rules.md`, переложенные на веб; FSD-направление слоёв
  проверяется линтером с первого дня.
- **Аккаунт** — Firebase JS SDK, вход по телефону в том же Firebase-проекте:
  тот же uid, общие чаты, сессии, кошелёк и оффер с приложением. SMS-код — 6 цифр.
- **Общий код** — `@aura/contracts` git-зависимостью с тем же тегом, что у
  app/bff. Чистая логика приложения (возвраты, оффер, слоты, форматтеры)
  переносится копией со ссылкой на источник; пакет `@aura/domain` — отдельным
  решением позже.
- **Заготовка под PSP** — `features/pay` на порту способа оплаты: `balance`
  живой, `card` (hosted page) и `wallet` (Payment Request) — на фейковом
  провайдере за `PSP_ENABLED`; маршрут возврата и «Still confirming…» с опросом
  готовы заранее. BFF и контракты до выбора провайдера не меняются: PSP ляжет
  как новый вид пополнения (`AURAD-0009`).
- **Этап 1** — Advisors (публичные) → Auth → Chat → Booking; этап 2 — Sessions,
  Profile, Top up, Daily card, `/match`.

## Why

- Один deploy-unit — один манор (`AURAD-0006`); у веба свой рантайм и каденс
  релизов (без ревью сторов).
- Монорепо отклонён в `AURAD-0006`; общий пакет логики требует рефакторинга
  RN-barrel'а в 74 файлах — дешевле подождать, пока станет ясен общий набор.
- PSP заблокирован юрлицом (`AURAI-0006`) — веб не должен ждать его, но и не
  должен переделываться, когда он появится.

Разбор и варианты — `AURAI-0007`. Спека — `AURAF-0020`.
