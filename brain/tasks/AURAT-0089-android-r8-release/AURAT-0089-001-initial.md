# AURAT-0089-001 — R8 для release-сборки Android (и edge-to-edge)

Дата: 2026-10-14
Статус: **заведена**, не начата, слэйв не назначен
Репозиторий: `aura-app`
Повод: владелец заметил в Play Console при выпуске `23 (1.0.2)` (`AURAT-0088`)
две пометки на бандле `22 (1.0.1)`.

## Что пишет Play

**1. Issue — «DEX code optimization is below our threshold», fix by Feb 2027.**
App bundle explorer для `22.aab`: DEX optimization **Low**, Optimization —,
**Obfuscation 2%**, Shrinking —, R8 configuration — («Upgrade to AGP 9.0 and
use R8»), total uncompressed DEX **38.7 MB**. Метки: Memory usage, Bad
behavior. Play: ниже 25% в любой категории может повлиять на видимость и
возможность публикации.

**2. Recommended — «Your app uses deprecated APIs or parameters for
edge-to-edge»** (User experience). Конкретные классы в Play — раскрыть
рекомендацию и записать на старте задачи.

## Что известно

- `android/app/build.gradle`: `enableProguardInReleaseBuilds = false` — R8
  выключен намеренно со старта проекта; отсюда же предупреждение Play «no
  deobfuscation file» (`AURAT-0087-011`), `mapping.txt` не создаётся.
- Target SDK 36 → edge-to-edge принудителен; устаревшие вызовы, вероятно, из
  RN / библиотек (`StatusBar`, `react-native-screens`), не из нашего кода —
  проверить.
- Сборка 23 (Meta SDK, `AURAT-0088`) добавила `facebook-android-sdk` целиком
  — DEX стал больше; R8 его ужмёт.

## Что сделать

1. Включить R8 (minify + shrink resources) для release; при необходимости —
   keep-правила для кода, находимого рефлексией: мосты RN / TurboModules,
   Nitro (`react-native-nitro-modules`, `react-native-iap`), Firebase,
   Notifee, Meta SDK, `@aura/contracts` (zod — JS, не затронут).
2. Убедиться, что `mapping.txt` попадает в загрузку Play (деобфускация
   стектрейсов).
3. Edge-to-edge: найти источник устаревших API по деталям рекомендации;
   обновить библиотеку или убрать вызов.

## Чем считать сделанным

- В App bundle explorer у новой сборки DEX optimization не Low, все
  категории ≥ 25%, issue снят.
- Release-сборка с R8 проверена на устройстве по полному кругу: вход по
  телефону, чат и вложения, пуши, бронирование, покупка через Play, события
  Meta в Test events, удаление аккаунта. Стек вызова краша читаем в Play.
- Рекомендация edge-to-edge снята или объяснено, почему её источник вне
  нашего контроля.

## Границы

- iOS не касается.
- AGP 9 — только если без него R8 не даёт нужного; иначе отдельно.
- Срок Play — февраль 2027; не горит, но проверка на устройстве долгая.
