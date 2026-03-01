# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Demo project for NICAR 2026 showing how to use AI "skills" — modular, self-contained instruction packages
that extend Claude/Codex's capabilities for domain-specific tasks. The repo includes eight skills covering
FEC campaign finance, weather forecasts, image rotation, Census demographics, and skill creation.
The `skills/` directory is the canonical teaching copy; numbered tutorial docs (`01_*.md` – `07_*.md`)
walk through quickstart workflows, skill-building exercises, and worked Census examples.

## Environment Setup

This project uses `uv` for Python dependency management (Python 3.12+ required):

```bash
uv sync                          # Install dependencies into .venv
uv run <script>                  # Run a script with dependencies auto-resolved
```

JupyterLab is the primary analysis environment:

```bash
uv run jupyter lab               # Launch JupyterLab
```

Quarto renders notebooks/documents to `data/html_reports/`:

```bash
quarto render                    # Render all Quarto docs
quarto render <file.qmd>         # Render a single file
```

The `.env` file sets `JUPYTER_PATH`, `JUPYTER_CONFIG_DIR`, and `JUPYTER_RUNTIME_DIR` to keep
Jupyter isolated inside `.venv`. This file is gitignored — do not commit it.

## Skills Architecture

Skills are directories containing a `SKILL.md` (with YAML frontmatter) and optional bundled
resources (`scripts/`, `references/`, `assets/`). This repo has three skill locations:

- `skills/` — teaching copy used in the NICAR presentation (canonical source)
- `.claude/skills/` — active skills for Claude Code (auto-loaded when you open the project)
- `.codex/skills/` — active skills for the Codex CLI

Eight skills are present in all three locations:

- `fecfile` — FEC campaign finance filing analysis (Python)
- `weather-forecast` — 7-day forecasts via Open-Meteo (Python)
- `image-rotator` — rotate images 90° (Python)
- `skill-creator` — guided workflow for building new skills (Python)
- `census-demographics` — ACS demographics for a state or county via R/tidycensus
  (requires `CENSUS_API_KEY`)
- `state-county-rankings` — ranked county metrics within a state (R, bundled CSV, no API key)
- `peer-county-finder` — find demographically similar counties via z-score distance (R, bundled CSV,
  no API key)
- `majority-minority-change` — county racial composition change between two Census snapshots
  (R, bundled CSVs, no API key)

Claude Code reads from `.claude/skills/` automatically. For Codex, run `./codex.sh` (wrapper that
sets `CODEX_HOME` and symlinks global auth) or set `CODEX_HOME` manually to the repo root's
`.codex/` directory.

### SKILL.md structure

```
---
name: skill-name
description: Third-person description of when to use this skill.
---

# Skill Title
...markdown instructions for Claude...
```

The `description` frontmatter controls when Claude auto-selects the skill. Write it in
third-person: "This skill should be used when..."

### Skill resources (progressive disclosure)

| Directory | Purpose | Loaded when |
|-----------|---------|------------|
| `scripts/` | Executable code for deterministic/repeated tasks | Executed or read as needed |
| `references/` | Documentation/schemas loaded into context | Claude determines it's needed |
| `assets/` | Output files (templates, images) used in results | Copied/modified by Claude |

## Creating a New Skill

Use the `skill-creator` helper scripts:

```bash
# Initialize a new skill directory with template
uv run .claude/skills/skill-creator/scripts/init_skill.py <skill-name> --path <output-dir>

# Validate and package a skill into a distributable zip
uv run .claude/skills/skill-creator/scripts/package_skill.py <path/to/skill-folder>
uv run .claude/skills/skill-creator/scripts/package_skill.py <path/to/skill-folder> ./dist
```

See `.claude/skills/skill-creator/SKILL.md` for the full 6-step skill creation workflow.

## FEC Filing Analysis (fecfile skill)

The `fecfile` skill (at `.claude/skills/fecfile/`) uses the `fecfile` Python library
(auto-installed by `uv run`) to analyze FEC campaign finance filings.

### Finding filing IDs

```bash
uv run fec_find_filings.py <COMMITTEE_ID> --limit 5
uv run fec_find_filings.py <COMMITTEE_ID> --form-type F3X --report-year 2024
uv run fec_find_filings.py <COMMITTEE_ID> --format csv --limit 10
```

Requires `FEC_API_KEY` or `DATA_GOV_API_KEY` env var (defaults to `DEMO_KEY` if unset).

### Fetching filing data

