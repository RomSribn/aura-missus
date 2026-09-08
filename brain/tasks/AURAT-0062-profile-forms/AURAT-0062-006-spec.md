# AURAT-0062-006 — Спека клиентской половины

Дата: 2026-09-08
Статус: **одобрена 2026-09-08**, решения §8 закрыты — см. `AURAT-0062-007-approval.md`
Репозиторий: **aura-app**, ветка `feature/AURAT-0062-profile-forms`
Фича: `AURAF-0015` · сервер: `AURAT-0063` (делать **до** мержа этой)

---

## 1 · Два экрана и один набор атомов

**Create Account** — ворота. Открывается `reset`-ом сразу после проверки кода,
если у аккаунта нет имени. Ни шапки, ни стрелки назад, ни «Skip for now».
Аппаратная «назад» на Android выходит из приложения, как с Home, — потому что
под экраном ничего нет, а не потому, что кнопку глушили.

**Edit Profile** — пуш из вкладки Profile по тиловой кнопке «Edit». Шапка со
стрелкой, таб-бар скрыт. Нижний шит `EditProfileSheet` удаляется целиком.

Оба собраны из одних атомов; атомы пишутся один раз.

## 2 · Где что живёт (FSD)

### `shared`

| Файл | Что |
|---|---|
| `shared/lib/birth-date.ts` | **переезд** из `entities/horoscope/lib/`: `BIRTH_DATE_DIGITS`, `birthDateParts`, `maskBirthDate`, `toIsoBirthDate` + `MIN_BIRTH_YEAR` из `horoscope/config/signs.ts`. Плюс две новые чистые функции: `formatBirthDateDigits(digits) → 'DD.MM.YYYY'` и `birthDateDigitsFromIso('YYYY-MM-DD') → digits` — экран правки показывает уже сохранённую дату, чего у гороскопа не было. Тесты (`__tests__/birth-date.test.ts`, 20 штук) переезжают вместе с файлом |
| `shared/lib/email.ts` | `isValidEmail(value)` — одна чистая функция, не бизнес-логика (правило `lib/`) |
| `shared/ui/form-field/FormField.tsx` | белая карточка r16, рамка 1.5px `line` → `accent` в фокусе (150 мс), eyebrow-лейбл 10.5 над значением 16/600; пропсы `locked` (read-only, `opacity .6`) и `right` (хвостовой слот) |
| `shared/ui/form-field/DobField.tsx` | тот же корпус; значение — Bricolage 16/700 `letterSpacing .04em`, плейсхолдер `DD.MM.YYYY`, хвост — плитка 36 r11 `paper2` с иконкой `cal`. Маска — `maskBirthDate` из `shared/lib` |
| `shared/ui/form-field/Toggle.tsx` | 52×31, кнопка 25 белая, трек `line2` → `teal`, `translateX 21`, 200 мс `cubic-bezier(.22,1,.36,1)`, `accessibilityRole="switch"` |
| `shared/ui/form-field/OptInRow.tsx` | карточка с текстом согласия + `Toggle` |
| `shared/ui/orb/ProfileOrb.tsx` | фирменный орб как аватар по умолчанию + вариант `empty` (диск `paper2`, рамка `line`, иконка `user` в `ink3`). Рядом с существующим `PulsingOrb` |

Все размеры и цвета — токены `shared/config/theme.ts`; из `rn/theme.ts`
дизайнера берутся только числа (жёсткое правило 3).

### `entities/user`

| Файл | Что |
|---|---|
| `model/types.ts` | `Profile { displayName, email, birthDate \| null, phoneE164, marketingOptIn }` — `birthDate` в ISO `YYYY-MM-DD`, как на сервере; `DD.MM.YYYY` существует только на экране |
| `api/schema.ts` | zod-схема ответа `/v1/me` |
| `api/profile-api.ts` | `fetchProfile()`, `patchProfile(partial)` |
| `model/profile-store.ts` | модульный стор ровно той же формы, что `wallet-store` / `horoscope-store`: `subscribe / getState / load / patch / reset`. Идентити-скоупная серверная сущность, живёт дольше экрана, сбрасывается при выходе |
| `model/use-profile.ts` | `useSyncExternalStore` поверх стора |
| ~~`ui/PhotoRow.tsx`~~ | **не в этой задаче** — вынесено в `AURAT-0064` вместе с хранением файла (решение **D4**) |
| ~~`config/constants.ts`~~ | **удаляется** вместе с `'Vasya'` |
| ~~`model/get-display-name.ts`~~ | **удаляется**: имя приходит из стора |

