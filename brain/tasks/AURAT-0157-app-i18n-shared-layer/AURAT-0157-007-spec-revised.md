# AURAT-0157-007 — spec revised (draft)

Тип: задача фичи `AURAF-0023`, шаг 2, **часть A — строки и структура** (решение владельца 1 в `006`). Форматтеры
(часть B) — `AURAT-0159`. Только `aura-app`; флаг `AURA_I18N_ENABLED` выключен — в релизе всё английское.
Английский текст не меняется, кроме тела пуша (решение 2). Отличия от `005` — по правкам `006`.

## Что меняется

1. **Общие фразы — пространство `shared`** (24 языка; память веба — `translate.mjs scan`):
   - `goBack` «Go back», `tryAgain` «Try again», `connection.comeBack` «Check your connection and come back in a
     moment.», `error.generic` «Something went wrong. Please try again.», `ok` «OK»; «Close» уже есть;
   - **`BackButton`** (`shared/ui/back-button`): `CircleButton` + иконка `back` + переведённый
     `accessibilityLabel`, размеры 40 / 44 → иконка 20 / 22 — заменяет 13 копий в 11 экранах; где кнопка устроена
     иначе (daily-card) — тот же ключ через `t`;
   - точные совпадения переходят на ключи: «Try again» ×4 (константы `RETRY_LABEL`, `HOROSCOPE_RETRY_LABEL`,
     `RETRY` удаляются), «Check your connection and come back…» ×3;
   - `Alert.alert` без кнопок (`use-profile.ts` «Sign out failed», `use-session-detail.ts` «Session cancelled») —
     явная кнопка `[{ text: t('ok') }]`, иначе Android рисует английское «OK». Сами тексты алертов — шаг 3.
2. **`SegmentedControl`** — `options: readonly { value: T; label: string }[]`:
   - значения машинные: advisors `'all' | 'online' | 'topRated'`, sessions `'upcoming' | 'past'`, home
     `'today' | 'tomorrow'`; сравнения в `filter-advisors.ts`, `use-advisors.ts`, `SessionsScreen.tsx`,
     `use-home.ts` — по ним;
   - подписи через `t`: пространства `advisors` и `sessions` (пока только подписи сегментов), home — `shared`
     `day.today` / `day.tomorrow`;
   - **вёрстка**: в компоненте `numberOfLines={1}` + `adjustsFontSizeToFit` (`minimumFontScale` 0.8); на ключах
     `@max` по ширине ячейки — 3 сегмента ≈ 98pt → `@max 14`, 2 сегмента ≈ 160pt → `@max 22` (13,5px Hanken
     SemiBold, экран 390pt); переводы подбираются под лимит («Parhaiten arvioidut» → короче).
3. **`AuthError` хранит код**: `new AuthError(code, cause)`, `message` = код (для логов).
   - `authErrorKey(code)` в `shared/api/firebase` → ключ `auth.*` в `shared` (12 фраз `handleAuthError`, английский
     дословно); неизвестный код → `error.generic`;
   - phone-auth и verify-otp держат в состоянии ошибку и переводят при рендере; литерал `use-phone-auth.ts:188` →
     `error.generic`.
4. **Пуши и каналы Notifee** (`features/push`) — пространство `push`:
   - каналы «Messages» / «Announcements», запасной заголовок «Your advisor»;
   - **тело — «New message»** (было «sent you a new message»), заголовок — имя консультанта (решение 2);
   - headless: показ пуша и создание канала ждут `i18nReady()`;
   - Android: при `languageChanged` оба канала пересоздаются с тем же id и новым именем.
5. **SMS**: `auth().setLanguageCode(currentLanguage())` прямо перед `verifyPhoneNumber`; в моке
   `@react-native-firebase/auth` (`jest.setup.js`) — `setLanguageCode`.
6. **Таб-бар** (`app/navigation/AuraTabBar.tsx`): у пяти кнопок — `accessibilityLabel` (Home, Chats, Advisors,
   Sessions, Profile) из пространства `app` (`src/app/config/locales`, в реестре).
7. **Линтер**: новых путей нет. `shared/ui/**` уже `error` (покрывает `BackButton` и `SegmentedControl`); в
   `features/push` и `shared/api/firebase` JSX нет, а режим `all` там — сплошь id, коды и логи. Их защищают тесты
   из п. 8 (текст на de ≠ английскому).
8. **Тесты**: полнота и `@max` новых пространств (существующие тесты); `BackButton` (метка на de); сегменты (значение
   ≠ подпись, подпись на de, фильтрация по значению); `authErrorKey` (все коды + неизвестный); push на de (заголовок,
   тело, канал), ожидание `i18nReady`, пересоздание каналов; `setLanguageCode` до `verifyPhoneNumber`; таб-бар —
   метки. Существующие английские ожидания не меняются, кроме тела пуша.

## Не входит

- Форматтеры, даты, деньги — `AURAT-0159`. Строка Language и лист — `AURAT-0158`.
- Остальные строки слайсов — шаг 3. Файлы `AURAT-0156`.

## Открыто (для `AURAT-0159`, на ход A не влияет)

**Английская дата.** Совет: **en-GB для дат и времени, en для денег** (вариант владельца). Шапку Home собрать из
двух кусков CLDR — день недели и «число месяц» — через « · » из дизайна: en «WEDNESDAY · 4 NOVEMBER» как в макете, а
в любом языке обе части остаются правильными по CLDR (lt «trečiadienis · lapkričio 4 d.»). Бронь — «Friday 14
August». Цена: короткий сентябрь в en-GB — «Sept» (4 буквы в календарных блоках). US-порядок везде ломает
нарисованную шапку и плохо вяжется с 24h.

## Проверка

- **Slave:** `npm run lint` (0 / 0), `npx tsc --noEmit`, `npx jest --no-watchman`, `translate.mjs check` по
  `shared`, `advisors`, `sessions`, `push`, `app`.
- **Манор, dev-сборка, «i18n: next language» на de / fi / pl / el / псевдоязыке:** «назад» и таб-бар читаются
  TalkBack/VoiceOver на языке; сегменты не обрезаны и фильтруют; ошибка неверного кода на языке; пуш в фоне
  (Android) — «New message» на языке, имя канала в настройках меняется после смены языка; SMS на реальный номер
  после смены языка.
