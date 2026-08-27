# AURAT-0040-013 — Карта правок по разделам, обоих документов

Дата: 2026-08-28
Дополняет: `007` (список расхождений) и `012` (поправка про имя)
Поднято: `slave-0` заметил, что «crash diagnostics» стоит и в §05, а не только в
§02. Проверка этого превратилась в полный проход, и он нашёл больше.

## Зачем отдельный документ

`007` называл **первое** место каждого расхождения. Этого мало: одно
расхождение живёт в двух-семи разделах, и правка одного раздела оставляет
остальные говорить обратное. Плюс — `007` разбирал **только политику**. Terms не
аудировался вовсе, а там те же утверждения.

**Счёт не меняется: расхождений по-прежнему десять.** Меняется длина карты
правок — она длиннее списка расхождений, и это разные вещи.

## Главное, что нашёл полный проход

**Обещание удаления аккаунта стоит в СЕМИ местах, в двух документах.** `007`
называл два.

| Документ | Раздел | Формулировка |
|---|---|---|
| Privacy | §07 | «deleted with the account, or earlier if you delete a conversation» |
| Privacy | §08 | «you may ask us to … delete it» |
| Privacy | §08 | «You can delete your account from the app's profile screen» |
| Privacy | §11 | «we will close the account and erase the data» (о несовершеннолетних) |
| **Terms** | **§02** | «If we learn that an account belongs to a minor, we close it and delete the data» |
| **Terms** | **§04** | «You can delete your account at any time from the profile screen in the app» |
| **Terms** | **§12** | «You may stop using Aura and delete your account whenever you like» |

Ни одного механизма под это нет: единственный `@Delete` в сервисе отзывает
push-токен. Terms §04 формулирует прямее всех из семи.

**Персона над общим столом — третье место.** `007` называл Privacy §05. Есть
ещё **Terms §09**: «display that content to you and to the advisor you chose».

## Карта — Privacy

| § | Что сделать | Почему |
|---|---|---|
| 02 | **Оставить** «the display name you choose» | Собирается. Правка `012` |
| 02 | Убрать «birth details (date, time and place)» | Не собирается; вернуть, когда доедет `AURAT-0039` |
| 02 | Из технических оставить **только** push-токен и платформу; убрать модель устройства, версию ОС, версию приложения, язык, IP, краш-репорты | Приложение шлёт `{ platform }` и всё; телеметрии в зависимостях нет |
| 02 | Убрать «App Store» | iOS не существует |
| 05 | Убрать «and crash diagnostics» из строки про Google; **дописать туда профильное имя** | Крашей нет; имя лежит именно у Google |
| 05 | Убрать строку «Apple and Google» → только Google | — |
| 05 | Переформулировать «the advisor you chose» | Персона над общим инбоксом; отправитель не показывается |
| 05 | «Customer-support tooling» — это наша же установка на нашем хосте, не сторонний обработчик | Формулировка хуже, чем положение дел |
| 06 | Убрать Apple из «notably Google and Apple» | — |
| 07 | Обещание удаления переписки | Механизма нет |
| 07 | «Diagnostic and security logs — up to 12 months» | Ротация по объёму 3×10 МБ; месяцами не пахнет |
| 08 | «delete your account from the app's profile screen» + «delete it» | Механизма нет. Назвать оговорку: реестр неудаляем, у стойки своя копия |
| 11 | «close the account and erase the data» | То же обещание, третье место в этом документе |
| 12 | Убрать «App Store» | — |
| 13 | `info@aura-app.cc` | MX у домена пуст |

## Карта — Terms

| § | Что сделать | Почему |
|---|---|---|
| 02 | «we close it and delete the data» | Механизма нет |
| 04 | «You can delete your account at any time from the profile screen» | Прямее всех семи |
| 05 | «Advisors are independent practitioners… the words of a reading are their own» | Проверить по коду нельзя — за владельцем. Но соседствует с персонами `AURAD-0001` |
| 07 | Убрать Apple и App Store (два места) | iOS не существует |
| 07 | «write to support@aura-app.cc and we will credit or refund it» | Адрес не принимает почту; а сам возврат сегодня делается руками (`AURAT-0030-002`) |
| 09 | «display that content to you and to the advisor you chose» | Персона над общим столом, третье место |
| 12 | «delete your account whenever you like» | Механизма нет |
| 15 | `support@aura-app.cc` | MX пуст |

## ЧЕГО НЕ ТРОГАТЬ — и это единственное, ради чего документ стоит читать до правки

Три предложения ловятся на те же слова, но говорят о другом и **верны**.
Правка поиском по «crash», «IP» или «logs» их сломает.

- **Privacy §12, «hosting provider keeps standard server logs, including IP
  addresses»** — это логи **сайта у Netlify**, и они действительно есть. К
  краш-репортам приложения отношения не имеет.
- **Privacy §07, «Diagnostic and security logs»** — это **наши серверные** логи,
  они тоже есть. Неверен там только **срок** (12 месяцев), а не факт.
- **Privacy §12, «sets no advertising or profiling cookies»** — проверено:
  `Set-Cookie` в ответе отсутствует. Верно.

Проверено и верно, менять не нужно: одноразовый код вместо пароля; push-токен;
«never your card number»; «attachments are served only to authenticated
requests»; «up to 30 days in backups»; семь лет на бухгалтерские записи;
отсутствие продажи данных и рекламных сетей; юрисдикция ЕС.

## Порядок правки

1. Сначала **семь мест про удаление** — они в двух документах и решаются одним
   решением владельца (строить путь удаления или снимать обещание).
2. Потом вычёркивание несобираемого — механическая часть, кода не касается.
3. Потом переформулировки (персона, служба поддержки, срок логов).
4. Почта — до публикации URL в листинге, а не после.
