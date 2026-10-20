# AURAT-0107-012 — Fix: the open sheet keeps `?book=1&slot=` in the URL

Date: 2026-10-20

Owner, verifying: «когда я перехожу, то с ссылки убираются url params». Asked how it should be;
owner chose: while the Book sheet is open over the profile, the address is
`/advisors/<id>?book=1&slot=<chosen time>` — on arrival by link and on Book; it can be copied, a
reload opens the sheet again; closing it and Back from Booked land on the plain profile and do not
reopen it. Over the chat the URL stays `/chats/<id>`.
