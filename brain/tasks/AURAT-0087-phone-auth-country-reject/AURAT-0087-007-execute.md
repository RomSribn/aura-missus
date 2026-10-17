# AURAT-0087-007 — Сделано

Дата: 2026-10-13
Слот `slave-0`, ветка `fix/AURAT-0087-phone-auth-country-reject`. Не закоммичено,
всё застейджено для ревью.

## Firebase (по решению владельца, 006)

`aura-2781b` → `smsRegionConfig` через Identity Toolkit Admin API (`PATCH`,
`updateMask=smsRegionConfig`, gcloud на Mac, `roma.sribnyi@gmail.com`):
34 → **35 регионов, добавлен `CA`**. Прочитано обратно: 35, CA и US есть,
вход по телефону включён, тестовый номер на месте. Канадские номера проходят
**уже сейчас**, без обновления приложения.

**Осталось владельцу руками:** добавить Канаду в страны Play production
(Play Console → Production → Countries/regions) и в территории App Store
(App Store Connect → Pricing and Availability). Правило TECH-DEBT #1 —
три места сразу.

## Код (`aura-app`)

- `src/shared/config/sms-regions.ts` — новый: `SMS_REGIONS` (35, зеркало
  allowlist) и `SMS_COUNTRIES` (что предлагает пикер).
- `src/shared/lib/phone.ts` — `numberRegion(digits, iso2)`: регион по самому
  номеру через `libphonenumber-js` (так же читает Firebase).
- `src/screens/phone-auth/model/use-phone-auth.ts` — целый номер, чей регион
  не в `SMS_REGIONS`: кнопка неактивна, под полем «We can't text numbers from
  {Country} yet.», Firebase не вызывается. Сообщение вычисляется, не хранится.
- `src/screens/phone-auth/ui/CountryPickerSheet.tsx` — пикер по
  `SMS_COUNTRIES`; комментарии про «245 rows» обновлены.
- `src/screens/phone-auth/lib/device-country.ts` — страна из локали вне списка
  → `ES`.
- `src/shared/api/firebase/auth.service.ts` — `AUTH_REGION_BLOCKED` больше не
  экспортируется (потребителей не было, хард-правило №5); серверный текст
  выровнен: «We can't text numbers from this country yet…».
- `src/shared/index.ts`, `src/shared/api/firebase/index.ts` — экспорты.
- `src/shared/config/countries.ts` — комментарий: полный список нужен, чтобы
  назвать страну номера; пикер уже.
- `TECH-DEBT.md` #1 — 35 регионов, история с CA, правило «три места».

Тесты: `sms-regions.test.ts` (новый), `auth.service.test.ts` (новый —
серверная ветка региона на двух вероятных текстах Android + не-региональный
отказ), `phone.test.ts` (`numberRegion`: 438/416 → CA, 201 → US, 876 → JM),
`use-phone-auth.test.tsx` (Ямайка под «United States» названа и остановлена,
канадский 438 проходит, `+92` вставкой → Pakistan без вызова `sendOTP`,
недобранный номер — тишина).

## Проверки в слоте

`npx tsc --noEmit` — чисто; `npx eslint src` — чисто; `npx jest` — 120 наборов,
838 тестов, всё зелёное. (`npm run typecheck` в этом репо нет — скрипта нет.)

## Открыто

- Точный текст серверной ошибки региона на Android по-прежнему не подтверждён
  на устройстве — после мёржа в маноре можно проверить номером из
  неразрешённой страны (вставкой, напр. `+92`, клиент остановит раньше —
  значит, проверка серверной ветки возможна только при расхождении списков).
- Фикс клиента дойдёт до людей только с новой сборкой в Play и App Store.
- Цвет текста отказа — коралловый, как у всех ошибок экрана; по правилу
  `AURAT-0080` («серый там, где это факт») региональный отказ — факт. Не менял:
  вне скоупа спеки, решить вместе с `AURAT-0080`.
