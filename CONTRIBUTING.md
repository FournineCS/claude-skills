# Contributing

Thanks for your interest in contributing! This repo is a collection of [Claude Code](https://docs.claude.com/en/docs/claude-code) skills — shareable instructions, scripts, and references that Claude loads on demand.

## Adding a New Skill

1. **Create the skill directory** under `skills/<your-skill-name>/`.
2. **Add a `SKILL.md`** with YAML frontmatter:

   ```markdown
   ---
   name: your-skill-name
   description: "One-paragraph description with trigger phrases. Be specific — Claude uses this to decide when to load the skill."
   ---

   # Your Skill Title

   Instructions for Claude...
   ```

3. **Optional subdirectories:**
   - `scripts/` — shell scripts, Python helpers, etc.
   - `references/` — supplementary docs Claude loads on demand
   - `evals/` — evaluation cases (`evals.json`)

4. **Add an entry** to the table in [README.md](README.md).

5. **Open a PR.**

## Skill Quality Bar

- **Safety first.** Any destructive operation (file deletion, network calls, system changes) must require explicit user confirmation. Default to read-only / preview.
- **No hardcoded paths or personal info** — usernames, machine names, emails, API keys, etc.
- **Cross-platform where applicable.** macOS skills should work on both Intel and Apple Silicon. Linux skills should not assume a distro.
- **Quote your shell variables.** Run `bash -n` and ideally `shellcheck` before submitting.
- **Idempotent.** Re-running a skill should not break anything.
- **Small surface area.** A skill should do one thing well, not be a kitchen sink.

## Code Style

- Bash: prefer `[[ ]]` over `[ ]`, quote variables, `set -e` only when appropriate.
- Markdown: keep lines reasonable, use fenced code blocks with language hints.
- Keep `SKILL.md` focused on what Claude needs to know. Move long-form docs to `references/`.

## Reporting Issues

Use the GitHub issue templates. Include:
- Skill name
- macOS/OS version
- Claude Code version
- Reproduction steps

## License

By contributing, you agree your contributions will be licensed under the [MIT License](LICENSE).
