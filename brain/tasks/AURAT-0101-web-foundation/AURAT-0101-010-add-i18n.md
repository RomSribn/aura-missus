# AURAT-0101-010 — Add: i18n

Date: 2026-10-20
Owner, reviewing 009: «добавь так же переводы через i18 и запиши правило про добавления переводов в
каждой задаче».

This reverses an earlier choice: `AURAI-0007` Р6 / `AURAF-0020` «NOT in scope: i18n» /
`aura-web-build-rules` «Copy is English, in each slice's config/copy.ts (no i18n yet)». The owner is the
source of truth — the web gets i18n now, in the foundation, and a rule that every task ships its
strings in every supported language. The mobile app is not affected (its rules stay as they are).
No new AURA ID is minted here; the change is recorded in this task and in the rules / AURAF-0020 text.

Open (asked): supported languages; library.

Answers (owner, same day): languages — «en, и все страны EC» → English (source, fallback) + the 23 other
official EU languages: bg cs da de el es et fi fr ga hr hu it lt lv mt nl pl pt ro sk sl sv
(Ukrainian / Russian are not in this set). Library — i18next + react-i18next.
