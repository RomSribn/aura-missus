# AURAT-0141-007 — execute

Дата: 2026-10-25. Коммит `aura-app` `daf3d9a` на `feature/AURAT-0141-push-token-retry`.

## Что сделано

| Файл | Что |
|---|---|
| `features/push/model/push-registration.ts` | `getToken` → `registerDevice` без ожидания `requestPermission` (тот вызывается рядом, `.catch`); `AppState` `active` → повтор, если прошлая попытка не удалась или успех старше интервала; счётчик `session` — попытка ушедшего пользователя не помечает следующего и не блокирует его; одна попытка за раз |
| `features/push/config/constants.ts` | `TOKEN_REFRESH_INTERVAL_MS` = 12 ч |
| `model/__tests__/push-registration.test.tsx` (новый) | 7 тестов: зависший запрос разрешения; выход; повтор после сбоя PUT и `getToken`; нет повтора в интервале; повтор после интервала; нет второй параллельной попытки |

## Проверки

- Jest полный — 133 набора, 992 теста, зелёные; `tsc --noEmit` — 0; eslint `src/features/push` — чисто.
- prettier переформатировал импорт `devices-api` в правленом файле (был не по prettier и до правки).
- По пути: диск `/Volumes/Work` отключался, новый тест пропал — написан заново.
- В тесте интервала — `jest.setSystemTime`, а не `advanceTimersByTime`: 12 ч таймеров не завершаются.

## Дальше

- По желанию владельца — staging-APK на A50 до мёржа; иначе мёрж по merge gate и прод-сборка.
- Через неделю после релиза — повторный запрос «писали советнику за 7 дней без токена».
