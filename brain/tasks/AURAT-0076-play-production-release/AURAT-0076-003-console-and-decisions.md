# AURAT-0076-003 — Play Console заполнен; страны, SMS и отзывы — решения владельца

Дата: 2026-09-17
Статус: **B сделано**, C в работе

## B. Что заполнено в Play Console (владелец, с разбором в маноре)

- **Sign in details (App access):**
  - тестовый номер Firebase `+34 6…11` с фиксированным кодом;
  - инструкция для ревьюера 440 символов: вход, бесплатный чат, платные сессии
    через Google Play, «не удалять аккаунт».

  Кредитов у ревьюера нет: служебного начисления в BFF не существует (типы
  ledger: TOPUP, SESSION_CHARGE, SESSION_REFUND). Если Google отклонит за
  недоступность платной части — отдельная задача на начисление.
- **Ads:** нет. **Advertising ID:** нет (`AD_ID` в манифесте отсутствует).
- **Content rating (IARC):** All Other App Types. User Content Sharing — Yes
  (чат с командой, отзывы), модерация чата — Yes, block/report — No. Online
  content — Yes. Digital purchases — Yes, лутбоксов нет.

  Итог: PEGI 3, USK 0, ESRB Everyone, ClassInd 14+, IARC 3+; пометки Users
  Interact и In-App Purchases.
- **Target audience:** только 18+. Включено «Restrict users that Google has
  determined to be minors».
- **Data safety:**
  - shared — ничего;
  - collected:
    - Name, User IDs, Phone (required);
    - Email (optional, Account management + Advertising or marketing);
    - Other info — дата рождения (optional, Personalization);
    - Purchase history (optional, + Fraud prevention/compliance);
    - Other in-app messages (required);
    - Photos, Videos, Other audio, Files and docs, App interactions, Other UGC
      (optional);
    - Device or other IDs (required);
  - шифрование при передаче — да;
  - вход — «Username and other authentication»;
  - URL удаления — `https://aura-app.cc/delete-account/`;
  - частичное удаление без удаления аккаунта — **No**: отдельной страницы с
    шагами нет;
  - Contacts по ошибке отмечался и снят.
- **Government apps:** No. **Financial features:** нет. **Health:** нет.
- **Store settings:**
  - категория Lifestyle;
  - email `support@aura-app.cc`, телефон не указан;
  - сайт `https://aura-app.cc`;
  - External marketing включён.
- **Main store listing:**
  - краткое описание (70 символов) и полное (~1 650);
  - в тексте: развлечение, 18+, советники — персоны команды (Terms §05);
  - гороскоп не упомянут — маршрута нет, `AURAT-0039`;
  - иконка загружена.

## C. Решения владельца

| Вопрос | Решение |
|---|---|
| Страны production | «США, Испания, Европа». Манор взял ЕС-27, Исландию, Лихтенштейн, Норвегию, Великобританию, Швейцарию, Украину и США (34). Россия и Беларусь — нет. Балканы вне ЕС и Молдова — не включены, добавить по запросу |
| Allowlist SMS в Firebase | **«Да, сейчас»** |
| Кнопка «пожаловаться» на отзывы | **Отправить без неё.** Текст отзывов предмодерируется. При отказе Google по UGC-политике — добавить |
| Managed publishing | включить до отправки на проверку |

## Allowlist SMS расширен (манор, 2026-09-17)

Identity Toolkit Admin API (`projects.config`, `updateMask=smsRegionConfig`),
учётка Firebase Admin из прод-BFF:
- было `["ES","UA"]`, стало 34 региона: AT, BE, BG, CH, CY, CZ, DE, DK, EE, ES,
  FI, FR, GB, GR, HR, HU, IE, IS, IT, LI, LT, LU, LV, MT, NL, NO, PL, PT, RO, SE,
  SI, SK, UA, US;
- проверено чтением обратно: совпадает. Вход по телефону включён, тестовый
  номер на месте.

**Следствия:**
- `aura-app` `TECH-DEBT.md` #1 устарел: там `["ES","UA"]`. Поправить
  отдельным коммитом в `develop`.
- **Трата на SMS теперь ограничена только этим списком.** Лимиты Google Cloud
  трату не останавливают, App Check нет.

## Бюджет с оповещениями (манор, по просьбе владельца, 2026-09-17)

Создан через `gcloud` на Mac (аккаунт `roma.sribnyi@gmail.com`). На
`aura-2781b` включён `billingbudgets.googleapis.com`.

| Поле | Значение |
|---|---|
| Бюджет | `aura-2781b monthly (SMS guard)`, id `fc01634b-5e64-47c1-9471-2446f3f35f69` |
| Платёжный аккаунт | `01E3AB-F2A605-F44DED` (USD) |
| Сумма / период | $25 в месяц, только проект `aura-2781b` |
| Кредиты | `EXCLUDE_ALL_CREDITS`: пробные $300 (до ~2026-11-26) не прячут реальную трату |
| Пороги | 50%, 90%, 100% фактической траты; 100% прогноза |
| Получатели | стандартные — администраторы платёжного аккаунта по email |

**Бюджет только оповещает, трату не останавливает.** Если придёт письмо о
всплеске: Firebase → Authentication → Usage (SMS по странам), затем сузить
allowlist через `smsRegionConfig`.

Посмотреть: `gcloud billing budgets list --billing-account=01E3AB-F2A605-F44DED`.
