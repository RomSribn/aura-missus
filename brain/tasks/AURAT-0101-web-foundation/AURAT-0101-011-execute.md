# AURAT-0101-011 — Execute (i18n, from 010)

Date: 2026-10-20
Changes staged, **not committed**.

## Done (aura-web)

- Deps: `i18next` 26.5, `react-i18next` 17.1.
- `shared/config/languages.ts` — `LANGUAGES` (24: en + EU), `Language`, `SOURCE_LANGUAGE`.
- `shared/i18n/` — `Translation<Source>` (keys of the English source, each a string), `I18nNamespace`
  (source + a lazy loader per language, `Record` over all languages), `initI18n` (i18next with a
  namespace backend: English bundled, other languages one chunk per namespace × language, loaded before
  the first render; `<html lang>` follows the language), `detectLanguage` (browser preference → base code
  → else `en`).
- Namespaces: `shared` (`shared/config/locales/` — `close`), `app` (`app/config/locales/` — nav, GuestGate,
  Not found, route error). 24 files each; `ResourceNamespaceMap` augmentation per namespace → typed keys.
  `app/config/copy.ts` removed; Sheet's close label, layout, GuestGate, NotFound, RouteError use `t()`.
- `app/config/i18n.ts` — `I18N_NAMESPACES`; `main.tsx` renders after `initI18n`.
- `vitest.setup.ts` initialises i18n with direct imports (loading `@/shared` there broke `vi.mock` of
  the api modules); `tsconfig.app` now includes it; eslint override for its imports.
- Vite: `i18n` vendor chunk (index 461 kB, under the 500 kB warning).
- Tests: every namespace × language — same keys as English, no blank string, same `{{placeholders}}`;
  setup's namespace list = `I18N_NAMESPACES`; `detectLanguage`; the shell rendered in German.
  Verified by hand: a key removed from `de.ts` or a missing `mt.ts` fails `typecheck`.
- README: «Translations».

## The rule (owner: «запиши правило про добавления переводов в каждой задаче»)

- `<workspace>/.claude/aura-web-build-rules.md`: Technology Stack (i18n), slice `config/` = locales,
  **hard rule 9** «Every task ships its strings in every language», new section «Translations»
  (layout of `config/locales/`, registration, compiler + test enforcement, interpolation / plurals,
  `Intl`, brand names, lazy loading). Old line «Copy is English … no i18n yet» replaced.
- `<workspace>/.claude/skills/react-web-app/SKILL.md`: `config/` line + checklist item.
- Both files are workspace-level (the workspace is not a git repo) — the change is live for every slot
  and the manor, but is not versioned.
- missus `AURAF-0020`: section «Languages», the «NOT in scope: i18n» line removed.

## Checks

lint (eslint + steiger) ✓ · typecheck ✓ · test — 14 files, 123 tests ✓ · build ✓
(index 461 kB, i18n 59 kB, firebase 67 kB, 46 language chunks) · prettier ✓.

## Note

Translations of the 23 languages are written in this task without a native-speaker review (rule:
review is welcome, does not block). Register: informal where consumer apps usually are (de, es, nl, sv,
da, fi, et, hu, ro, …), formal elsewhere (bg, cs, el, fr, hr, lt, lv, pt, sk, sl).

Next: owner review in IDE → commit → merge gate.
