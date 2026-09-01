# AURAT-0050-004 — Контекст и **проверенная** причина

Дата: 2026-09-01
Метод: не рассуждения о Prisma, а её собственный вывод — генерированный клиент
из `src/generated/prisma` подключён к **поддельному** драйвер-адаптеру
(`SqlDriverAdapter`), который ничего не исполняет, а записывает SQL. БД, Redis
и Chatwoot не участвуют: правило слейва соблюдено.

## Что на входе

`src/modules/auth/prisma-users.repository.ts`:

```ts
return this.prisma.user.upsert({
  where:  { firebaseUid: data.firebaseUid },
  create: { firebaseUid: data.firebaseUid, phoneE164: data.phoneE164 },
  update: { phoneE164: data.phoneE164 ?? undefined },
});
```

`AuthUser.phoneE164` приходит из гварда как `decoded.phone_number ?? null`
(`src/common/guards/firebase-auth.guard.ts:53`; ровно так же в WS-хендшейке,
`src/modules/delivery/chat.gateway.ts:46`). То есть **`null` — штатное
значение**, не экзотика: любой токен без клейма `phone_number` даёт его.

## Гипотеза владельца — уточнена, а не подтверждена

Гипотеза была: быстрый путь не выбирается потому, что в `update` нет
уникального поля `firebaseUid`, и Prisma требует его в обеих ветках.

Проверено на Prisma **7.8.0** (`@prisma/client` и `prisma` в образе — 7.8.0,
генератор `prisma-client`, адаптер `@prisma/adapter-pg`). Неверно: наличие
уникального поля в `update` роли не играет. Дело в том, **пуст ли `update`**.

### 1. `phoneE164` не `null` — быстрый путь, гонки нет

```
INSERT INTO "public"."users" ("id","firebaseUid","phoneE164","createdAt","updatedAt")
VALUES ($1,$2,$3,$4,$5)
ON CONFLICT ("firebaseUid") DO UPDATE SET "phoneE164" = $6, "updatedAt" = $7
WHERE ("public"."users"."firebaseUid" = $8 AND 1=1)
RETURNING …
```

Одна инструкция, без транзакции. Такой запрос P2002 по `users_firebaseUid_key`
дать не может: конфликт по этому индексу — это ровно та ветка, которую он
обрабатывает.

### 2. `phoneE164 === null` — `update` схлопывается в `{}`, путь медленный

`{ phoneE164: data.phoneE164 ?? undefined }` при `null` превращается в объект
без единого поля. `DO UPDATE SET` без присваиваний — невалидный SQL, и Prisma
уходит на find-then-create **внутри транзакции**:

```
BEGIN
SELECT "public"."users"."id" FROM "public"."users" WHERE ("firebaseUid" = $1 AND 1=1) OFFSET $2
INSERT INTO "public"."users" (…) VALUES (…) RETURNING "id"
ROLLBACK        ← когда INSERT упал на уникальном индексе
```

Вот и гонка, дословно та, что в маноре: два параллельных запроса оба видят
«строки нет» на `SELECT`, оба идут в `INSERT`, второму прилетает
`duplicate key value violates unique constraint "users_firebaseUid_key"` →
`PrismaClientKnownRequestError P2002` наружу из `upsert`.

Тёплый случай (строка уже есть) на этом же пути стоит транзакции и **трёх**
`SELECT` — на каждом аутентифицированном запросе, а `ensureUser` вызывается на
всех 14 точках.

### 3. Контроль

Если в `update` положить **любое** непустое поле — включая `firebaseUid`, —
Prisma снова компилирует нативный `ON CONFLICT`. То есть лечение, которое
предполагал владелец, работает, но по другой причине: важна непустота `update`,
а не уникальность поля в нём.

## Предсказание, проверяемое в маноре

Из (1) следует: манорский прогон получил P2002 **только если у ID-токена не
было клейма `phone_number`** (синтетический UID через custom token — типичный
случай). Если у токена телефон был, значит на живом стенде сработал ещё какой-то
путь, и это стоит увидеть. Лечение ниже закрывает оба случая, поэтому проверка
не блокирующая — но при прогоне в маноре на это стоит посмотреть.

## Идиома в проекте уже есть

`create` → `catch P2002` → перечитать существующую строку: карта дня
(`prisma-tarot.repository.ts:50`), сообщения (`prisma-messages.repository.ts:95`),
беседы (`prisma-conversations.repository.ts:52`), кошелёк
(`prisma-wallets.repository.ts:198`). До `users` она просто не дошла.

Правила сборки, которые здесь применяются: **#6 «Idempotency at the seams»**
(повтор/ретрай не создаёт дубля) и **#2 «Transport is thin»** (лечим в
репозитории, сервисы и 14 вызовов не трогаем).

## Следующий шаг

005 — спека: что именно меняем и почему так.