`profile-store.reset()` встаёт рядом с `horoscopeStore.reset()` / `walletStore.reset()`
на выходе из аккаунта — иначе следующий вошедший увидит чужое имя.

### `screens`

- `screens/create-account/` — `ui/CreateAccountScreen.tsx`, `model/use-create-account.ts`, `config/copy.ts`, `index.ts`
- `screens/edit-profile/` — `ui/EditProfileScreen.tsx`, `model/use-edit-profile.ts`, `config/copy.ts`, `index.ts`
- `screens/profile/` — `EditProfileSheet.tsx` **удаляется**; `ProfileSheetKey` теряет `'edit'`; `ProfileCard` берёт `ProfileOrb` вместо `Avatar`, показывает `name || 'Add your name'`, «Edit» пушит экран
- `screens/home/ui/BirthDateSheet.tsx` — импорты маски переезжают на `@/shared`; сохранение идёт через `profileStore.patch`, чтобы дата с Home и дата из профиля не разъехались

### `app` / `shared/config/navigation.ts`

- `SCREENS.CREATE_ACCOUNT` — маршрут **корневого стека**. Так «без навигации»
  получается само: под ним ничего нет, шапки у корневого стека нет
- `SCREENS.PROFILE_ROOT` + `SCREENS.EDIT_PROFILE` — новый `ProfileStackNavigator`
  по образцу `ChatsStackNavigator`; `EDIT_PROFILE` добавляется в
  `TAB_BAR_HIDDEN_ROUTES` у `AuraTabBar`
- `shared/lib/navigation.ts` — новая `enterAccountSetup(navigation)` рядом с
  `enterApp` / `leaveApp`: `reset({ index: 0, routes: [{ name: CREATE_ACCOUNT }] })`

## 3 · Ворота: как приложение узнаёт, что имени нет

`use-verify-otp` после `authService.verifyOTP(code)`:

```
profileStore.load()            // GET /v1/me
  → есть displayName  → enterApp(navigation)
  → нет displayName   → enterAccountSetup(navigation)
```

Читается **сервер**, не устройство: имя должно быть тем же на втором телефоне и
после переустановки. Пока `AURAT-0063` не влит, `GET /v1/me` отвечает 404 —
поведение при этом описано в решении **D1**.

Обратный путь один: `Continue` → `PATCH /v1/me` → `enterApp`.

## 4 · Валидация

| Поле | Правило | Когда говорим |
|---|---|---|
| Имя | обязательное, `trim().length > 1` | кнопка серая, ошибку не пишем — поле пустое, а не неверное |
| Емейл | необязательное; если непустое — `isValidEmail` | после `blur`, а не на каждой букве |
| Дата рождения | необязательная; маска не даёт набрать невозможное; ошибка — только когда набраны все 8 цифр и `toIsoBirthDate` вернул `null` | строкой под полем, как в `BirthDateSheet` |
| Телефон | не редактируется | иконка `lock` |

Неверный емейл или дата **блокируют** `Continue` / `Save changes`: пустое поле
и неверное поле — разные вещи, и второе нельзя молча проглотить.

## 5 · Дата рождения → гороскоп

Дата, введённая на любом из двух экранов, уезжает тем же `PATCH /v1/me`, что и
у гороскопа. После успешного ответа — `horoscopeStore.load(true)`, и знак
появляется на Home без второго вопроса. Один вызов, один маршрут, никакой второй
даты рождения в системе.

## 6 · Моторика (`PROFILE_FORMS.md` §5)

