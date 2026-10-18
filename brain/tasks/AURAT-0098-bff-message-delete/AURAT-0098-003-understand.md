# AURAT-0098-003 — Понимание и контекст

Дата: 2026-10-18

Оператор удаляет сообщение в Chatwoot → BFF принимает `message_updated` с
`content_attributes.deleted`, мягко удаляет строку с вычисткой текста и вложений,
шлёт WS `message.deleted`, история перестаёт отдавать удалённое и по
`deletedFrom` возвращает `deletedIds`. Сначала тег `aura-contracts` `v0.22.0`
(от него зависит app-задача `AURAT-0097`), потом BFF.

Источники (все одобрены владельцем, читаются из клона `aura-app-manor`):
- план — `AURAT-0098-001-initial.md` (части A и B);
- фича — `AURAF-0018-message-deletion.md`;
- факты о Chatwoot 4.15.1 и коде — `AURAT-0097-004-context.md`;
- решения — `AURAT-0097-006-decisions.md` (без следа; обе стороны; TECH-DEBT
  вместо бэкстопа), одобрение — `AURAT-0097-007-approval.md`.

Собственной спеки не пишу: план `001` и есть спека, одобренная владельцем.
