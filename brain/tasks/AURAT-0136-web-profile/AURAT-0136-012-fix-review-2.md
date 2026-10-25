# AURAT-0136-012 — Fix: второе ревью манора

Date: 2026-10-25

Владелец: «ок» + второе ревью манора (фото, загрузка профиля, длина полей, разметка — приняты).
Сделано по его предложениям:

- `preparePhoto`: `context.imageSmoothingQuality = 'high'` перед `drawImage` — уменьшение в 5–6
  раз (24 Мп → 1024) без зубцов.
- `use-profile-photo`: загрузка разделена на `send` (пережатие → проверка → `PUT`, возвращает
  причину отказа) и `upload`, который ловит любое исключение (`toBlob`, декод) → `failed`;
  «Uploading…» больше не может зависнуть.
- FAQ «How do sessions work?» (en + 23 языка): «…pay from your Aura balance. At the booked time the
  session starts in your chat with them, and you can add minutes while it runs. Messaging an advisor
  before you book is free.» — больше нет спора «чат открывается со стартом сессии» / «писать
  бесплатно» (`AURAT-0127`).
- Тесты: сглаживание в `prepare-photo.test.ts`; исключение пережатия → «The photo could not be
  uploaded» без запроса — в `profile.test.tsx`.

Проверки: typecheck, lint, vitest (88 / 1574), build — зелёные. Нестабильный
`booking.test.tsx › a short balance…` (тайм-аут при высокой нагрузке, видел и slave-2) в этом прогоне
прошёл; к 0136 отношения не имеет.
