# AURAT-0089-009 — Принято

Дата: 2026-10-21 · Статус: **done**

Владелец проверил R8-APK (staging, `892caa7`) на телефоне: «UI норм, релизь».
Release одобрен в этом же ответе → `wts-release slave-0` (мёрж в `develop` и push;
вместе уходит и локальный `df22a59`, versionCode 29 / 1.0.4).

Итог: `aura-app` `892caa7` — R8 в release (`proguard-android-optimize.txt`, keep
Nitro + номера строк), `StatusBar` без `backgroundColor`. DEX 41.1 → 8.2 MB.

Осталось владельцу (вне слота):
- следующий AAB (`npm run aab:prod`) — в нём R8; если 29 уже загружен в Play,
  поднять versionCode до 30;
- после загрузки: App bundle explorer — DEX optimization не Low, issue снят;
  в пометке edge-to-edge останутся только `StatusBarModule`/`WindowUtilKt` из RN;
- в AAB должен лежать `BUNDLE-METADATA/com.android.tools.build.obfuscation/proguard.map`.
