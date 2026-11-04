# AURAI-0010 — пробник Hermes

Запускает любой JS на **точной сборке Hermes приложения** (macOS-срез пода `hermes-engine`, тот же код Intl,
что на iOS, — `PlatformIntlApple`) без симулятора. Так в `AURAI-0010` проверены `Intl`, полифилы PluralRules,
i18next и определение языка.

## Сборка (2026-11-04, проверено)

```bash
D=<slot>/master/ios/Pods/hermes-engine/destroot   # появляется после `pod install`
clang++ -std=c++20 -I$D/include -F$D/Library/Frameworks/macosx -framework hermesvm \
  -Wl,-rpath,$D/Library/Frameworks/macosx AURAI-0010-hermes-probe-host.cpp -o hermes-probe
printf 'print(Object.getOwnPropertyNames(Intl).join(","), typeof Intl.PluralRules)\n' > t.js
./hermes-probe t.js   # → getCanonicalLocales,Collator,DateTimeFormat,NumberFormat undefined
```

Фреймворк называется `hermesvm`, не `hermes`. Несколько файлов выполняются в одном рантайме по порядку, так что
полифил можно подать первым: `./hermes-probe shim.js test.js`. Внутри есть `print()`. Модули (`import`) хост не
понимает — сначала собрать в один файл (например, `npx esbuild entry.js --bundle --format=iife`).

## Язык по умолчанию — только внутри `.app`

Голый бинарь не проходит подбор языка по бандлу: `-AppleLanguages '(de-DE)' -AppleLocale en_US` даёт `en-US`.
Чтобы увидеть поведение приложения, положить бинарь в `Probe.app/Contents/MacOS/` с `Info.plist`
(`CFBundleLocalizations` — нужный список) и запускать его оттуда с теми же аргументами:

| Бандл | `(de-DE)` + `en_US` | `(uk-UA, pl-PL)` + `uk_UA` |
|---|---|---|
| только `en` (как Aura сейчас) | `en-US` | `en-UA` |
| 24 `CFBundleLocalizations` | `de-US` | `pl-UA` |

## Чего пробник не показывает

Android (Intl там на ICU4J/`android.icu`, другой код), реальный iOS, текстовый движок RN. Это — манор и устройство.
