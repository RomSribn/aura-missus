# Roadmaps — Rules

## Format

```markdown
# PR-NNNN — Roadmap Title

**Source:** original planning source path
**Ingested by:** PI/PT artifact and date
**Authority:** intent / advisory / approved scope

## Priorities
{Time-bound product or delivery priorities}

## Artifact Map
{Roadmap item → PF / PI / PD / PT mapping}
```

## Rules

1. **Flat files, no folders.** `PR-NNNN-short-name.md` directly in `roadmaps/`.
2. **Snapshots, not live tasks.** Do not track execution status here.
3. **Always map to internal artifacts.** A roadmap item should point to
   PF/PI/PD/PT when such an artifact exists.
4. **Keep source provenance.** Preserve original source path/date and the
   ingestion artifact.
5. **Next number:** `ls roadmaps/ | grep '^PR' | sort | tail -1`
