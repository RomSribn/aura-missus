# AURAT-0062-002 — Что уже есть в brain и в коде

Дата: 2026-09-08

## В brain

Папки под профиль/личные данные **нет**. Ближайшие соседи:

- `tasks/AURAT-0039-bff-horoscope-birth-date/` — шов даты рождения. Пять
  файлов, последний от 2026-08-25. Ключевое для нас в `004` и `005`:
  маршрут `PATCH /v1/me` спроектирован **write-only** намеренно (правило 8 —
  нет читателя, нет `GET`), а **серверная половина не начата**.
- `tasks/AURAT-0041-app-release-stubs-and-horoscope/` — половина приложения
  того же шва; влита, живёт в `screens/home` + `entities/horoscope`.
- `features/AURAF-0014-advisor-reviews/` — свежий образец формы «фича + две
  половины» (`AURAT-0058` сервер → `AURAT-0059` клиент, строго в этом порядке).

Совпадений по ключевым словам profile / create account / personal data —
ничего. Задача заводится с нуля.

## В коде приложения

Что есть сегодня, проверено чтением, а не документацией:

| Что | Где | Состояние |
|---|---|---|
| Имя пользователя | `entities/user/model/get-display-name.ts` | `authService.getCurrentUser()?.displayName ?? 'Vasya'` — дизайнерская заглушка из `config/constants.ts` |
| Правка профиля | `screens/profile/ui/EditProfileSheet.tsx` | нижний шит, только имя + заблокированный телефон; дизайн его **удалил** |
| Сохранение имени | `screens/profile/model/use-profile.ts:saveDisplayName` | пишет в Firebase `updateProfile({ displayName })` |
| Дата рождения | `entities/horoscope/lib/birth-date.ts` | маска, календарная проверка, `DDMMYYYY → YYYY-MM-DD`; 20 тестов |
| Ввод даты рождения | `screens/home/ui/BirthDateSheet.tsx` | три «коробки» + невидимый `TextInput` под ними |
| Запись даты | `entities/horoscope/api/horoscope-api.ts:putBirthDate` | `PATCH /v1/me { birthDate }` |
| Вход в приложение | `shared/lib/navigation.ts:enterApp` | `reset` на один маршрут `MAIN` из `use-verify-otp` |
| Емейл | — | нигде не собирается и не хранится |
| Согласие на рассылку | — | нет |

## На сервере (`aura-bff`, ветка `develop`)

Проверено в `project/manor/master/aura-bff`:

- контроллера `me` **нет** ни одного; `grep` по `'/v1/me'`, `birthDate`,
  `horoscope` в `src/` — пусто;
- в `prisma/schema.prisma` модель `User` держит `firebaseUid`, `phoneE164`,
  чатвутовские идентификаторы и связи — **ни имени, ни емейла, ни даты
  рождения, ни согласия**.

То есть `putBirthDate` сегодня стучится в маршрут, которого нет, и это
предусмотрено: 404 переводит гороскоп в терминальное `disabled`. Личным данным
такой исход не годится — отсюда вторая половина задачи, `AURAT-0063`.
