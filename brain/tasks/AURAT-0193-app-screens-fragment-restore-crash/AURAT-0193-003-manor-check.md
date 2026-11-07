# AURAT-0193-003 — проверка в маноре

Дата: 2026-11-07 · `develop` @ `68f0333` (с 0188 и 0181), debug-сборка arm64, AVD `Galaxy_A16_API36`. Координатор.

| Проверка | До (`0ea88d0`, `AURAT-0188-011` п. 9) | После |
|---|---|---|
| `settings put system font_scale 1.15` при открытом треде | `FATAL EXCEPTION` — `Screen fragments should never be restored` | ✓ без падения; экраны собраны заново из JS (открылась главная) |
| То же с открытой клавиатурой (заодно модуль `AuraKeyboardFrame` при пересоздании) | — | ✓ без падения |
| `font_scale 1.0` обратно | — | ✓ без падения |
| Home → `am kill cc.silvermind.aura` → `am start` | — | ✓ новый процесс, без падения, главная |

Не проверено: A50 (Android 11) — телефон владельца; Pixel 10 — со сборкой релиза.
