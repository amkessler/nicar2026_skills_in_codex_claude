# nicar2026_skills_in_codex_claude

Demo project for NICAR 2026 showing how to use AI "skills" — modular, self-contained instruction
packages that extend Claude/Codex's capabilities for domain-specific tasks. The primary example
skill is `fecfile` for analyzing FEC campaign finance filings. The `skills/` directory includes
additional example skills and tools for creating new ones.

## Active skills

Claude Code and Codex CLI each read skills from their own directory because they are separate tools
with separate configuration systems. The skills themselves share the same `SKILL.md` format, so
the same skill files work in both tools — they just need to be present in the right place.

| Tool | Active skills directory | How skills trigger |
|------|------------------------|--------------------|
| Claude Code | `.claude/skills/` | Auto-triggers based on `description` frontmatter, or invoke with `/skill-name` |
| Codex CLI | `.codex/skills/` | Auto-triggers based on `description` frontmatter, or invoke with `$skill-name` |

Both directories in this repo contain the same four skills: `fecfile`, `weather-forecast`,
`image-rotator`, and `skill-creator`.

The `skills/` directory at the repo root is the **teaching copy** — it's the canonical source
used in the NICAR presentation. The `.claude/skills/` and `.codex/skills/` directories are the
**active copies** that each tool actually reads.

### Enabling repo-local skills

Claude Code picks up `.claude/skills/` automatically when you open the project.

For Codex, set `CODEX_HOME` to point at this repo's `.codex/` directory:

```bash
CODEX_HOME=/path/to/this/repo/.codex codex
```

Or symlink individual skills into your global Codex skills folder:

```bash
ln -s /path/to/this/repo/.codex/skills/fecfile ~/.codex/skills/fecfile
```