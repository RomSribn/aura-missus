# AURAT-0088-011 — Политика приватности: Meta

Дата: 2026-10-14
Статус: **опубликовано владельцем и сверено**

## Что было неправдой

§02 «Technical data»: «Aura contains no advertising, analytics or crash
reporting software and does not use an advertising identifier» — ложно с
1.0.2 (23) на Android.

## Что опубликовано (текст предложен, владелец внёс)

| Раздел | Правка |
|---|---|
| Last updated | `14 October 2026` |
| §02 Technical data | фраза заменена: Meta SDK на Android для измерения рекламы; аналитики и crash reporting нет; iOS не использует рекламный ID |
| §02 новый подраздел | «Advertising measurement (Android)»: рекламный ID, установка/запуск, три события (профиль, Top Up, покупка, подтверждённая сервером — сумма, валюта, продукт); не передаются имя, телефон, email, сообщения, файлы, ID аккаунта; iOS ничего не шлёт |
| §03 | строка: измерение рекламы (Android) — Legitimate interests, право возразить (`AURAD-0018`) |
| §05 | Meta Platforms после Google Play: joint controllers (Meta Platforms Ireland Limited + Silvermind OÜ) по Business Tools Terms |
| §06 | Meta в списке провайдеров вне ЕЭЗ |
| §08 | отказ: удалить/сбросить рекламный ID в настройках Android; возражение — privacy@aura-app.cc |

Сверено по живой странице `aura-app.cc/privacy/` (бандл разобран, текст
сличён): все шесть правок на месте, старой фразы нет.

## Оговорки, озвученные владельцу

- Возражение по письму технически нечем исполнить: в приложении нет
  переключателя, отключающего SDK для конкретного человека. Реальный
  механизм — сброс рекламного ID на устройстве. Если письмо должно
  действительно что-то выключать — отдельная задача (переключатель в Edit
  Profile).
- «Joint controllers» — по стандартной схеме Meta (Controller Addendum);
  сверить с актуальной редакцией условий в Business Manager.

## Осталось до production

Play: Advertising ID «да» + Data safety (shared: Device or other IDs, App
interactions, Purchase history → Meta) — в той же отправке, что 23 в
production. Overview: Purchase = 3.
