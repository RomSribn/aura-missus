# AURAT-0118-042 — Исследование: панель iOS над клавиатурой (˄ ˅ ✓, AutoFill) в Safari

Date: 2026-10-21

## Вопрос владельца

> Проинвестигируй как работает этот нативный компонент ИОС в вебе

## Источник

Открытый код WebKit (`main` `70f4e7bc`, 2026-10-21; файлы — `WKContentViewInteraction.mm` `162a937a`,
`forms/WKFormAccessoryView.mm` `4bc4dba7`, `WebPage.cpp` `da8adc50`, `ios/WebPageIOS.mm` `760bea87`,
`_WKFormInputSession.h`, `WKWebView.mm`), WebKit bug 155574, обсуждения iOS 26. Safari поверх WebKit — закрытый код.

## Что подтверждено кодом

- Решение показывать панель (`requiresAccessoryView` / `_elementTypeRequiresAccessoryView`): на iPhone — **да**
  для text, password, search, email, url, tel, number, **textarea** и **contenteditable**; нет — для date / time /
  month / color и при Writing Tools. Приложение (Safari) может спрятать панель (`accessoryViewShouldNotShow`)
  или подставить свою — страница до этого не дотягивается.
- Содержимое на iPhone (`WKFormAccessoryView`): ˄, ˅, отступ, Done; с Liquid Glass Done — галочка, поля 10pt
  сверху и снизу. Кнопку AutoFill («AutoFill Contact») добавляет **Safari** (`accessoryViewCustomButtonTitle`), не
  WebKit. QuickType-подсказки — из `autocomplete` (`tel`, `one-time-code` → «From Messages»).
- ˄ ˅ активны, если в порядке фокуса всей страницы есть другое «assistable» поле, не перекрытое другим
  элементом; `<form>` на это не влияет.
- Атрибута, который включает или выключает панель, нет. `inputmode` / `autocorrect` / `spellcheck` —
  слухи, в коде такого пути нет.

## Что не объяснено кодом

- Почему у нашего `<textarea>` панели нет, а у `contenteditable` Telegram и наших `<input>` — есть: WebKit даёт
  `textarea` и `contenteditable` одно и то же. Варианты: Safari (закрытый код) прячет или подменяет панель;
  панель есть, но невидима (в Liquid Glass фон панели прозрачен, рисуются только капсулы кнопок); что-то на
  нашей странице.
- Пустое место под адресной строкой: если панель не нужна, WebKit не резервирует место (`nil`). Значит, это
  либо невидимая панель, либо интерфейс Safari, либо наша вёрстка.

## Проверки на устройстве (различают случаи)

1. Тап туда, где была бы ✓ (справа в пустой полосе): клавиатура закрылась → панель есть, но невидима.
2. Временно яркий фон `html` / `body`: полоса окрасилась → это наша страница, не Safari.
3. Минимальная страница с голыми `<textarea>`, `<div contenteditable>`, `<input>`: если голый `textarea`
   получает панель — причина в нашем композере.

## Варианты для композера

- `div contenteditable="plaintext-only" role="textbox" aria-multiline="true"` — как у Telegram, тот же путь
  панели; цена — заново: значение, placeholder, лимит, Enter / Shift+Enter, IME, вставка (только текст,
  `textContent`, без HTML). Имеет смысл, только если проверка 3 покажет, что Safari иначе обращается с
  голым `textarea`.
- `<input type="text">` — панель (вероятно), но без многострочных сообщений.
- Убрать пустое место — только если проверка 2 покажет, что оно наше.

Исходники исследования (только чтение): scratchpad `webkit/`.