Вход экрана `translateY 12→0` + `opacity 0→1`, 320 мс. Фокус поля — цвет рамки
150 мс. Тумблер — 200 мс. Разблокировка кнопки — `opacity .4→1`, 150 мс. Орб
из `empty` в фирменный — кросс-фейд ~200 мс на первом введённом символе.
Всё на `Animated` с `useNativeDriver` там, где это трансформ или прозрачность
(цвет рамки и трека — `false`, как в порте дизайнера).

## 7 · Тесты

Обязательные, по образцу `BirthDateSheet.test.tsx` и `ProfileScreen.test.tsx`:

1. `Continue` заблокирован при пустом имени и при имени из одного символа.
2. `Continue` заблокирован при непустом неверном емейле; разблокирован, когда
   емейл очищен.
3. Неполная дата ошибку не показывает; полная невозможная (`31.04.1994`) —
   показывает и блокирует.
4. `Save changes` мёртв, пока ничего не изменилось; оживает после правки; снова
   мёртв, если вернуть значение обратно.
5. Заблокированный телефон не редактируется.
6. Ворота: `displayName` пуст → `reset` на `CREATE_ACCOUNT`; непуст → `MAIN`.
7. `profile-store`: `reset` роняет состояние; ответ от предыдущей личности не
   приземляется (та же проверка `generation`, что в `wallet-store`).
8. Переехавшие тесты `birth-date` зелёные на новом месте.
9. `ProfileScreen` рисует `Add your name` при пустом имени.

## 8 · Решения (закрыты 2026-09-08)

**D1 — порядок половин → сервер первым.**  `AURAT-0063` строит
`GET/PATCH /v1/me`, потом эта задача мёржится. Иначе экран соберёт емейл и
согласие, а деть их будет некуда: мёрж в `develop` — это деплой.
*Альтернатива, если хочется ворота раньше сервера:* урезанный режим — на
`Create Account` только имя (пишется в Firebase `displayName`), емейл, дата и
согласие спрятаны до появления маршрута. Это лишний временный код, но он честен.

**D2 — длина имени → `> 1 символа`,** как у дизайна. Если владелец хочет
пускать односимвольные имена — скажите, правка в одну строку.

**D3 — согласие на рассылку по умолчанию.** Дизайн: **включено**. Для GDPR/
ePrivacy предвыбранная галочка согласия — слабое место (согласие должно быть
активным действием). Формально это решение владельца и юридический, а не
технический вопрос; техника одинаковая. **Решено: включено,** как рисует дизайн — рекомендация выключить отклонена
владельцем. В базе умолчание колонки остаётся `false` (`AURAT-0063`): строка,
созданная до вопроса, согласия не выражает, а экран всегда шлёт явное значение.

**D4 — «Change photo».** Хранить фото негде (см. `AURAF-0015`, «не в объёме»).
**Решено: кнопка не рисуется, работа вынесена в `AURAT-0064`.** Аватаром
остаётся орб (и его `empty`-вариант). `PhotoRow` в этой задаче не строится —
он приезжает вместе с хранением файла.

**D5 — плитка календаря → фокус в поле.** Нативный date picker не берём (`AURAT-0044`). Плитка
остаётся, но по нажатию **ставит фокус в поле** и поднимает клавиатуру — то
есть делает ровно то, на что похожа, без нового нативного модуля.

## 9 · Что удаляется

`entities/user/config/constants.ts`, `entities/user/model/get-display-name.ts`,
`screens/profile/ui/EditProfileSheet.tsx`, вариант `'edit'` в `ProfileSheetKey`,
`entities/horoscope/lib/birth-date.ts` (переезжает), экспорт четырёх функций
даты из `entities/horoscope/index.ts`.

## 10 · Проверка перед показом

`npx tsc --noEmit`, `npm run lint`, `npm test` (сейчас на `develop` 635 тестов —
должно стать больше и остаться зелёным). Стек в слейве не поднимаем: поведение
на устройстве проверяется в маноре после мержа.
