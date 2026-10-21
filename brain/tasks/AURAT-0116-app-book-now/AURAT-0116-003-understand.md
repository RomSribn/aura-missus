# AURAT-0116-003 — Understand

Date: 2026-10-21

На `BookSessionScreen` для «сегодня» первой в сетке времени стоит «Now», когда сервер
говорит `availability.instantAvailable === true` для выбранной длительности. Выбор «Now» →
тот же Review и та же оплата, но бронь уходит с `startNow: true` и без `startsAt` (как Quick
book в чате). Ближайший слот сетки освобождается сам после `AURAT-0115` — в приложении это не
трогаем.
