# Claude behavioral rules

Behavioral ruleset for Claude Code agents — Karpathy thinking discipline + Caveman output compression. See [CLAUDE.md](CLAUDE.md) for the full spec.

## Global install

Applies to every Claude Code session on the machine:

```bash
mkdir -p ~/.claude
curl -fsSL https://git.recwebnetwork.com/claude/CLAUDE.md -o ~/.claude/CLAUDE.md
```

## Project install

Applies only to the current project (run from the project root):

```bash
curl -fsSL https://git.recwebnetwork.com/claude/CLAUDE.md -o ./CLAUDE.md
```

## Update

Re-run the same command — it overwrites in place.

## What's inside

- **Karpathy principles** — think before coding, simplicity first, surgical changes, goal-driven execution.
- **Caveman style** — terse output, drop filler, keep technical substance exact.

Full rules in [CLAUDE.md](CLAUDE.md).
