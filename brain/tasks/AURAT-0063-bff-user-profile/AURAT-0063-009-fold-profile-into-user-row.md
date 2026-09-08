# AURAT-0063-009 — Профиль свёрнут в строку пользователя

Дата: 2026-09-08
Повод: вопрос владельца при просмотре — «у нас что, теперь профайл таблица
отдельно от юзера?»

## Что было не так

Таблица всегда была одна — `users`, четыре колонки в неё же (`ALTER TABLE`, не
`CREATE TABLE`). Отдельным был **класс**: `ProfileRepository` +
`PrismaProfileRepository` в `modules/profile`, поверх той же таблицы, что и
`UsersRepository` в `modules/auth`.

Обоснование было такое: `UserRecord` читают `chat` и `chatwoot`, и незачем
разращивать форму личности данными профиля. Вопрос владельца попал в слабое
место этого рассуждения: **wallet, по образцу которого строилось, платит за
второй запрос по делу — у него своя таблица.** Здесь платить не за что.
`ensureUser` делает upsert и возвращает всю строку `users` целиком, то есть
профильные колонки уже в руках — а `getProfile` шёл за ними вторым `SELECT`.

## Что изменено

| Файл | Как |
|---|---|
| `modules/profile/profile.repository.ts` | **удалён** |
| `modules/profile/prisma-profile.repository.ts` | **удалён** |
| `modules/auth/users.repository.ts` | `UserRecord` + четыре поля; новый `ProfileUpdate`; метод `updateProfile` |
| `modules/auth/prisma-users.repository.ts` | `updateProfile`; конверсия `DATE` ↔ `YYYY-MM-DD`; явная проекция `toUserRecord` на всех трёх выходах |
| `modules/auth/users.service.ts` | делегирующий `updateProfile` |
| `modules/profile/profile.service.ts` | работает через `UsersService`; `NotFoundException` больше не нужен — `ensureUser` строку гарантирует |
| `modules/profile/profile.module.ts` | только контроллер и сервис |

**`GET /v1/me` стал одним запросом вместо двух.** Запись как была — `ensureUser`
плюс `UPDATE`; пустой патч теперь не ходит в базу вовсе.

Маршруты, контракты, миграция и OpenAPI **не изменились ни на строку** — это
перекладка слоя, а не смена поведения.

## Побочные правки

- `chatwoot/provisioning.service.spec.ts` — литерал `UserRecord` дополнен
  четырьмя полями. Ровно та цена, о которой шла речь: расширение общей формы
  задевает чужие тесты. Задело один, и в нём теперь написано, почему
  провижнинг эти поля не читает.
- `auth/users.service.spec.ts`, `auth/prisma-users.repository.spec.ts` —
  обновлены и дополнены.

## Новое в тестах

`PrismaUsersRepository.updateProfile` получил пять собственных тестов, и они
проверяют то, чего раньше не проверял никто: что дата уезжает в колонку
UTC-полночью и возвращается тем же ярлыком (`1994-05-21` → `Date` → `1994-05-21`),
что `null` стирает, что поле, которого нет в патче, не попадает в `UPDATE`, и что
пустой апдейт не пишет ничего.

## Проверено

`lint`, `typecheck`, `build` — чисто. `npm test` — **749 тестов в 54 наборах**,
все зелёные (было 743 до переделки: −8 тестов удалённого репозитория, +14 новых
в auth и profile).

## Дальше

Гейт 2 — разрешение владельца на коммит и `wts-finish slave-2`.
