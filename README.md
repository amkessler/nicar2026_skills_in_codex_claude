# NICAR 2026 Session on using "Skills"

This project accompanies the NICAR 2026 session showing how to use AI "skills", the modular, self-contained instruction packages that extend Claude/Codex's capabilities for domain-specific tasks.

This repo includes six skills: `fecfile` for analyzing FEC campaign finance filings (from [Matt Hodges](https://github.com/hodgesmr/agent-fecfile)), `weather-forecast` for fetching 7-day forecasts, `image-rotator` for rotating images, `skill-creator` for building new skills, `state-county-rankings` for ranked county demographics from local CSVs, and `majority-minority-change` for threshold-crossing analysis between Census snapshots. Together they demonstrate the range of what skills can do, from domain-specific data analysis to simple utilities to meta-tooling for the skill system itself.

## Attendee Quickstart

For a step-by-step tutorial with copy/paste commands, see:

-   `01_quickstart_underlying_code.md`
-   `02_skills_learning_notes.md` (session notes, exercises, and troubleshooting)
-   `03_fecfile_examples.md` (worked FEC filing examples)
-   `04_build_a_skill_from_your_code.md` (build a skill from existing R/Python scripts)
-   `05_skill_build_example_state_county_rankings.md` (rank counties within a state from local demographics CSVs)
-   `06_skill_build_example_majority_minority_change.md` (analyze threshold crossings between two Census snapshots)

## What is a skill?

When you ask an AI assistant to help with data analysis, it has to figure out on the fly how to approach the problem: which fields exist, how to handle edge cases, what the right tool or library is. Without guidance, it may guess at field names, rewrite the same boilerplate code every session, or make different choices each time. A colleague asking the same question might get a different approach, different column names, different aggregation logic.

A **skill** solves this by giving Claude or Codex a standing set of instructions before the conversation begins, a documented, version-controlled playbook that the AI follows every time. A skill is just a folder containing a `SKILL.md` file (plain Markdown with a short YAML header) plus any helper scripts or reference documents the AI should use. You write it once, commit it to your repo, and every session (and every collaborator) gets the same behavior.

### How skills get invoked

Skills can trigger in two ways:

**Automatically**. The AI reads the `description` field in each skill's `SKILL.md` header and decides whether the skill is relevant to your request. If you type "Analyze filing 1896830", Claude sees the `fecfile` skill description, loads its instructions, and knows to start with `--summary-only` before pulling full schedules. Type "What's the weather in Memphis this week?" and the `weather-forecast` skill triggers instead, running the geocoding and forecast scripts in the right order. Type "Rotate this image 90 degrees" and `image-rotator` loads. You don't have to ask for any skill by name — the description does the routing.

**Manually**. You can invoke any skill directly by typing `/skill-name` (Claude Code) or `$skill-name` (Codex). For example, `/skill-creator` launches the skill-building workflow regardless of what else you typed. This is useful when you want a specific skill explicitly, or when you're building and testing a new skill and want to force it to load.

### Why skills matter for data journalism

Skills aren't just convenient, they address real problems that come up when you use AI tools for reporting:

**Reproducibility.** A skill codifies your analytical approach the same way a data dictionary or style guide does. When your methodology is written down in `SKILL.md` and committed to version control, you can explain to an editor or a reader exactly how the analysis was structured. Anyone who clones the repo gets the same AI behavior you had.

**Field name accuracy.** FEC filings have specific, non-obvious field names like `col_a_total_receipts` and `contributor_state`. Without a skill, an AI might confidently use a plausible-sounding but wrong field name. The `fecfile` skill includes reference files (`FORMS.md` and `SCHEDULES.md`) with authoritative field mappings and explicitly instructs the AI not to guess, only to use names it can verify. The `weather-forecast` skill does the same for the Open-Meteo API's response structure, ensuring the AI uses the correct JSON fields for temperature, wind, and WMO weather codes rather than inventing plausible-sounding alternatives. This is the difference between an analysis you can trust and one you have to fact-check line by line.

**Handling data at scale.** Major committee filings (ActBlue, WinRed, presidential campaigns) can contain hundreds of thousands of rows. A naive AI session might try to load all of it into memory at once. The `fecfile` skill has explicit rules: always check `--summary-only` first, use `--stream` mode for large filings, post-filter with pandas before presenting results. These aren't suggestions, they're baked into the skill's instructions so the right approach happens automatically.

**Bundled, deterministic scripts.** Skills can include executable scripts alongside their instructions. The `fecfile` [skill](https://github.com/hodgesmr/agent-fecfile) bundles `fetch_filing.py`, which always parses FEC data the same way using the same library. The `weather-forecast` skill bundles two scripts: `get_coordinates.py` (a local database of US city coordinates — no network call needed) and `get_forecast.py` (the Open-Meteo API call). The skill's instructions require Claude to always run them in that order, making the two-step geocode-then-forecast workflow reproducible and explicit. The `image-rotator` skill bundles `rotate_image.py`, so rather than writing PIL rotation code from scratch each time — and potentially getting the `expand=True` flag wrong or saving in the wrong format — Claude runs a known-good script. The Census-focused skills follow the same pattern: `state-county-rankings` bundles `get_state_county_rankings.R` for consistent metric rankings from local ACS county data, and `majority-minority-change` bundles `analyze_majority_minority_change.R` for repeatable threshold-crossing analysis between two snapshots. In all five cases, the data or output comes from a tested, version-controlled code path rather than improvised code that varies session to session.

**Portability.** Skills committed to the tool-readable skills directories travel with the repo. A colleague who clones the project gets the same skill instructions and bundled scripts without pasting anything into a system prompt. For Codex CLI, repo-local skills now belong under `.agents/skills/`; personal skills that should be available everywhere belong under `~/.agents/skills/`.

**Building your own.** The `skill-creator` skill is itself an example of this pattern applied recursively — it bundles `init_skill.py` (scaffolds a new skill directory with a template `SKILL.md`) and `package_skill.py` (validates and zips a skill when you need an archive), and its `SKILL.md` walks through a six-step creation process. If you want to build a skill for your own beat — court records, property data, Census API, a local government's open data portal — `skill-creator` gives you the tooling and the process to do it consistently.

### When a skill is not the right surface

Modern Claude Code and Codex workflows have more choices than "put everything in a skill":

| Need | Better surface |
|------------------|------------------|
| Always-on repo conventions, build commands, and review expectations | `AGENTS.md` for Codex, `CLAUDE.md` for Claude Code |
| Focused repeatable workflow with instructions, references, and optional scripts | Skill |
| A reusable installable package, multiple skills, connectors, or MCP tools | Plugin |
| Mechanical enforcement before/after tool use | Hooks or project settings |
| Specialized parallel work with preloaded knowledge | Subagents or agent teams |

For this NICAR repo, direct skill folders are still the right teaching surface. If you want to distribute a reusable workflow beyond one repo, or bundle it with connected tools, convert the skill into a plugin instead of relying on manual copy/paste.

## Active skills

Claude Code and Codex CLI can use the same `SKILL.md` format, but they discover repo-local skills from different locations.

| Tool | Active skills directory | How skills trigger |
|------------------|-----------------------------|-------------------------|
| Claude Code | `.claude/skills/` | Auto-triggers based on `description` frontmatter, or invoke with `/skill-name` |
| Codex CLI | `.agents/skills/` | Auto-triggers based on `description` frontmatter, or invoke with `$skill-name` or view with `/skills` |

The Codex CLI scans for repo-local skills in `.agents/skills/` from your current working directory up to the repository root. Codex also reads personal skills from `~/.agents/skills/`; admin and bundled system skill locations may also be present in managed environments.

The `skills/` directory at the repo root is the **session/canonical copy** — it's the source used in the NICAR session materials. Keep active tool copies or symlinks in sync with that canonical copy when a skill changes.

### Enabling repo-local skills

**Claude Code** picks up `.claude/skills/` automatically when you open the project — no setup needed.

**Codex CLI** no longer needs the old `CODEX_HOME=$(pwd)/.codex codex` wrapper workflow for repo-local skills. Put the skills under `.agents/skills/`, then launch Codex normally from the repo root:

``` bash
cd /path/to/nicar2026_skills_in_codex_claude
codex
```

Codex usually detects skill changes automatically. If the project skills do not appear in `/skills`, confirm that the skill folders exist under `.agents/skills/`, wait a moment, and then restart Codex if they still do not appear. You can keep `.agents/skills/` as a copy of `skills/`, or use symlinks so the active Codex skills point at the canonical folders:

``` bash
mkdir -p .agents/skills
for skill in fecfile weather-forecast image-rotator skill-creator state-county-rankings majority-minority-change; do
  ln -sfn "../../skills/$skill" ".agents/skills/$skill"
done
```

Codex follows symlinked skill folders when scanning `.agents/skills/`.

If you want a skill available globally in all your Codex sessions, copy or symlink it into your personal skills folder instead:

``` bash
# Create your global skills folder if it doesn't exist yet
mkdir -p ~/.agents/skills

# Symlink the skill from this repo into your global folder
ln -s /path/to/nicar2026_skills_in_codex_claude/skills/fecfile ~/.agents/skills/fecfile
```

Replace `/path/to/nicar2026_skills_in_codex_claude` with the actual path where you cloned this repo. On a Mac you can find it by running `pwd` from inside the repo directory in your terminal.

`CODEX_HOME` still exists, but it controls Codex state such as config, auth, logs, sessions, and runtime package metadata. Use it only when you intentionally need a separate Codex profile or automation home, not as the normal repo-local skills activation step.

For local Codex experimentation with curated or remote skills, `$skill-installer` can install skills into your personal setup. For team or public distribution, prefer a plugin package.

### Optional Codex metadata

Plain `SKILL.md` files are enough for this repo. Codex can also read optional `agents/openai.yaml` metadata for UI display, implicit-invocation policy, and tool dependencies. Use that only when a skill needs Codex-specific presentation or dependency declarations; keep the portable workflow in `SKILL.md`.
