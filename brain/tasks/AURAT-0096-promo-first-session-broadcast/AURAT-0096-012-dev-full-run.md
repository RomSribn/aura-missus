# AURAT-0096-012 — полный прогон на development

2026-10-17. Владелец на телефоне: второе сообщение — текст в две строки, пуш и пузырь ок.

- Полный прогон: `recipients 7 · 4 offer used · sent 3 (0 without device)`, exit 0.
  Store: `cmtcwn9kr…` (sunshine, 2850), `cmu4bgb39…` (veronica, 2852), `cmvcngvvz…` (olivia, 2854),
  ~1 msg/s.
- Повторный прогон: `3 already sent · sent 0`, exit 0 — идемпотентность подтверждена.
- Логи `bff-dev`: ошибок нет; FcmSender штатно удалил 3 протухших Android-токена.

## Дальше — прод
Мерж `develop` → `main` (отдельное «да»; `main` пересобирает и `aura-bff`, и `aura-chatwoot`),
затем в прод-контейнере `aura-bff`: `--dry-run` → `--only <прод-userId владельца>` →
полный прогон днём. Предпосылка: Android 1.0.2 (versionCode 27) раскатан в Play.
