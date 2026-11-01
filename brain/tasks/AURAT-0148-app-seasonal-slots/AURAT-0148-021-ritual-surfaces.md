# AURAT-0148-021 — экран Daily Card и расклад в чате в цветах сезона (решение владельца)

Дата: 2026-11-01. Владелец: сезонные цвета красят только баннер на Home, а экран Daily Card, который он
открывает, остаётся сливовым — пусть фон наследует пресет; и то же для расклада карт в чате с адвайзером.
Расширяет `SEASONAL.md` §4 (дописано решение).

- `entities/campaign`: `lib/ritual-look.ts` (`ritualLookOf`) + `useRitualLook()` — один источник для всех
  тарот-поверхностей. Без сезона — сегодняшние `theme.gradients.dailyCard` / `tarotSpread`, `plumDark`, gold.
  С сезоном: `bannerFrom` вместо plum, свечение за колодой и верх панели — `bannerFrom` +12% / +5% к белому
  (так сегодняшние `#4C3566` / `#3D2857` поднимают plum; токены `theme.season.ritualGlowLift/PanelLift`),
  `bannerTo` — тёмный край и подложка (вырез, home indicator), `bannerAccent` — всё золото.
  `SeasonBanner` = `RitualColors` (один тип).
- `shared/lib/styles.ts`: `mixHex(from, to, t)`.
- Daily Card: фон, подложка, eyebrow, спиннер, keywords и рамка guidance — из `look`.
- Расклад (`features/tarot-spread`): `TarotSpreadCard` читает `useRitualLook()` и передаёт `look` в
  Picker/Result → панель `SpreadShell` (градиент + рамка), eyebrow, «chosen»-строка, полноэкранный
  `SpreadCardViewer` (wash, ground, keywords).
- Сами карты (рубашка/лицо, `entities/tarot`) — plum и gold: это колода, не комната.
- Контраст: белый и акцент на обоих концах — пары P11–P16, сервер их проверяет.
- Тест `ritual-look.test.ts` (без сезона / winter / valentine); `tsc` ✓, `eslint` ✓, jest 159 / 1165 ✓.
- Пересобран staging-APK, установлен на A50.

Веб (`AURAT-0149`/`0151`): если владелец захочет так же — отдельной задачей.
На устройстве добавить: Daily Card и расклад в чате под winter — фон/подложка без сливовых полос в вырезе.
