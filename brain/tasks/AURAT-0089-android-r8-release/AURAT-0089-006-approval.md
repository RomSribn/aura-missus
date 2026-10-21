# AURAT-0089-006 — Одобрение

Дата: 2026-10-21

Владелец одобрил спеку `005` как есть: R8 + `proguard-android-optimize.txt`,
keep-правила (Nitro + что потребует R8), убрать `backgroundColor` у `StatusBar`
на онбординге. `edgeToEdgeEnabled` остаётся false, `shrinkResources` не включаем,
AGP не трогаем.
