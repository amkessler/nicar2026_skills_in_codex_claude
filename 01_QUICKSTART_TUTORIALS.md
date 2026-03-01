# Quickstart Tutorials (NICAR 2026 Skills Demo)

This guide gives attendees three fast, hands-on paths through this repo:
1. FEC filing analysis
2. Weather forecast workflow
3. Creating a new skill

Each section is designed to take about 5 minutes.

## Before You Start

Run these once from the repo root:

```bash
uv sync
```

Optional, but recommended for FEC API limits:

```bash
export FEC_API_KEY="your_key_here"
```

If you are using Codex with repo-local skills:

```bash
CODEX_HOME="$(pwd)/.codex" codex
```

## Quickstart 1: FEC Filing Analysis

Goal: find a filing ID for a committee, then pull filing data safely.

### Step 1: Find filings for a committee

```bash
uv run python fec_find_filings.py C00770941 --limit 5
```

Look for the `file_number` column in output. That is the filing ID.

### Step 2: Start with summary-only

Replace `<FILING_ID>` with one `file_number` value from Step 1.

```bash
uv run skills/fecfile/scripts/fetch_filing.py <FILING_ID> --summary-only
```

This is the safest first step for any filing size.

### Step 3: Pull one schedule

```bash
uv run skills/fecfile/scripts/fetch_filing.py <FILING_ID> --schedule A
```

Use `--schedule B` for disbursements.

### Step 4: Stream large filings (optional)

```bash
uv run skills/fecfile/scripts/fetch_filing.py <FILING_ID> --stream --schedule A
```

This outputs JSONL (one JSON record per line) and avoids loading huge filings into memory.

## Quickstart 2: Weather Forecast Workflow

Goal: geocode a US city, then fetch a 7-day forecast.

### Step 1: Get coordinates

```bash
uv run python skills/weather-forecast/scripts/get_coordinates.py "Philadelphia, PA"
```

Expected style of output:

```text
39.9525839 -75.1652215
```

### Step 2: Fetch forecast table

```bash
uv run python skills/weather-forecast/scripts/get_forecast.py 39.9525839 -75.1652215
```

You should see a table with period, temperature, wind, and forecast description.

### Step 3: Fetch JSON output (optional)

```bash
uv run python skills/weather-forecast/scripts/get_forecast.py 39.9525839 -75.1652215 --json
```

Use this for charting or downstream analysis.

## Quickstart 3: Create a New Skill

Goal: scaffold, validate, and package a distributable skill.

### Step 1: Initialize a skill skeleton

```bash
uv run python skills/skill-creator/scripts/init_skill.py city-budget --path skills
```

This creates `skills/city-budget/` with:
- `SKILL.md`
- `scripts/`
- `references/`
- `assets/`

### Step 2: Edit the new SKILL.md

Open and complete TODO sections:

```bash
skills/city-budget/SKILL.md
```

Focus on:
1. `name` and `description` in frontmatter
2. Clear trigger conditions
3. Exact workflow steps

### Step 3: Validate structure

```bash
uv run python skills/skill-creator/scripts/quick_validate.py skills/city-budget
```

Expected output:

```text
Skill is valid!
```

### Step 4: Package as a zip file

```bash
uv run python skills/skill-creator/scripts/package_skill.py skills/city-budget ./dist
```

Expected artifact:
- `dist/city-budget.zip`

## Common Problems

`uv: command not found`
- Install uv: https://docs.astral.sh/uv/getting-started/installation/

FEC API errors or limits
- Set `FEC_API_KEY` (or `DATA_GOV_API_KEY`) in your shell.

Weather city lookup fails
- `get_coordinates.py` only includes the 1000 largest US cities.
- For other places, run `get_forecast.py` with explicit latitude/longitude.

Image rotation script fails on Pillow
- Run `uv sync` to install project dependencies.
