# AURAT-0073-013 — Redeploy ушёл в production, а не в development

Дата: 2026-09-16

## Что показал лог, присланный владельцем

- `Starting deployment of RomSribn/aura-bff:main`, `COOLIFY_FQDN='bff.aura-app.cc'`,
  `COOLIFY_BRANCH='main'`, коммит `781957a` — это **production** `aura-bff`
  (ресурс `de0sra2t2v3utotwvpbnfcsc`), а не `development`.
- `Build step skipped` — тот же образ, что уже работал. Контейнер пересоздан с
  перекрытием, прод после этого отвечает 200. Код `781957a` про
  `ERASURE_JOURNAL_*` не знает, так что на прод это не повлияло: был только
  короткий перезапуск.
- `bff-dev` по-прежнему отвечает 503 (17:54Z). `develop` = `d54b07d`,
  `main` = `781957a`.

## Вывод

Скорее всего, и переменные попали в production `aura-bff`, а не в
`development`. Тогда:
- dev по-прежнему без переменных, поэтому новый контейнер `d54b07d` не
  проходит проверку окружения;
- в production лежит **dev-токен** `aura-erasure-journal`. После релиза в
  `main` прод писал бы удаления в dev-бакет, а окружения не должны делить
  бакеты и токены (`AURAD-0005`). Убрать до шага B.

## Находка про Coolify

В логе между `New container started` и `Removing old containers` меньше
секунды: rolling update **не ждёт**, пока новый контейнер станет здоров
(healthcheck не настроен). Поэтому dev и лёг: новый контейнер упал на
проверке окружения, а старый уже сняли. Фраза `AURAS-0004` «the new container
starts while the old one serves» создаёт ложное чувство защиты. Предложить
владельцу поправить документ после того, как dev поднимется и это
подтвердится.

## Дальше

Владелец проверяет, где лежат переменные: добавляет их в `development`,
убирает из `production`. Затем Redeploy именно dev.
