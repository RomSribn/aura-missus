# AURAT-0179-009 — execute (правки 008)

Дата: 2026-11-07. Файлы: `HomeScreen.test.tsx`, `features/chat/ui/MessagePreview.tsx`, `features/chat/config/locales/
{en,index}.ts`, `screens/chats/config/locales/en.ts`. Prettier применён только к `MessagePreview.tsx` — у
`ChatListRow.tsx` и теста он переформатировал бы чужие строки, их не трогал.

Проверка: act-предупреждений в `HomeScreen.test.tsx` — **0** (было 175, вместе с 91 от старых тестов); tsc 0, lint 0,
Jest 221 / 3035 зелёный, `translate.mjs check` — 0 avoided.

Дальше: лёгкая проверка координатора → одобрение владельца → коммит, вливание `develop` (`35ae093`) в ветку,
перепрогон, мёрж (каждый шаг с мёржем — отдельным вопросом).
