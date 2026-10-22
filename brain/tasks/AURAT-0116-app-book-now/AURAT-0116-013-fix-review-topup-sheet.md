# AURAT-0116-013 — Fix: Top Up с Review не открывает шторку

Date: 2026-10-22

Замечание владельца по проверке на устройстве: переход на Top Up из Quick book сразу открывает
модалку пополнения, а с экрана Review booking — нет (просто Profile). Нужно, чтобы открывало.

Причина: `use-book-review.ts` `onTopUp` шлёт `MAIN › { screen: PROFILE, params: { sheet } }` —
`sheet` уходит стеку Profile, а читает его `PROFILE_ROOT` (`use-profile.ts`,
`route.params?.sheet`). Ошибку типов скрывал `as never`. Quick book и тред шлют вложенно:
`PROFILE › { screen: PROFILE_ROOT, params: { sheet: 'topup' } }`. Баг старше 0116 (с
`AURAF-0019`), чиню в этой же задаче по просьбе владельца.
