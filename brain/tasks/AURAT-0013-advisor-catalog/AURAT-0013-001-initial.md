# AURAT-0013-001 — Initial input

Date: 2026-08-13
Slave: `slave-1` (aura-bff-manor), branch `feature/AURAT-0013-advisor-catalog`
Master @ `8c3734e` (develop), missus @ `b41203e`

## What the user asked

> нужно заменить всех наших адвайзоров на этих с документа
> `/Users/romansribnyi/Downloads/ADVISORS REAL.xlsx`

The file holds **8 advisors**, three fields each: name (col A), a floating
photo over col B, and a bio (col C). No header row (`dimension A2:C9`).

## How the ask changed during intake

The request as phrased was "replace the list". Reading the code showed there is
no list to replace **in this repo**: the advisor personas are a hardcoded
`ADVISORS` array in the *app* (`aura-app-manor`,
`src/entities/advisor/config/advisors.ts`), whose own comment reads *"Stands in
for the advisors API until a backend exists."* The BFF's `advisors` table holds
only `id` + `priceMinorPerMinute`.

When shown this, the user redirected:

> мы храним адвайзоров в маноре? данные про адвайзоров должны храниться в базе
> данных

So the task is **not** an edit to the app's seed array. It is the advisor
catalog feature the app's placeholder was always waiting for — BFF-side, in
Postgres. This closes **TECH-DEBT #10**.

## Decisions taken during intake (user, this session)

| Question | User's answer |
|---|---|
| ID minting (authority is `aura-app-manor`) | "номер ставь любой, следующий логический" → `AURAT-0013`; counter bumped in `aura-app-manor/active-work.md` |
| Where avatars live | Object storage; user has created the bucket |
| Prices | "проставь сам рандомно, вилка 2-4 доллара за минуту" |
| Missing text fields | Derive from the bios |
| `Dreams` category (no dream reader among the 8) | "удаляй тогда, пофиг" |
| Old advisor ids + their dev-DB threads | "пофиг на старые треды, можешь даже удалить их" |
| App-side switch to the endpoint | "сразу следом" — separate task, next |

Assistant's calls, stated and not objected to: `tint` stays app-side (pure
design), `rating`/`reviews` are not modelled (invented numbers in the DB; real
reviews are their own feature), `online` keeps coming from presence, and the DB
stores an `avatarKey` with the storage base URL in config rather than a baked
full URL — so changing bucket/CDN needs no migration and dev/prod can differ
(`AURAD-0005` already forbids envs sharing anything).

## Work done before the task folder existed

- xlsx unpacked and parsed (no `openpyxl`; the system python's `expat` is
  broken, so parsing was done in Node against `sharedStrings.xml`,
  `worksheets/sheet1.xml` and `drawings/drawing1.xml`).
- Photos assigned to rows by anchor coverage — the images float, so each was
  given to the row it overlaps most.
- **`labsang` / `alisher` photos swapped** against their anchor positions. The
  river/chapan portrait matches Alisher's bio ("I drowned after falling into a
  river"), his Central-Asian name and dress on three counts; the anchor only
  records where someone dragged the image. Flagged to the user, who said "вроде
  норм все"; the swap was made and reported.
- Photos delivered to `/Users/romansribnyi/Documents/advisors/`
  (`original/` untouched, `avatar/` 512×512 square, face-checked) for the user
  to upload to the bucket.
- Derived dataset (roles, categories, taglines, specialties, greetings, prices)
  in the session scratchpad as `advisors-real/derived.json`, each field
  carrying a `_derivedFrom` quote from the source bio.

## Next

Step 002 — check the shared brain for existing state.