```bash
uv run .claude/skills/fecfile/scripts/fetch_filing.py <FILING_ID> --summary-only
uv run .claude/skills/fecfile/scripts/fetch_filing.py <FILING_ID> --schedule A
uv run .claude/skills/fecfile/scripts/fetch_filing.py <FILING_ID> --schedules A,B
uv run .claude/skills/fecfile/scripts/fetch_filing.py <FILING_ID> --stream --schedule A
```

Always check `--summary-only` first before fetching full schedules. Large filings (ActBlue,
WinRed, presidential campaigns) must use `--stream` or schedule pre-filtering to avoid loading
hundreds of thousands of rows into context. Field names are documented in
`.claude/skills/fecfile/references/FORMS.md` and `SCHEDULES.md` — do not guess field names.

## Census Skills (R-based)

Four census skills use R with `tidycensus`/`dplyr`/`readr`. Run them with `Rscript`, not `uv run`.
Scripts should be called with repo-relative paths from the repo root.

### census-demographics

Fetches live ACS metrics for a state or county. Requires `CENSUS_API_KEY` in the environment.

```bash
Rscript skills/census-demographics/scripts/get_demographics.R --state "<state>"
Rscript skills/census-demographics/scripts/get_demographics.R --state "<state>" --county "<county>"
Rscript skills/census-demographics/scripts/get_demographics.R --state GA --format json
```

Variable codes are in `.claude/skills/census-demographics/references/VARIABLES.md`.

### state-county-rankings

Ranks counties within a state from the bundled ACS 2023 CSV. No API key needed.

```bash
Rscript skills/state-county-rankings/scripts/get_state_county_rankings.R \
  --input skills/state-county-rankings/data/county_demographics_acs5_2023.csv \
  --state "<state>"
```

`--state` accepts full names or USPS abbreviations (e.g., `Georgia` or `GA`).
Output columns: `state`, `county`, `metric`, `value`, `rank`, `direction`.

### peer-county-finder

Finds demographically similar counties using z-score normalized Euclidean distance. No API key needed.

```bash
Rscript skills/peer-county-finder/scripts/find_peer_counties.R \
  --input skills/peer-county-finder/data/county_demographics_acs5_2023.csv \
  --target-state "<state>" --target-county "<county>"
```

Output starts with `similarity_rank`, `state`, `county`, `distance`, then selected feature columns.

### majority-minority-change

Compares county racial composition across two Census snapshots using bundled 2010 and 2020 CSVs.
No API key needed.

```bash
Rscript skills/majority-minority-change/scripts/analyze_majority_minority_change.R \
  --input-start skills/majority-minority-change/data/county_race_acs5_2010.csv \
  --input-end skills/majority-minority-change/data/county_race_acs5_2020.csv \
  --start-label 2010 --end-label 2020
```

`--state` accepts full names or USPS abbreviations for optional state filtering.
Key output fields: `nonwhite_share_<year_label>`, `delta_nonwhite_share_pp`,
`crossed_to_majority_minority`, `crossed_out_of_majority_minority`.

## Tutorial Documents

Numbered tutorial docs at the repo root (`01_*.md` – `07_*.md`) are the workshop teaching materials:

| File | Contents |
|------|----------|
| `01_QUICKSTART_TUTORIALS.md` | Student quickstart commands and first-run workflows |
| `02_SKILLS_TEACHING_NOTES.md` | Teaching notes, exercises, and troubleshooting |
| `03_BUILD_A_SKILL_FROM_YOUR_CODE.md` | How to turn existing R/Python scripts into a skill |
| `04_TIDYCENSUS_DEMOGRAPHICS_SKILL_EXAMPLE.md` | Worked tidycensus skill example |
| `05_STATE_COUNTY_RANKINGS_SKILL_EXAMPLE.md` | Worked state-county-rankings example |
| `06_MAJORITY_MINORITY_CHANGE_SKILL_EXAMPLE.md` | Worked majority-minority-change example |
| `07_PEER_COUNTY_FINDER_SKILL_EXAMPLE.md` | Worked peer-county-finder example |

`AGENTS.md` at the repo root contains agent/Codex-specific instructions (mirrors key CLAUDE.md
content for Codex sessions).

## Data Directory Layout

```
data/
  source/        # Raw source data (input)
  processed/     # Cleaned/transformed data
  handmade/      # Manually curated data
  public/        # Data for publication
  documentation/ # Data documentation
  html_reports/  # Quarto render output (gitignored)
analysis/
  notebook_templates/  # Reusable Jupyter notebook templates
  archive/             # Archived notebooks
```

Jupyter notebooks in `analysis/` are gitignored (except templates in `notebook_templates/`).
