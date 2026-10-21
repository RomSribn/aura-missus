# AURAT-0089-010 — AAB для прода

Дата: 2026-10-21

Владелец: «собери aab для прода». AAB 29 уже загружен в Play → versionCode 30 /
versionName 1.0.5 (манор, `develop` @ `442a5bf`, локально, не запушен).

`npm run aab:prod` в маноре — BUILD SUCCESSFUL (19 мин 44 с).
`android/app/build/outputs/bundle/release/app-release.aab`, 66.2 MB (было 71.8 MB):
- `base/dex/classes.dex` 8.6 MB (R8);
- `BUNDLE-METADATA/com.android.tools.build.obfuscation/proguard.map` есть — Play
  подхватит деобфускацию сам;
- бэкенд `bff.aura-app.cc`; подпись — upload-ключ (SHA-256 `61:C3:F5:…:BB:8B`).

Дальше владельцу: загрузить в Play, проверить App bundle explorer (DEX optimization).
