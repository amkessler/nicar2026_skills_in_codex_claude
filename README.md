# nicar2026_skills_in_codex_claude

Demo project for NICAR 2026 showing how to use AI "skills" — modular, self-contained instruction
packages that extend Claude/Codex's capabilities for domain-specific tasks. The primary example
skill is `fecfile` for analyzing FEC campaign finance filings. The `skills/` directory includes
additional example skills and tools for creating new ones.

## What is a skill?

When you ask an AI assistant to help with data analysis, it has to figure out on the fly how to
approach the problem — which fields exist, how to handle edge cases, what the right tool or
library is. Without guidance, it may guess at field names, rewrite the same boilerplate code
every session, or make different choices each time. A colleague asking the same question might
get a different approach, different column names, different aggregation logic.

A **skill** solves this by giving Claude or Codex a standing set of instructions before the
conversation begins — a documented, version-controlled playbook that the AI follows every time.
A skill is just a folder containing a `SKILL.md` file (plain Markdown with a short YAML header)
plus any helper scripts or reference documents the AI should use. You write it once, commit it
to your repo, and every session — and every collaborator — gets the same behavior.

### How skills get invoked

Skills can trigger in two ways:

**Automatically** — The AI reads the `description` field in each skill's `SKILL.md` header and
decides whether the skill is relevant to your request. If you type "Analyze filing 1896830",
Claude sees the `fecfile` skill description, loads its instructions, and knows to start with
`--summary-only` before pulling full schedules. You don't have to ask for it by name.

**Manually** — You can invoke any skill directly by typing `/skill-name` (Claude Code) or
`$skill-name` (Codex). This is useful when you want a specific skill regardless of what you
typed, or when you want to be explicit.

### Why skills matter for data journalism

Skills aren't just convenient — they address real problems that come up when you use AI tools
for reporting:

**Reproducibility.** A skill codifies your analytical approach the same way a data dictionary
or style guide does. When your methodology is written down in `SKILL.md` and committed to
version control, you can explain to an editor or a reader exactly how the analysis was
structured. Anyone who clones the repo gets the same AI behavior you had.

**Field name accuracy.** FEC filings have specific, non-obvious field names like
`col_a_total_receipts` and `contributor_state`. Without a skill, an AI might confidently use
a plausible-sounding but wrong field name. The `fecfile` skill includes reference files with
authoritative field mappings and explicitly instructs the AI not to guess — only to use names
it can verify. This is the difference between an analysis you can trust and one you have to
fact-check line by line.

**Handling data at scale.** Major committee filings (ActBlue, WinRed, presidential campaigns)
can contain hundreds of thousands of rows. A naive AI session might try to load all of it into
memory at once. The `fecfile` skill has explicit rules: always check `--summary-only` first,
use `--stream` mode for large filings, post-filter with pandas before presenting results. These
aren't suggestions — they're baked into the skill's instructions so the right approach happens
automatically.

**Bundled, deterministic scripts.** Skills can include executable scripts alongside their
instructions. The `fecfile` skill bundles `fetch_filing.py`, which always parses FEC data the
same way using the same library. Claude runs the script rather than rewriting parsing logic
from scratch each time. This means the data comes from a known, testable code path — not
improvised code that varies session to session.

**Portability.** Skills committed to `.claude/skills/` and `.codex/skills/` travel with the
repo. A colleague who clones the project gets all four skills automatically. There's no manual
setup, no "paste this into your system prompt" step. The workflow is self-contained.

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