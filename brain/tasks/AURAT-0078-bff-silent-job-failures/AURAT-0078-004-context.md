# AURAT-0078-004 — Что показал код

Дата: 2026-09-18
Ветка: `feature/AURAT-0078-bff-silent-job-failures` (от `develop` @ `1843a68`)

## Одиннадцать процессоров, один обработчик

`src/jobs/*.processor.ts` — одиннадцать классов, все `extends WorkerHost`:

| Процессор | Очередь | Попыток | Свой `logger` | `onFailed` |
|---|---|---|---|---|
| `ReconciliationProcessor` | `reconciliation` | **1** | **нет** | нет |
| `QueueRetentionProcessor` | `queue-retention` | 1 | есть | нет |
| `PresenceProcessor` | `presence` | 1 | нет | нет |
| `SessionsProcessor` | `sessions` | 5 | есть | нет |
| `AccountErasureProcessor` | `account-erasure` | 10 | есть | нет |
| `FcmFanoutProcessor` | `fcm-fanout` | 3 | нет | нет |
| `ChatwootWebhookProcessor` | `chatwoot-webhook` | 5 | нет | нет |
| `AvatarProcessor` | `avatar` | 5 | есть | нет |
| `ContactNameProcessor` | `contact-name` | 5 | есть | нет |
| `TarotProcessor` | `tarot` | 5 | нет | нет |
| `PlayRefundProcessor` | `play-refund` | 1 | есть | **есть** (`AURAT-0077`) |

Заглушка называла десять очередей; в коде их одиннадцать — `queue-retention`
и `contact-name` обе на месте, `reconciliation` действительно вообще без
логгера.

## Наследование `@OnWorkerEvent` работает — проверено по коду библиотек

Это главный вопрос развилки «базовый класс против одиннадцати копий», и ответ
не из документации, а из исходников в `node_modules`:

- `@nestjs/bullmq` → `bull.explorer.js`, `registerWorkerEventListeners`
  вызывает `metadataScanner.scanFromPrototype(instance, getPrototypeOf(instance), …)`.
- `@nestjs/core` → `metadata-scanner.js`, `scanFromPrototype` идёт по цепочке
  прототипов `do … while (prototype = Reflect.getPrototypeOf(prototype)) &&
  prototype !== Object.prototype` — то есть **видит методы базового класса**.
- `@OnWorkerEvent` — это `SetMetadata`, метаданные ложатся на саму функцию;
  `getOnWorkerEventMetadata(instance[key])` читает их через цепочку прототипов.
- Регистрация: `instance.worker.on(eventName, instance[key].bind(instance))` —
  привязка к конкретному экземпляру, общего состояния между процессорами нет.

**Вывод: базовый класс — рабочий вариант, а не надежда.** Одно ограничение,
которое надо закрыть тестом: если наследник **переопределит** `onFailed` без
своего декоратора, `instance[key]` разрешится в его метод — без метаданных, и
обработчик не зарегистрируется **вообще**. Молча. Ровно тот класс отказа, от
которого задача избавляется.

## `this.worker` в юнит-тесте бросает

`WorkerHost.worker` — геттер, который бросает, пока воркер не поднят. Значит
имя очереди в сообщение нельзя брать из `this.worker.name`: тест, который зовёт
`processor.onFailed(...)` напрямую (а именно так устроен образец в
`play-refund.processor.spec.ts`), упадёт. Имя очереди должно приходить иначе —
через `super(QUEUE)` или из имени класса.

## Логи — `nestjs-pino`, объект первым аргументом

`main.ts` → `app.useLogger(app.get(Logger))` из `nestjs-pino`. В `Logger.call`
первый аргумент-объект раскладывается в поля записи, последний optional-параметр
становится `context`. То есть `new Logger(ИмяКласса)` уже кладёт имя класса в
`context` каждой строки, а `this.logger.error({ jobName }, 'сообщение')` —
принятый в сервисе стиль (18 мест).

## `fcm-fanout` бросает **намеренно**

`FcmFanoutProcessor.process` при частичной доставке сужает `job.data.tokens` до
не доставленных и **бросает**, чтобы BullMQ назначил повтор. Обработчик падений
«всё в `error`» превратил бы штатный повтор в три строки уровня `error` на
каждый частично доставленный пуш. Значит уровень должен зависеть от того,
последняя ли это попытка.

## Ошибки самого воркера почти так же молчаливы

`bullmq/queue-base.js` `emit()`: если на `'error'` нет слушателя, `EventEmitter`
бросает, библиотека ловит, пробует ещё раз и в итоге делает `console.error(err)`
— сырая строка мимо pino, без `context`, без структуры. Обрыв Redis, ошибка
планировщика повторяемых задач приходят именно туда.

## Что уже закреплено в репозитории

- `TECH-DEBT.md` #31 — эта задача, со сформулированной развилкой.
- `queues.spec.ts` — готовый образец «сторожевого» теста: очередь, заведённую и
  забытую в `allQueueOptions`, валит тест, а не эксплуатация. Такой же сторож
  нужен процессорам.
- `play-refund.processor.spec.ts` — образец теста на обработчик: зовётся, пишет
  имя задачи и текст ошибки, `JSON.stringify(calls)` **не содержит** токена,
  переживает событие без `job`.

## Противоречий между источниками нет

Заглушка, `TECH-DEBT` #31 и код говорят одно и то же. Единственная поправка —
число очередей: одиннадцать, не девять и не десять.
