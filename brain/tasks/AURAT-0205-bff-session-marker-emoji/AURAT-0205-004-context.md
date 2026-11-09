# AURAT-0205-004 — context

Проверено в коде (develop `5bb4200`):

- Маркер в Chatwoot шлётся в одном месте — `SessionsService.announce()`
  (`src/modules/sessions/sessions.service.ts:606`): `SESSION_MARKER_CONTENT[...]` →
  `messaging.postActivityMessage()` → `chat.ingestSystemMarker({ content, … })`.
  Один и тот же `content` идёт в оба места.
- `SESSION_MARKER_CONTENT` / `markerOf` (`src/modules/chat/session-markers.ts`) —
  контракт: `marker` выводится из сохранённого текста точным совпадением; клиенты
  узнают старую историю по тексту (AURAT-0168). Сохранённый текст менять нельзя.
- Текст стола нигде не сравнивается с сохранённым:
  - вебхук и reconciliation идут через `message-normalizer.ts`; у activity
    (`message_type` 2 / `'activity'`) нет направления → `buildMessage` / `buildDeletion`
    возвращают null;
  - `ingestSystemMarker` дедупит по `(conversation, chatwootMessageId)`, текст не
    сравнивает;
  - клиент (`createActivityMessage`) и адаптер (`postActivityMessage`) просто постят
    то, что дали; чтения «последнего сообщения» из Chatwoot нет.
- Формулировки для стола (приватные заметки) живут в домене sessions —
  `notices/desk-note.channel.ts`. Маркер — не нотис (не идёт через `SessionNotifier`),
  поэтому отдельный маленький модуль рядом с `announce`, а не канал нотисов.
- Тесты announce — `sessions.service.spec.ts:1566` (`describe('announce')`),
  сейчас ждут одинаковый текст в обоих вызовах.

Противоречий с фоном из манора нет.
