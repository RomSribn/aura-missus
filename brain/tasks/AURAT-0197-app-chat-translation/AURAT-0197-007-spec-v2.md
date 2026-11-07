# AURAT-0197-007 — spec v2 (поверх `005`)

Дата: 2026-11-07 · Статус: **одобрено владельцем (см. `008`)**. Всё из `005` в силе, кроме изменений ниже.

## Решения (§11 `005`)
1. **А** — галочка блокирует отправку, пока согласие не сохранено; набирать и прикреплять можно.
2. **А** — перевод на другом языке: английский + «Перевод · Deutsch · Показать», по кнопке — перевод.
3. **А** — переключатель в профиле только при согласии текущей версии.

## §4 — монотонное слияние перевода (замечание `006`)

Одно правило в `lib/translation.ts`, им пользуются все пути (`mergeServerMessages` для известных сообщений,
`message.translated`, `translations` догонки, `refreshSpreads`):

```ts
const RANK = { pending: 0, failed: 1, translated: 2 } as const;
/** Новый перевод сообщения поверх того, что держит тред, — или прежний. */
mergeTranslation(held?: MessageTranslation, incoming?: MessageTranslation): MessageTranslation | undefined
```

- `incoming` нет → `held` (опоздавший DTO без поля ничего не стирает);
- `held` нет → `incoming`;
- `held.status === 'translated'` → `held` всегда (окончательный: сервер его не меняет, язык зафиксирован в момент
  прихода ответа — `AURAT-0195` §1);
- иначе `incoming`, если `RANK[incoming] > RANK[held]`, иначе `held`: `pending → failed → translated` можно,
  `failed → pending` (опоздавшая страница) — нет.

Сообщение, у которого перевод не изменился, остаётся тем же объектом — `React.memo` строк не перерисовывает, а
`setThreads` возвращает `prev`, когда не изменилось ничего.

Тесты (добавляются к §8 `005`): `mergeTranslation` по всем парам; `ChatProvider` — гонка «событие раньше истории»
(`message.translated: translated`, затем синк со страницей, где то же сообщение `pending` → остаётся
`translated`); то же для `translations` догонки с `pending` и для `failed` поверх `translated`; `failed`, затем
`translated` по событию → `translated`.
