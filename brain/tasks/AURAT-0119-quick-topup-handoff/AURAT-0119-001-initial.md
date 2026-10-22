# AURAT-0119-001 — Initial

Date: 2026-10-22
Slave: `slave-1`, ветка `feature/AURAT-0119-quick-topup-handoff` от `develop` @ `caf8736`.
Фича: `AURAF-0019` (checkout), связано с `AURAT-0020` (две модалки на iOS), `AURAT-0116`.

Владелец (проверка `AURAT-0116` на Android, SM-A505FN): «переход с review booking работает
теперь плавнее, чем с quick booking, посмотри почему так». Разбор: Review — экран стека,
переход в Profile — анимация стека, шторка Top Up выезжает одновременно. Quick book — по
очереди: quick sheet уезжает (200 мс, затемнение гаснет, виден тред) → `onClosed` → резкое
переключение вкладки на Profile → затемнение и шторка Top Up снова (320 мс). Ожидание `onClosed`
нужно только iOS (`AURAT-0020`), Android ждёт впустую.

Предложено: (а) переключать вкладку сразу, Top Up открывать после `onClosed` (iOS); (б) на
Android не ждать `onClosed`. Владелец: «делай след исправление» — делаю (а) + (б).
