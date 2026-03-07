# Quickstart Tutorials For Underlying Code

This guide gives you six fast, hands-on paths through this repo: 1. FEC filing analysis 2. Weather forecast workflow 3. State county rankings from local data 4. Majority-minority change between two snapshots 5. Image rotation 6. Creating a new skill

## Before You Start

Run these once from the repo root:

``` bash
uv sync
```

Optional, but recommended for FEC API limits (if you don't yet have an API key you can request one [here](https://api.open.fec.gov/developers/)):

``` bash
export FEC_API_KEY="your_key_here"
```

If you are using Codex with repo-local skills, use either command:

``` bash
CODEX_HOME="$(pwd)/.codex" codex
```

or the tailored shell script included in this repo to start codex:

``` bash
./codex.sh
```

## Quickstart 1: FEC Filing Analysis

Goal: find a filing ID for a committee, then pull filing data safely.

### Step 1: Find filings for a committee

``` bash
uv run python fec_find_filings.py C00770941 --limit 5
```

Look for the `file_number` column in output. That is the filing ID.

### Step 2: Start with summary-only

``` bash
uv run skills/fecfile/scripts/fetch_filing.py C00770941 --summary-only
```

This is the safest first step for any filing size.

### Step 3: Pull one schedule

``` bash
uv run skills/fecfile/scripts/fetch_filing.py C00770941 --schedule A
```

Use `--schedule B` for disbursements.

### Step 4: Stream large filings (optional)

``` bash
uv run skills/fecfile/scripts/fetch_filing.py C00770941 --stream --schedule A
```

This outputs JSONL (one JSON record per line) and avoids loading huge filings into memory.

## Quickstart 2: Weather Forecast Workflow

Goal: geocode a US city, then fetch a 7-day forecast.

### Step 1: Get coordinates

``` bash
uv run python skills/weather-forecast/scripts/get_coordinates.py "Philadelphia, PA"
```

Expected style of output:

``` text
39.9525839 -75.1652215
```

### Step 2: Fetch forecast table

``` bash
uv run python skills/weather-forecast/scripts/get_forecast.py 39.9525839 -75.1652215
```

You should see a table with period, temperature, wind, and forecast description.

### Step 3: Fetch JSON output (optional)

``` bash
uv run python skills/weather-forecast/scripts/get_forecast.py 39.9525839 -75.1652215 --json
```

Use this for charting or downstream analysis.

## Quickstart 3: State County Rankings

Goal: rank counties in one state using bundled demographic data.

### Step 1: Run a basic ranking

``` bash
Rscript skills/state-county-rankings/scripts/get_state_county_rankings.R \
  --input skills/state-county-rankings/data/county_demographics_acs5_2023.csv \
  --state GA \
  --top-n 5
```

Expected output: - `data/processed/ga_county_rankings.csv`

### Step 2: Run custom metrics and JSON output

``` bash
Rscript skills/state-county-rankings/scripts/get_state_county_rankings.R \
  --input skills/state-county-rankings/data/county_demographics_acs5_2023.csv \
  --state Georgia \
  --metrics median_household_income,poverty_rate \
  --top-n 5 \
  --direction asc \
  --format json \
  --output data/processed/ga_rankings_income_poverty_asc.json
```

This returns the five lowest counties (per metric) in machine-readable JSON.

## Quickstart 4: Majority-Minority Change

Goal: compare county racial composition across two Census snapshots.

### Step 1: Run nationwide comparison

``` bash
Rscript skills/majority-minority-change/scripts/analyze_majority_minority_change.R \
  --input-start skills/majority-minority-change/data/county_race_acs5_2010.csv \
  --input-end skills/majority-minority-change/data/county_race_acs5_2020.csv \
  --format csv
```

Expected output: - `data/processed/majority_minority_change_2010_2020.csv`

### Step 2: Run with a state filter

``` bash
Rscript skills/majority-minority-change/scripts/analyze_majority_minority_change.R \
  --input-start skills/majority-minority-change/data/county_race_acs5_2010.csv \
  --input-end skills/majority-minority-change/data/county_race_acs5_2020.csv \
  --state "Georgia" \
  --format csv \
  --output data/processed/georgia_majority_minority_change.csv
```

Use this to focus on one reporting market.

## Quickstart 5: Image Rotation

Goal: rotate local images by 90-degree increments.

### Step 1: Rotate clockwise (default)

``` bash
uv run python skills/image-rotator/scripts/rotate_image.py path/to/image.jpg
```

This writes `path/to/image_rotated.jpg`.

### Step 2: Rotate counter-clockwise with explicit output

``` bash
uv run python skills/image-rotator/scripts/rotate_image.py \
  path/to/image.jpg \
  --direction counter-clockwise \
  --output data/processed/image_ccw.jpg
```

### Step 3: Rotate 180 degrees

``` bash
uv run python skills/image-rotator/scripts/rotate_image.py \
  path/to/image.jpg \
  --times 2 \
  --output data/processed/image_180.jpg
```

## Quickstart 6: Create a New Skill

Goal: scaffold, validate, and package a distributable skill.

### Step 1: Initialize a skill skeleton

``` bash
uv run python skills/skill-creator/scripts/init_skill.py city-budget --path skills
```

This creates `skills/city-budget/` with: - `SKILL.md` - `scripts/` - `references/` - `assets/`

### Step 2: Edit the new SKILL.md

Open and complete TODO sections:

``` bash
skills/city-budget/SKILL.md
```

Focus on: 1. `name` and `description` in frontmatter 2. Clear trigger conditions 3. Exact workflow steps

### Step 3: Validate structure

``` bash
uv run python skills/skill-creator/scripts/quick_validate.py skills/city-budget
```

Expected output:

``` text
Skill is valid!
```

### Step 4: Package as a zip file

``` bash
uv run python skills/skill-creator/scripts/package_skill.py skills/city-budget ./dist
```

Expected artifact: - `dist/city-budget.zip`

## Common Problems

`uv: command not found` - Install uv: https://docs.astral.sh/uv/getting-started/installation/

FEC API errors or limits - Set `FEC_API_KEY` (or `DATA_GOV_API_KEY`) in your shell.

Weather city lookup fails - `get_coordinates.py` only includes the 1000 largest US cities. - For other places, run `get_forecast.py` with explicit latitude/longitude.

Image rotation script fails on Pillow - Run `uv sync` to install project dependencies.
