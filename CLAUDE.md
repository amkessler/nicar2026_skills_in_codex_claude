# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Demo project for NICAR 2026 showing how to use AI "skills" — modular, self-contained instruction packages
that extend Claude/Codex's capabilities for domain-specific tasks. The primary example skill is
`fecfile` for analyzing FEC campaign finance filings. The `skills/` directory includes additional
example skills and tools for creating new ones.

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
resources (`scripts/`, `references/`, `assets/`). They live in two locations:

- `skills/` — example skills included in this repo (image-rotator, weather-forecast, skill-creator)
- `.codex/skills/` — skills active for the Codex CLI (currently: `fecfile`)

To enable repo-local skills with Codex: set `CODEX_HOME` to the repo root's `.codex/` directory
or symlink `.codex/skills/<skill-name>` into `~/.codex/skills/`.

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
uv run skills/skill-creator/scripts/init_skill.py <skill-name> --path <output-dir>

# Validate and package a skill into a distributable zip
uv run skills/skill-creator/scripts/package_skill.py <path/to/skill-folder>
uv run skills/skill-creator/scripts/package_skill.py <path/to/skill-folder> ./dist
```

See `skills/skill-creator/SKILL.md` for the full 6-step skill creation workflow.

## FEC Filing Analysis (fecfile skill)

The `.codex/skills/fecfile` skill uses the `fecfile` Python library (auto-installed by `uv run`)
to analyze FEC campaign finance filings.

### Finding filing IDs

```bash
uv run fec_find_filings.py <COMMITTEE_ID> --limit 5
uv run fec_find_filings.py <COMMITTEE_ID> --form-type F3X --report-year 2024
uv run fec_find_filings.py <COMMITTEE_ID> --format csv --limit 10
```

Requires `FEC_API_KEY` or `DATA_GOV_API_KEY` env var (defaults to `DEMO_KEY` if unset).

### Fetching filing data

```bash
uv run .codex/skills/fecfile/scripts/fetch_filing.py <FILING_ID> --summary-only
uv run .codex/skills/fecfile/scripts/fetch_filing.py <FILING_ID> --schedule A
uv run .codex/skills/fecfile/scripts/fetch_filing.py <FILING_ID> --schedules A,B
uv run .codex/skills/fecfile/scripts/fetch_filing.py <FILING_ID> --stream --schedule A
```

Always check `--summary-only` first before fetching full schedules. Large filings (ActBlue,
WinRed, presidential campaigns) must use `--stream` or schedule pre-filtering to avoid loading
hundreds of thousands of rows into context. Field names are documented in
`.codex/skills/fecfile/references/FORMS.md` and `SCHEDULES.md` — do not guess field names.

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
