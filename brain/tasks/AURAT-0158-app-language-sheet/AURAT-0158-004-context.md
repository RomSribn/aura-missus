# AURAT-0158-004 — context

Код (ground truth, slave-1 @ `d5b25bc`):
- `shared/lib/i18n/start.ts`: `chooseLanguage(lang | 'device')` пишет `{language, osLanguage}` или стирает файл,
  если выбран системный язык, и сразу `applyLanguage`. `currentLanguage()` — язык на экране (псевдо → en).
  `systemLanguage()` (detect-language.ts) наружу не экспортирован. Отдельного «есть ли сохранённый выбор» нет —
  но по устройству «выбран системный язык» ≡ «следую за устройством» (файл стирается).
- `I18N_ENABLED` из `config/env` из `@/shared` не экспортирован.
- `screens/profile`: строк `config/locales` нет (слайс целиком переезжает в шаге 3). `ProfileMenu` — без слота
  значения, `key={row.label}`. `use-profile.ts:66-69` фильтрует все `sheet`-строки при выключенном кошельке
  (сейчас там только promo — кошельковая строка).
- `BottomSheet`: `visible / onClose / onClosed / dragFromGrip` — `onClosed` срабатывает, когда модал реально
  ушёл: туда и вешается применение языка (иначе смена языка перерисовывает уходящий лист).
- Листы профиля — фичи (`promo-code`, `account-deletion`, `store-topup`): хук фичи + лист, экран держит
  `activeSheet`.
- Jest удаляет `Intl.DisplayNames` (как в Hermes) — дрейф-тест таблицы имён спрашивает Node отдельным процессом.

Дизайн: 14 — строка «Languages», значение «English» серым справа; 15 — «Choose language» + ✕, подзаголовок
«You can change this later in your profile.», радиосписок, у выбранного коралловый круг с галочкой, «Choose».
`AURAI-0010` §8: подзаголовок с единственным входом (профиль) не вяжется — шага языка при первом запуске нет.

Веб (aura-web `shared/i18n/language-choice.ts`): имена — `Intl.DisplayNames`, первая буква заглавная по правилам
языка. Node 22 ICU даёт те же: самоназвания Български … Svenska; en — Bulgarian … Swedish.

Переводы: `Language` — есть у веба (`me-page:sections.language`, 23 языка, совпадает с глоссарием `language`).
`Choose language`, `Device language`, `Choose` — у веба нет; `device language` — термин глоссария (форма для
каждого языка задана). Кнопка «Choose» — по форме кнопок языка (bg/hr/sl — ед. ч. повелит., el/hu — отглаг.
сущ., cs sk lt lv fr pt es de nl — инфинитив).
