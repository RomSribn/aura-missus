# AURAT-0038-005 — Сделано, гейты зелёные, Android доказан

Дата: 2026-08-21
Слейв: `slave-0`, ветка `feature/AURAT-0038-paste-image-into-chat`

## Файлы

| Файл | Что |
|---|---|
| `package.json` | `@mattermost/react-native-paste-input` 2.0.1 |
| `screens/chat-thread/ui/ChatInputBar.tsx` | `TextInput` → `PasteInput`, проп `onPaste` |
| `screens/chat-thread/ui/ChatThreadScreen.tsx` | `onPaste={attachment.fromPaste}` |
| `features/chat/model/use-attachment-draft.ts` | `pastedAsDraft` + `fromPaste` |
| `ios/PsychoApp/AppDelegate.swift` | `PasteInputModule.setup(factory.rootViewFactory)` |
| `jest.setup.js` | мок поля: обычный `TextInput`, несущий `onPaste` |
| `screens/chat-thread/ui/__tests__/ChatThreadScreen.paste.test.tsx` | 7 тестов |

`attachment-rules.ts` не менялся: вставка проходит те же `resolveContentType`,
`refuseDraft` и `kindOf`, что и любой другой источник.

## Решения, принятые при исполнении

1. **Имя для безымянной вставки** — `pasted.<ext>`, расширение выводится из
   типа через существующий `extensionOf`. Скриншот из просмотрщика приходит без
   имени, а файл без расширения iOS потом не открывает и не проигрывает
   (`AURAI-0003`).
2. **Несколько файлов — отказ, а не молчаливая потеря.** «One file at a time».
3. **Сообщение платформы наружу не идёт.** В буфере может лежать текст, который
   печатал пользователь; показывается наша фраза — то же правило, что и для
   кодов отказа сервера (`AURAT-0036`). Тест это и проверяет: приватная строка
   из ошибки не должна оказаться на экране.
4. **Пустая вставка — не событие.** На Android колбэк срабатывает и на медиа из
   клавиатуры; молчать здесь правильно, и это не то молчание, ради отмены
   которого заводилась фича.

## Риски спеки — что с ними стало

| Риск | Итог |
|---|---|
| Паритет пропсов (`submitBehavior`) | **Снят типами**: `PasteInputProps extends TextInputProps` |
| Конфликт нативного модуля с Nitro / рельсом Google Play | **Снят сборкой Android**: `BUILD SUCCESSFUL`, codegen `PasteTextInputSpecs` собран под все 4 ABI и слинкован в `libappmodules.so` — рядом с `libNitroIap.so` и `libNitroModules.so`. То, что убило запись голосового, здесь не повторилось |
| Компиляция строки в `AppDelegate` | проверяется сборкой iOS, идёт |
| Временный / security-scoped `uri` из буфера | **проверяется только на устройстве** — если понадобится, тот же `keepLocalCopy`, что уже написан для документов |

## Гейты

`tsc` 0, `eslint` 0, `jest` **61 сюита / 400 тестов** (было 60 / 393).
Экзит-коды сняты отдельно, не с хвоста пайпа.

## Что осталось до приёмки

Жест на устройстве. Проверяется в маноре после мёржа — по правилам слейва, и
потому что буфер обмена невозможно проверить юнит-тестом.
