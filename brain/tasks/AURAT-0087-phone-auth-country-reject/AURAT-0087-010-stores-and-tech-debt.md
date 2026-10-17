# AURAT-0087-010 — Канада в App Store; долг записан

Дата: 2026-10-13 (после закрытия, по просьбе владельца)

## App Store (по решению владельца, AskUserQuestion)

App Store Connect API, ключ `XHRC8JZJJN` (issuer `9bc0ba73-…`,
`~/.appstoreconnect/private_keys/`), подпись JWT встроенным `crypto` Node:
- приложение `6813629245`: `PATCH /v1/territoryAvailabilities/<CAN>` →
  `available: true`. Прочитано обратно: **34 территории**, CAN есть; статус
  `AVAILABLE_FOR_SALE_UNRELEASED_APP` — тот же, что у USA/ESP (приложение ещё
  не выпущено).
- четыре покупки `aura.topup.usd10/25/50/100`: у каждой своя доступность —
  `POST /v1/inAppPurchaseAvailabilities` с прежними 33 + CAN,
  `availableInNewTerritories: false`. Прочитано обратно: 34, CAN есть; статус
  `WAITING_FOR_REVIEW` не изменился.

## Play — не через API

`edits.countryavailability.get` читается ключом `play-billing-api@aura-2781b`
(`~/Downloads/aura-2781b-dcd1dfc5ef14.json`): 34 страны, CA нет. Изменить
список стран production Android Publisher API не позволяет, а прав на релизы у
этого аккаунта нет. **Осталось владельцу:** Play Console → Production →
Countries/regions → Canada.

## TECH-DEBT `aura-app`

`develop` @ `5a1432a`, запушено: #11 — Канада в Play (App Store сделан);
#12 — экран телефона с `SMS_REGIONS` ещё не в сборках сторов.
Номер #11 был намечен в спеке `AURAT-0080` — при её одобрении ей #13.
