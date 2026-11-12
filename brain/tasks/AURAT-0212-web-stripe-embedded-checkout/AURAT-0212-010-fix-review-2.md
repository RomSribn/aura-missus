# AURAT-0212-010 — Fix: второе ревью координатора (FSD и читаемость)

Date: 2026-11-12

Владелец в этой вкладке на вопрос о мёрже (ветка `6af1bf4` + `8c03c38`) ответил «Да, мёрж». В то же
время пришло второе ревью координатора. Владелец, дословно (в `aura-app-manor`): «передай,
остальное по рекомендации». Переразложение принято, но до мёржа нужно поправить пункты 1–4.
Мёрж отложен: после правок ветка уже не та, что была одобрена, — вопрос будет задан заново.

1. Интерфейс-результат `useCardForm` назывался `CardForm`, как компонент `ui/card-form.tsx`.
   Переименован в `CardFormControl`.
2. `CardFormEvents` и `CardFormControl` наружу никто не импортирует — `export` снят (правило 5).
3. `cx(styles.form)` в `card-form.tsx`: у `EmbeddedCheckout` `className?: string`, а CSS Module
   при `exactOptionalPropertyTypes` даёт `string | undefined`. Класс переезжает на обёртку
   `<div>` — проп React принимает `undefined`, и `cx` не нужен.
4. В `use-card-form.ts`: ref `now` → `latest`; в `settle` разбор с исходными именами
   (`provider`, `balance`, `events`).
5. На усмотрение — сделано:
   - комментарий, зачем ленивый `useState` как одноразовый конструктор колбэков;
   - объектные параметры у `open({…})` и `onSettled({…})`;
   - `open` отвечает, открыл ли форму, и только тогда `setPhase('form')`.

Прогон:
- `lint` и `typecheck` — чисто;
- `npm test` — 1959 / 1960. Упал `profile.test.tsx › Notifications: the offers switch…` (4,2 с,
  таймаут под нагрузкой). К оплате он не относится; отдельно файл прошёл дважды, 17 / 17;
- `build` — ок, маркера фейка нет.

Коммит: `AURAT-0212: card form hook — names, object arguments, no unused exports`.
