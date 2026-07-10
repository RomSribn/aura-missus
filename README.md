# Missus — Private Project Knowledge Base

Everything about the project that does not belong in the public codebase.

## Structure

| Folder | What's inside |
|--------|---------------|
| `brain/` | Knowledge base — features, tasks, decisions, investigations |
| `design/` | Visual references — screenshots, ideas for frontend |
| `inputs/` | Raw material from stakeholders and workers |
| `secrets/` | Credentials, tokens, provider API keys |

Each folder has its own `README.md` (what it is) and, where applicable, `RULES.md` (conventions for files inside).

## Using this with workspace-template

- Every slave worktree has paired `master/` and `missus/` — work on the same feature branch in both.
- Cross-repo commits happen through the `wts-commit` skill.
- `brain/` conventions are enforced by the `wts-task` skill.

This skeleton is the default shape. Add folders, rename prefixes, customise — adjust `.wts/config` at the workspace root to keep tooling in sync.
