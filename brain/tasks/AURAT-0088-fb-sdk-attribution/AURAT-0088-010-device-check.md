# AURAT-0088-010 — Проверка на устройстве (промежуточно)

Дата: 2026-10-14

Сборка `23 (1.0.2)` в internal testing, Samsung A50 (Android 11), установлена
из Play. Тестовым аккаунтом (уже с именем) — вход и три покупки по $25.

## Подтверждено

- **Test events** (реальное время, устройство «Роман's device»):
  `fb_mobile_purchase`, `_valueToSum: 25`, `fb_content_id: aura.topup.usd25`;
  `fb_mobile_initiated_checkout`; `fb_mobile_activate_app` (автоматически).
- **Overview** за 2026-10-14: App installs 1, Activate app 3, Purchase 1,
  Initiate checkout 1, интеграция «Facebook SDK», «last received ~20 min ago».
- `adb`: при холодном старте приложение ходит ровно на `157.240.5.12`
  (`edge-star-shv-01-mad2.facebook.com`) и BFF; ошибок SDK в logcat нет.
- Complete Registration не отправлялось — верно: аккаунт не новый,
  экран создания аккаунта не показывался.
- Дедупликация SDK (`InAppPurchaseManager.performDedupe`) по байткоду только
  помечает ручную покупку, совпавшую с автоматической, а не отбрасывает;
  автологирование покупок в консоли выключено.

## Не подтверждено пока

Purchase = 3 (три покупки). Overview застыл на ~21:00 по **всем** событиям:
Activate app тоже 3, хотя после 21:00 было не меньше трёх холодных
запусков. Это задержка агрегации Meta, а не потеря покупок. Перепроверить
Overview позже: ожидаем Purchase 3 / $75, Activate app > 3.
