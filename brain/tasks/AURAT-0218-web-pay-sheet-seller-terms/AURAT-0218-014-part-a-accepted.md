# AURAT-0218-014 — Часть A принята владельцем

Дата: 2026-11-18. Владелец, проверка на web-dev после мёржа (develop `5d78c37`): «Принято».

Принято: галочка Terms перед оплатой картой в Book / Top up / Extend, сессия Stripe открывается после
первой отметки, продавец и ссылки (§07 → `#s07`), «Terms of Service» во входе и в `/me`.

Задача остаётся **in-progress**: часть B (`termsConsent` в `CardTopUpRequest`, версия из
`TERMS_CONSENT_VERSIONS`) ждёт контрактов `v0.35.0` из BFF-части `AURAT-0216`. До неё ворота live
`AURAD-0023` по согласию с Terms не закрыты.
