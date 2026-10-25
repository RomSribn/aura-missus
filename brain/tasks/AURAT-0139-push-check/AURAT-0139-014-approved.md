# AURAT-0139-014 — approved

Дата: 2026-10-25. Владелец: «да, делай wts-release».

Итог: пуши о сообщениях проверены (работают); свои пуши из Firebase Console — показ на переднем плане
(iOS `firebase.json`, Android notifee), канал `announcements`, иконка-орб и coral-тон, тап: `advisorId` → тред,
`action=daily-card` → карта дня, `action=rate` → страница в сторе. Android проверен владельцем на staging-APK,
в т.ч. холодный старт. В `develop`: `5f4f16e`, `0b5ac7b`. iOS — вне задачи (сборка на ревью Apple).

Не в этой задаче: прод-сборка Play (новый versionCode) — манор; AURAT-0140 (согласие на промо) → часть 4
(topic `promo`, Toggle в Profile); нативный попап оценки и Firebase In-App Messaging / Analytics — отдельными задачами,
если понадобятся.
