# AURAT-0088-012 — Декларации Play переподаны, 23 на ревью

Дата: 2026-10-14
Статус: **отправлено на ревью Google** (владелец)

## Что заявлено

**App content → Advertising ID:** «Yes», цели Analytics + Advertising or
marketing. **Ads:** по-прежнему «No» (рекламы в приложении нет).

**Data safety** — изменены три типа, остальное без изменений:

| Тип | Было | Стало |
|---|---|---|
| Device or other IDs | collected, required | collected + **shared**; + Analytics, Advertising or marketing (сбор и передача) |
| App interactions | collected, optional | collected + **shared**, **required**; + Analytics, Advertising or marketing |
| Purchase history | collected, optional | collected + **shared**, optional; + Analytics, Advertising or marketing |

Shared — только эти три (получатель Meta, использует в своих целях).
Остальные типы — только collected: Firebase, Hetzner, Cloudflare, Resend —
поставщики от нашего имени; отзывы — user-initiated. Это не «sharing» по
определению Google.

**Production:** релиз `23 (1.0.2)` из библиотеки, release notes en-US (вариант
с упоминанием измерения рекламы и ссылкой на политику).

Отправлено одной отправкой: Advertising ID + Data safety + production 23.

> **Поправка 2026-10-14, по данным Play.** Так не вышло. Submission activity
> показывает заявку **3 от 14 октября 21:54 с единственным изменением —
> `App content → Data safety`**. Ни production-релиза, ни отдельной строки
> `Advertising ID` в ней нет, и владелец подтверждает: сборку `23` загружали
> **только в internal testing**.
>
> Что из этого следует:
> - **`23 (1.0.2)` в магазин не поехала.** В production опубликована `1.0.1`
>   (заявка 2 от 13 октября). Значит у пользователей SDK нет, и реклама
>   сообщать о себе не может.
> - Продвигать `23` надо отдельно: Test and release → Testing → Internal
>   testing → релиз с `23` → **Promote release** → Production. Пересобирать
>   не нужно, уходит тот же файл.
> - **Порядок:** сначала дождаться заявки 3, потом продвигать. Изменение,
>   добавленное поверх идущей проверки, отправляет её на новый круг — на этом
>   проект уже обжигался дважды.
> - **Проверить `App content → Advertising ID`.** Отдельной строки в заявке
>   нет, то есть ответ либо внутри анкеты Data safety, либо не сохранился.
>   Если в сборке есть разрешение `AD_ID`, а в декларации «нет» — Google
>   снимает приложение с публикации.

## Состояние критериев приёмки (`001`)

| Критерий | Состояние |
|---|---|
| Установка видна в Events Manager | ✓ App installs 1 (2026-10-14) |
| Покупка с суммой журнала BFF, ровно один раз | частично: параметры ✓ (25, USD, `aura.topup.usd25`); счёт 3 = 3 — ждём агрегацию Overview |
| Data safety переподана | ✓ отправлено на ревью |
| Meta в политике приватности | ✓ `011` |
| iOS не тронут | ✓ ни пода, ни ATT, ни App Privacy |

## Дальше

- Решение Google по ревью → при Managed publishing нажать Publish.
- Overview: Purchase = 3. Затем — закрытие задачи (коммит missus, release).
