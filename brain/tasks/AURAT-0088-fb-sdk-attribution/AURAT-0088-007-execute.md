# AURAT-0088-007 — Реализация

Дата: 2026-10-14
Ветка: `feature/AURAT-0088-fb-sdk-attribution` (slave-0), не закоммичено,
всё застейджено.

## Что сделано

**Пакет:** `react-native-fbsdk-next` `13.4.3` (точно, без `^`); исходники в
`node_modules` сверены с прочитанным тарболом — идентичны. Нативный SDK
закреплён `ext.facebookSdkVersion = "18.3.0"` (`android/build.gradle`), вместо
плавающего `18.+`.

**iOS исключён:** `react-native.config.js` → `platforms.ios = null`.
`npx react-native config`: ios `None`, android `FBSDKPackage`. `ios/` в диффе
нет.

**Флаг `AURA_META_ATTRIBUTION_ENABLED`:** `env/resolve.js` (bool, `false`),
явно `false` во всех четырёх `.env.*`, тест «каждый флаг выключен в каждой
закоммиченной цели» расширен. Включён только в `aab:prod` / `apk:prod`
(`ios:archive:prod` — нет). Новый `env/flag.js` — Gradle читает флаг тем же
резолвером, что и Babel (с `.local`-слоем), а не `System.getenv`.

**Android:** `strings.xml` — App ID и Client Token; манифест — `meta-data`
ApplicationId / ClientToken, `AutoInitEnabled` / `AutoLogAppEventsEnabled` /
`AdvertiserIDCollectionEnabled` = `${metaAttributionEnabled}`
(`manifestPlaceholders` из `env/flag.js`); комментарий об AD_ID и
adservices-разрешениях и какие декларации они тянут;
`com.facebook.CustomTabActivity` удалена (`tools:node="remove"`) — по просьбе
владельца: экспортированная activity Facebook Login, который не используется.

**JS:** `shared/lib/attribution.ts` (no-op, контракт; iOS и Jest) и
`attribution.android.ts` (флаг, `try/catch`, валидация суммы/валюты),
экспорт из `@/shared`. Точки вызова:
- `use-create-account.ts` — `trackRegistrationCompleted()` после успешного
  `saveProfile`;
- `use-profile.ts` — `trackTopUpOpened()` в `useEffect` на
  `activeSheet === 'topup'` (оба входа);
- `use-store-topup.ts` — `trackPurchase({ creditedMinor, currency, sku })`
  после ответа BFF и `setBalance`, до `finishTransaction`, только при
  `!result.replayed`.

**Документация:** `env/README.md` — строка в таблице настроек и абзац о флаге.

## Отступление от спека

Спек (`005`, ветка B) предполагал старт SDK из JS (`Settings.initializeSDK()`).
Байткод `FacebookSdk` 18.3.0 показал: при `AutoInitEnabled=false` трекер
активностей всё равно стартует, а любой сетевой запрос до `fullyInitialize()`
бросает `GraphRequest can't be used when Facebook SDK isn't fully
initialized`. Отложенный старт рискует потерять установку и первый запуск —
то, ради чего задача. Поэтому стартом управляет манифест через флаг: в
prod-сборке SDK инициализируется штатно вместе с приложением. Для варианта A
это и нужно; путь к B (согласие) позже — переключить placeholder в `false` и
вызывать `initializeSDK()` после «да», с той же оговоркой про установку.

## Проверки

- `tsc --noEmit` — 0 ошибок; `eslint .` — 0; Prettier — новые файлы и мои
  правки чистые (остатки в `use-profile.ts`, `ProfileScreen.test.tsx`,
  `shared/index.ts`, `env/README.md` были и до задачи, не трогал).
- `jest` — 121 сьют, **851 тест, все зелёные**. Новые: 8 в
  `attribution.android.test.ts`, 4 в `use-store-topup` (сумма из BFF,
  `replayed` не шлёт, двойная доставка — одно событие, отказ BFF — нет
  события), по 1–2 в create-account и profile.
- `./gradlew assembleDebug` — **BUILD SUCCESSFUL** (25 мин, 4 ABI): bridge-модули
  пакета собираются на RN 0.85. APK 205 МБ (debug).
- Слитый манифест (debug): `AD_ID` + 4 × `ACCESS_ADSERVICES_*` присутствуют;
  три флага `false`; `CustomTabActivity` отсутствует. С
  `AURA_ENV=prod AURA_META_ATTRIBUTION_ENABLED=true` — три флага `true`.

## Не проверено (только после мёржа, на устройстве)

- Установка и события в Events Manager на prod-сборке из internal testing.
- Сумма покупки = запись журнала BFF.

## Шаги владельца вне кода (до production)

1. Meta App Dashboard → **выключить «Log in-app events automatically»**.
2. Политика `aura-app.cc/privacy/`: Meta в третьих лицах + способ отказа.
3. Play: Advertising ID → «да»; Data safety → shared: Device or other IDs,
   App interactions, Purchase history (Meta, Advertising/Analytics) — в той
   же отправке, что сборка 23+.
4. versionCode не поднимал — это шаг выпуска.

## Вне master-репо

`active-work.md` (воркспейс): счётчик `AURAD` → 0019, запись про `AURAD-0018`
— не застейджено, это репо воркспейса.
