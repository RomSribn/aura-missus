# AURAT-0209-018 — Privacy: записи согласий из `AURAT-0216` / `AURAT-0218` (предложение манора)

Дата: 2026-11-18. **Одобрено владельцем 2026-11-18:** «Да, обе правки». Это правка одобренного текста `011`.

## Зачем

BFF-часть `AURAT-0216` заводит таблицу `consents`. Для каждой брони, сессии «сейчас» и продления в ней
хранится, какую версию текста галочки клиент подтвердил, на каком языке и когда. То же для согласия с
Terms при оплате на вебе (`AURAT-0218`).

Сейчас Privacy §02 называет только запись согласия на чат. Новые записи не названы, и в §03 нет цели
для них.

## Живая Privacy, 2026-11-18

`https://aura-app.cc/privacy/`, sha256 `47aae8e8…2161c` — та же, что 17.11. В §03 строки на эту цель нет.
Ближайшие строки:
- «Processing credit purchases, sessions and refunds, and keeping accounting records | Contract; legal
  obligation (accounting)»;
- «Responding to legal claims and requests from authorities | Legal obligation; legitimate interests».

Ни одна из них не называет хранение записи о подтверждении.

## Правки к промпту 2 (`014`) — дополняют `015`

**П. 3, третий абзац.** После «…what it cost, and any refund or dispute.» вставить:

> When you book, start or extend a session, or pay in the web app, we also keep a record of what you
> confirmed: which version of the text, in which language, and when.

У манора было «pay by card». Заменено на «pay», потому что на вебе платят не только картой: ещё Apple
Pay, Google Pay и Link (Terms §07), а согласие `0218` спрашивается при любой оплате.

**П. 4, таблица §03.** Кроме замены строки о дате рождения, добавить строку сразу после «Processing
credit purchases, sessions and refunds, and keeping accounting records»:

> | Keeping a record of what you confirmed when you book or pay, to show it if there is a dispute | Legitimate interests |

Почему legitimate interests, а не legal obligation, как у записи согласия на чат: галочка — не
согласие по GDPR (ст. 7(1)). Это признание условий договора, а запись хранится как доказательство в
споре (`AURAD-0024`).

## Без изменений

- **§07, срок хранения.** Записи подпадают под «Purchases, balance and sessions»: не меньше семи лет,
  после удаления аккаунта — без имени и телефона.
- **`/delete-account/`.** Их покрывает «records of purchases, balance and paid sessions».
- **Если `AURAT-0219` будет хранить email** для подтверждений, это отдельная правка Privacy в той
  задаче (`AURAT-0219-001`).
