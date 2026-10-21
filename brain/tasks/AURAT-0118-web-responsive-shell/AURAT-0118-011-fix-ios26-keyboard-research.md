# AURAT-0118-011 — Fix: шторка над клавиатурой iOS 26 — разбор и вторая версия

Date: 2026-10-21

## Слова владельца

> нет, просто комит изменений, фикс продолжаем тут. Проблема именно когда клавиатура открыта, ИОС
> версии с жидким стеклом. Посмотри в интернете как реализовывать такой функционал тут

Мёрж не делаем; фикс `f13e078` (`010`) на телефоне ещё не проверялся — dev-сервер манора на develop
`f5b222a`. Продолжаем в слоте.

## Что нашлось (сообщество, не документация Apple)

- `interactive-widget=resizes-content` и VirtualKeyboard API (`keyboard-inset-*`) iOS не поддерживает —
  только JS по `window.visualViewport` (`resize` + `scroll`).
- dfinity/governance-app PR #513 (iOS 26 Safari, vaul): iOS сначала шлёт `resize` видимой области, а
  через десятки мс прокручивает окно к полю (`scroll`, `offsetTop` растёт). Чтение сразу после `resize`
  даёт неверную позицию — шторка и поле уезжают. Их решение: шторка кончается у верха клавиатуры —
  `keyboardInset = documentElement.clientHeight − offsetTop − height` (≥ 0), высота ограничена
  `visualViewport.height`; перечитывать через ~100 мс после последнего события; вниз / выше (клавиатура
  закрывается) — сразу.
- parisosuch/colosseum PR #595: одной высоты мало — шторка привязана к низу layout viewport, нужен
  отдельный отступ под клавиатуру.
- Apple Developer Forums 800154 / 800125, WebKit 297779: в iOS 26 после закрытия клавиатуры
  `offsetTop` может остаться > 0 — схема `top: offsetTop; height` (версия `010`) тогда уводит низ шторки
  за край экрана; схема с `bottom: max(0, …)` — нет.
- `scrollIntoView` прокручивает и окно — спорит со своей прокруткой iOS к полю.

## Вторая версия (меняет `010`)

- `shared/lib/browser/use-visible-viewport.ts`: на слое — `--keyboard-inset` (место под клавиатурой у
  низа layout viewport) и `--visible-h` (`visualViewport.height`); `resize` и `scroll`; рост отступа —
  через 100 мс после последнего события, уменьшение — сразу; без `scrollIntoView`.
- `sheet.module.css` (≤ 760): слой — `inset: 0` с `bottom: var(--keyboard-inset, 0px)`; шторка —
  `max-height: calc(var(--visible-h, 100%) * 0.92)`. Без `visualViewport` — как до задачи.
- Тест — по сценарию iOS 26: `resize` (449, 0) → `scroll` (449, 288) → через 100 мс отступ 59px и высота
  449px; открытие с уже открытой клавиатурой; закрытие — сразу.
