# AURAT-0087-011 — Сборка 22 (1.0.1) в Play; Канада в Play

Дата: 2026-10-13

- AAB собран в маноре `npm run aab:prod` (101 с), `develop` @ `5a1432a` +
  подъём версии; SHA-256 `2ad051f51444a7b5fcec530dda2e23702c242954b96573af1f4d5c0173021958`,
  подпись upload-ключом `CN=Aura, O=Silvermind, C=ES`, 4 ABI.
- Владелец залил в Play: production и internal — `22 (1.0.1)`, раскатка 100%,
  все страны. Release notes en-US: выбор страны при входе, Канада, фиксы.
- Предупреждение Play «no deobfuscation file» — ожидаемое: R8 выключен
  (`enableProguardInReleaseBuilds = false`), `mapping.txt` не существует.
- Подъём версии закоммичен и запушен: `develop` @ `af9f6b8`.
- Прочитано через Android Publisher API: production-стран **35, CA есть** —
  владелец добавил Канаду в Play. Канада теперь во всех трёх местах
  (Firebase, Play, App Store) — TECH-DEBT #11 погашен по сути; строка в
  `TECH-DEBT.md` ещё не зачёркнута.
