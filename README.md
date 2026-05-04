# Claude Skills

A collection of open-source [Claude Code](https://docs.claude.com/en/docs/claude-code) skills for everyday engineering and system tasks.

Skills are reusable instructions, scripts, and references that Claude Code loads on demand to perform specialized workflows.

## Available Skills

| Skill | Description |
|-------|-------------|
| [mac-cleanup](skills/mac-cleanup/) | Comprehensive MacBook cleanup, disk analysis, and system health audit. Read-only analysis followed by interactive, approval-gated cleanup. |

## Installation

Skills live in `~/.claude/skills/`. Install one by copying or symlinking it:

```bash
# Clone the repo
git clone https://github.com/FournineCS/claude-skills.git
cd claude-skills

# Symlink a skill (recommended — get updates with git pull)
ln -s "$PWD/skills/mac-cleanup" ~/.claude/skills/mac-cleanup

# Or copy it
cp -R skills/mac-cleanup ~/.claude/skills/mac-cleanup
```

Restart Claude Code or start a new session — the skill will be auto-discovered and listed in the available skills.

## Using a Skill

Skills auto-trigger on relevant prompts (e.g. "clean up my Mac", "free up disk space"), or you can invoke one explicitly via the `/` menu.

## Repository Layout

```
claude-skills/
└── skills/
    └── <skill-name>/
        ├── SKILL.md         # Skill manifest + instructions
        ├── scripts/         # Helper scripts
        ├── references/      # Reference docs Claude loads on demand
        └── evals/           # Evaluation cases
```

## Contributing

Contributions welcome. To add a new skill:

1. Create `skills/<your-skill>/` with a `SKILL.md` containing frontmatter (`name`, `description`).
2. Keep destructive operations behind explicit user approval.
3. Add an entry to the table above.
4. Open a PR.

## License

[MIT](LICENSE)
