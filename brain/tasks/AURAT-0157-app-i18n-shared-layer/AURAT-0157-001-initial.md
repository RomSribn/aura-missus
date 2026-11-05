# AURAT-0157-001 — initial

Дата: 2026-11-04. Контекст: ждёт свободного слота (slave-0 и slave-1 заняты 0156 и 0155).

Владелец: «запускай 1b и 1c параллельно на слейвах и другие задачи одновременно».

Диспетчер: шаг **2 (shared + app)** фичи `AURAF-0023`. Основание: `AURAI-0010` §1, §4, решения владельца 2 и 5,
`AURAT-0154` (основа, `develop` @ `40d0ee7`). Что ожидается:
- общие фразы в пространстве `shared` («Go back» ×13, общая ошибка ×7, «Close», «Try again», «Check your
  connection…»);
- `SegmentedControl` → `{ value, label }`, подписи перестают быть ключами состояния (`SEGMENTS`,
  `HOROSCOPE_DAYS`, `SESSION_SEGMENTS` и их сравнения);
- `AuthError` хранит только код, экраны переводят код (`shared/api/firebase`, phone-auth, verify-otp);
- форматтеры с явным языком: деньги USD и даты по CLDR языка интерфейса, время 24h; таблицы CLDR генерирует
  скрипт из Node ICU, drift-тест; ручные сокращения месяцев для bg/lt; `relativeDay` и похожие отдают данные, а
  не английский текст; 42 вызова `formatUsdMinor`;
- тексты пушей и каналы Notifee (пересоздать при смене языка, headless);
- `auth().setLanguageCode(язык)` перед `verifyPhoneNumber`.
Правило «Translations» в `.claude/aura-build-rules.md` обязательно.
