# AURAT-0065-002 — Что уже есть

Дата: 2026-09-08
Слот: `aura-app-manor/slave-0`, ветка `feature/AURAT-0065-app-profile-avatar`
от `develop` = `9e9d0b5`. Brain — `c3954aa`.

В папке задачи только `001-initial.md` (заглушка, заведена из BFF-манора вместе
с серверной половиной). Работа не начиналась.

## Готовое, что переиспользуется целиком

| Что | Где | Зачем здесь |
|---|---|---|
| `bffUpload` | `shared/api/bff/upload.ts` | multipart с прогрессом, поле файла задаётся вызывающим |
| `react-native-image-picker` ^8.2.1 | `features/chat/model/use-attachment-draft.ts` | `maxWidth/maxHeight` и `assetRepresentationMode: 'compatible'` (HEIC→JPEG + поворот в пиксели) |
| Лист выбора источника | там же (`sourcesOpen`, `chooseSource`) | камера / библиотека, с задержкой до закрытия шита |
| `ProfileOrb` | `shared/ui/orb/` | остаётся видом по умолчанию навсегда |
| `authService.getIdToken(force)` | `shared/api/firebase/` | заголовок для запроса байтов |
| `profile-store` | `entities/user/model/` | `PUT /v1/me/avatar` отвечает полным профилем — писать некуда больше |

## Где сегодня рисуется орб

Три места, и это важно для раскладки компонентов:

- `screens/create-account` — 68 px, `empty` пока имя пустое;
- `screens/edit-profile` — 72 px, `empty` не бывает;
- `screens/profile/ui/ProfileCard` — 56 px, шапка настроек, `empty` пока имени нет.

Дизайн рисует `PhotoRow` только на первых двух. Третье — вопрос к спеке.

## Чего нет

`entities/user/ui/` не существует: в срезе только `api/` и `model/`. Папку
заводит эта задача.

Дальше: `003-understand`.
