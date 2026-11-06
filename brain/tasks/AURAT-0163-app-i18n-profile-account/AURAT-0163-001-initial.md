# AURAT-0163-001 — initial

Дата: 2026-11-06. Выдана по просьбе владельца («да, запускай» — на предложение выдать номера и запустить профиль и
витрину). Запуск — slave-0 (`wts-run`), от `develop` @ `7f58117`.

Шаг 3 фичи `AURAF-0023` — перенос строк. Это задача «профиль и аккаунт» из плана `AURAI-0010` § Recommendation, п. 3.
В develop уже есть: основа i18n, глоссарий, шрифты el/bg, shared-слой, форматтеры CLDR, лист языка, entities, вход
(`AURAT-0154`…`0159`, `0161`, `0162`).

Что входит; границы уточнить в спеке:
- `screens/profile`, `screens/edit-profile`, `screens/create-account`. create-account вынесена сюда из входа
  решением владельца `AURAT-0162-006` п. 1: поля Name / Email / Date of birth общие с edit-profile, у них должен быть
  один источник.
- `features/profile-form`, `features/profile-photo`, `features/sign-out`, `features/account-deletion`.
- Строка Language в профиле и её лист — уже `AURAT-0158`, не трогать.

Известные места (`AURAI-0010-evidence.json`):
- `Edit ${label.toLowerCase()}` — нижний регистр переведённого существительного ломает немецкий. Нужна целая строка
  на поле или `{{label, lowercase}}` по правилам языка.
- a11y `${title}. Day, month, year` у даты рождения — целая строка с интерполяцией.
- Валидация profile-form — булевы флаги, тексты лежат в config create-account / edit-profile.
- Удаление аккаунта — `@sensitive` (account-deletion): до маркетинга в стране нужна проверка носителем
  (`translate.mjs review`).

Правила — раздел «Translations» в `.claude/aura-build-rules.md`:
- все 24 языка в этой же задаче, namespace на слайс;
- глоссарий: `translate.mjs scan … --web <aura-web>`, на вебе уже есть edit-profile и account-deletion;
- `@max` для узких мест, `@sensitive`;
- `i18next/no-literal-string` на `error` для перенесённых путей;
- даты — через форматтеры `0159` с явным языком.

Параллельно в slave-1 идёт `AURAT-0164` (витрина). Общие файлы (`app/i18n/namespaces.ts`, `.eslintrc.js`) трогают обе
задачи — конфликт решает та, что мёржит второй.
