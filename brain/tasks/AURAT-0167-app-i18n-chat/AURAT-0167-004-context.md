# AURAT-0167-004 — context

Дата: 2026-11-06.

## Источники
- Код slave-0 @ `dc98590` (ground truth): `screens/chats`, `screens/chat-thread`, `features/chat`,
  `features/tarot-spread`; `i18next/no-literal-string` прогнан по четырём слайсам (30 находок в `.tsx`) + grep строк
  в `.ts`.
- aura-bff (манор): `sessions.service.ts` `MARKER_CONTENT` — «Your session has started» / «Your session has
  finished», ровно эти две строки, без точки.
- `AURAI-0010`, решение владельца 5: серверный контент v1 английский, маркеры переводит клиент по точному совпадению.
- Образцы: `AURAT-0166` (модель хранит причину, лист переводит при отрисовке; `@sensitive payment`; минус CLDR),
  `AURAT-0165` (a11y «действие, {{name}}»; `shared:minutes`; передал `use-quick-book.ts`), `AURAT-0162` (`@max` по
  замеру).
- aura-web `translate.mjs lookup`: совпадают по-английски — `message:marker.started/finished`,
  `message:preview.photo/video/voice`, `message:you`, `message:refused.empty/desk`, `message:attachment.gone`,
  «Couldn’t load» (normalized), `conversation-list:online`, `chats-page:empty.title/text`, «Browse advisors»,
  «All advisors», `send-message:send`, `tarot-pick:title/sub/turning/resultEyebrow`, `session:invite.eyebrow/title/
  text/book`, `extend-session:choose`, `shared:close`. Нет на вебе: «Away», «Book now», поле ввода, лист источника,
  статусы голоса / видео, «Tap to retry», «Not delivered · Tap to resend», ошибки черновика, «Choose a length».

## Что нашёл
- **Склейки и имена в падежном месте:** a11y строки чата `Chat with ${name}`; `Session live · ${n} min left` (без
  плюрала); `${type} · ${size}` и `${received} of ${total}`; `Sending ${pct}%`; `${i} of ${n}` в просмотре фото;
  `${catalogDiscountLine} — applied for you`; `Retry loading ${fileName}`; таро — `You chose ${card}`,
  `Open ${card} full screen` (имя карты — английское из колоды, в славянских языках требует падежа; «You chose» —
  род пользователя в pl / cs / sk / hr / sl / lt / lv / ro …); быстрая бронь `${'Start now'|'Book'} · ${cost}`.
- **Модель держит готовый текст:** `use-attachment-draft` хранит ошибку строкой (`refuseDraft` возвращает
  предложение) — смена языка оставит английский; `use-chat-thread` кладёт `author: 'You'` в просмотрщик;
  `use-quick-book` / `use-extend-checkout` — английские CTA, ошибки, тосты.
- **Маркеры:** `map-message.ts` распознаёт начало регуляркой `/\bstarted\b/i` только для тона; текст показывается
  как пришёл (`SessionMarker`, превью списка `— ${text}`). Комментарий «the app never composes them» станет неправдой.
- **a11y:** кнопка продления в шапке — подпись «Extend the session» при видимом «Extend +10 min» (label-in-name);
  плашка ошибки черновика — подпись «Dismiss» заслоняет саму ошибку для чтеца экрана.
- **Капс (`textTransform`)**: эйбрау приглашения, `ThreadDivider` (маркеры и строка расклада), `SpreadEyebrow`,
  ключевые слова карты — el пишется капсом без тонуса.
- **Уже переведено рядом:** `paid-session` (Extend +N min, лист блоков), `store-topup` (PayCompact, PayNotice,
  CheckoutButton), `features/booking` (QuickBookSheet), `app:tabs.chats`, `shared:close`, `shared:day.today`,
  `shared:minutes`.
- **Вне i18n, заметил:** заголовок списка сообщений — всегда «Today», даже над историей прошлых дней.

## Противоречия
- Заглушка `001` (до поправки) выносила маркеры за объём; поправка координатора и решение 5 `AURAI-0010` их
  включают — беру по решению владельца.
- Заглушка предлагает взять `book-session:started` / `review.errors.*` для быстрой брони. Это namespace другого
  экрана того же слоя (FSD: срез не опирается на соседа), и английский ошибок различается («No longer available —
  try another time.» против «That time is no longer available. Pick another one.»). Предлагаю свои ключи с
  переводами, скопированными оттуда, где английский совпадает (спека).
