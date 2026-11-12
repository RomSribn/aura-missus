# AURAT-0198-012 — мёрж и живая проверка на bff-dev

Дата: 2026-11-08 · Координатор (сессия «Локализация i18n для aura-app»); выключатели и ответ со стола — владелец.

Мёрж первого захода — `010` (коммит слота `36993f1`, брейн `3c6b26c`, `develop` BFF `71c4666`); мелочи A–E — второй
заход на той же ветке (`011`).

## bff-dev

Выкатка `71c4666`: миграция `20261108120000_message_translations` применена, seed прошёл; «translation chat on»
(`claude-haiku-5-5`, thinking off, effort low, бюджет $20), `TRANSLATION_CHAT_TO_DESK=true`, затем `REPLIES=true`.
Клиент — staging-сборка 0197 на AVD, язык приложения de, тестовый пользователь (согласие v1, перевод включён).

| Направление | Итог |
|---|---|
| Человек → чаттер | ✓ «Hallo Alisher, wird mein neuer Job gut sein? Ich habe ein wenig Angst.» → лог: `chat`, `to: en`, translated, $0,00022, callMs 2362, waitMs 1; отправка прошла (`POST …/messages?lang=de`) |
| Чаттер → человек | ✓ ответ со стола «I'm not sure, my dear!» → лог: `chat`, `to: de`, translated, $0,00007, callMs 1472; в приложении «Ich bin mir nicht sicher, meine Liebe!» · «Von KI übersetzt · Original anzeigen»; «Original anzeigen» → английский, «Originaltext · Übersetzung zeigen» |
| Выключатель | ✓ ответ «Gg», пришедший при `REPLIES=false`, остался без перевода |

Не проверено: пузырь у агента для этого сообщения (владелец смотрит стол), уведомление агенту, догонка `translatedFrom`
после фона, desk-note при сбое, сторож.
