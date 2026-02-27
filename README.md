# nicar2026_skills_in_codex_claude

Demo project for NICAR 2026 showing how to use AI "skills" — modular, self-contained instruction
packages that extend Claude/Codex's capabilities for domain-specific tasks. This repo includes
four skills: `fecfile` for analyzing FEC campaign finance filings, `weather-forecast` for
fetching 7-day forecasts, `image-rotator` for rotating images, and `skill-creator` for building
new skills. Together they demonstrate the range of what skills can do — from domain-specific
data analysis to simple utilities to meta-tooling for the skill system itself.

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
`--summary-only` before pulling full schedules. Type "What's the weather in Memphis this week?"
and the `weather-forecast` skill triggers instead, running the geocoding and forecast scripts in
the right order. Type "Rotate this image 90 degrees" and `image-rotator` loads. You don't have
to ask for any skill by name — the description does the routing.

**Manually** — You can invoke any skill directly by typing `/skill-name` (Claude Code) or
`$skill-name` (Codex). For example, `/skill-creator` launches the skill-building workflow
regardless of what else you typed. This is useful when you want a specific skill explicitly, or
when you're building and testing a new skill and want to force it to load.

### Why skills matter for data journalism

Skills aren't just convenient — they address real problems that come up when you use AI tools
for reporting:

**Reproducibility.** A skill codifies your analytical approach the same way a data dictionary
or style guide does. When your methodology is written down in `SKILL.md` and committed to
version control, you can explain to an editor or a reader exactly how the analysis was
structured. Anyone who clones the repo gets the same AI behavior you had.

**Field name accuracy.** FEC filings have specific, non-obvious field names like
`col_a_total_receipts` and `contributor_state`. Without a skill, an AI might confidently use
a plausible-sounding but wrong field name. The `fecfile` skill includes reference files
(`FORMS.md` and `SCHEDULES.md`) with authoritative field mappings and explicitly instructs the
AI not to guess — only to use names it can verify. The `weather-forecast` skill does the same
for the Open-Meteo API's response structure, ensuring the AI uses the correct JSON fields for
temperature, wind, and WMO weather codes rather than inventing plausible-sounding alternatives.
This is the difference between an analysis you can trust and one you have to fact-check line
by line.

**Handling data at scale.** Major committee filings (ActBlue, WinRed, presidential campaigns)
can contain hundreds of thousands of rows. A naive AI session might try to load all of it into
memory at once. The `fecfile` skill has explicit rules: always check `--summary-only` first,
use `--stream` mode for large filings, post-filter with pandas before presenting results. These
aren't suggestions — they're baked into the skill's instructions so the right approach happens
automatically.

**Bundled, deterministic scripts.** Skills can include executable scripts alongside their
instructions. The `fecfile` skill bundles `fetch_filing.py`, which always parses FEC data the
same way using the same library. The `weather-forecast` skill bundles two scripts:
`get_coordinates.py` (a local database of US city coordinates — no network call needed) and
`get_forecast.py` (the Open-Meteo API call). The skill's instructions require Claude to always
run them in that order, making the two-step geocode-then-forecast workflow reproducible and
explicit. The `image-rotator` skill bundles `rotate_image.py`, so rather than writing PIL
rotation code from scratch each time — and potentially getting the `expand=True` flag wrong or
saving in the wrong format — Claude runs a known-good script. In all three cases, the data or
output comes from a tested, version-controlled code path rather than improvised code that
varies session to session.

**Portability.** Skills committed to `.claude/skills/` and `.codex/skills/` travel with the
repo. A colleague who clones the project gets all four skills automatically. There's no manual
setup, no "paste this into your system prompt" step. The workflow is self-contained.

**Building your own.** The `skill-creator` skill is itself an example of this pattern applied
recursively — it bundles `init_skill.py` (scaffolds a new skill directory with a template
`SKILL.md`) and `package_skill.py` (validates and zips a skill for distribution), and its
`SKILL.md` walks through a six-step creation process. If you want to build a skill for your
own beat — court records, property data, Census API, a local government's open data portal —
`skill-creator` gives you the tooling and the process to do it consistently.

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