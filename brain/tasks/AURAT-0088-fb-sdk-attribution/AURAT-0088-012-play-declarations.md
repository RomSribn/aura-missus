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
