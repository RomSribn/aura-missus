# AURAT-0202-004 — лендинг: кнопка App Store неактивна, «Soon»

Дата: 2026-11-08. Владелец: «и добавь апдейт, чтобы кнопку App Store сделать неактивной, добавить Soon туда рядом». Выкладывается вместе с правкой политики (`003`).

Живой `/` на 2026-11-08: две кнопки App Store — в hero (`id="get"`) и в финальном призыве. Обе ведут на заглушку `apps.apple.com/app/aura/id0000000000`. Google Play ведёт на `cc.silvermind.aura`.

## Промпт для Claude Design

```text
Update the landing page (https://aura-app.cc/).

The app is not in the App Store yet, but both "Download on the App Store" buttons on the page link to a placeholder (https://apps.apple.com/app/aura/id0000000000). There are two of them:
- the store buttons in the hero (the block with id="get");
- the store buttons in the closing call-to-action, under the paragraph ending "…you alone decide whether it goes further."

Make each App Store button inactive until the app is published there:
1. It is no longer a link. Remove the href, target and rel, and render it as a non-clickable element with aria-disabled="true". There is no hover or press effect, and the cursor stays the default one.
2. It looks unavailable but keeps its exact size and position, so the layout does not move. Mute it, for example at about 45% opacity.
3. Add a small "Soon" label right next to the "App Store" text inside the button, as a compact pill in the page's accent style, readable on both the dark hero and the light closing section.
4. Screen readers announce it as "App Store — coming soon".

Keep both Google Play buttons exactly as they are: active, with the same link (https://play.google.com/store/apps/details?id=cc.silvermind.aura), the same look and the same order. Change nothing else on the page.
```

Когда приложение выйдет в App Store: вернуть кнопкам ссылку на настоящий ID, убрать «Soon». Проверить §12 политики («sends you to Google Play or the App Store», `AURAT-0042-119`).
