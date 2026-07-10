# Investigations — Rules

## Format

Each investigation = folder with report file(s).

```
investigations/
  PI-0001-short-name/
    PI-0001-short-name.md       ← main report
    PI-0001-supporting.md       ← optional extras (prefixed!)
```

## Rules

1. **Prefix:** `PI-NNNN-short-name/`
2. **One investigation = one folder.** Even if a single file.
3. **Report file inside.** Named same as folder or by topic.
4. **History, not living.** Captures what was known at the time; do not rewrite —
   open a new investigation if new research is needed.
5. **Next number:** `ls investigations/ | grep '^PI' | sort | tail -1`
