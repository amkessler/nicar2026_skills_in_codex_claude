---
name: state-county-rankings
description: This skill should be used when users need ranked county-level demographic metrics within a state from a local CSV file, such as income, population, poverty, or rent.
---

# State County Rankings

Use this skill to rank counties within a state for one or more metrics from a local dataset.

## Requirements

- R with `dplyr`, `tidyr`, `readr`, `stringr`, and `jsonlite`
- Local CSV input with `county`, a state column (`state`, `state_name`, or `state_abbrev`), and requested metric columns
- Bundled Census CSV for immediate use:
  `skills/state-county-rankings/data/county_demographics_acs5_2023.csv`
- No API key required

## Standard Workflow

1. Confirm input CSV path and state.
   - `--state` accepts full names or USPS abbreviations (for example, `Georgia` or `GA`).
   - Default bundled input:
     `skills/state-county-rankings/data/county_demographics_acs5_2023.csv`
2. Review `skills/state-county-rankings/references/COLUMN_REQUIREMENTS.md` and use exact output headers before downstream filtering/selecting.
   - Output columns are `state`, `county`, `metric`, `value`, `rank`, and `direction`.
3. Ask for metrics (or use defaults) and ranking direction.
4. Run:
   - `Rscript skills/state-county-rankings/scripts/get_state_county_rankings.R --input skills/state-county-rankings/data/county_demographics_acs5_2023.csv --state "<state>"`
5. Return top/bottom county rankings and note missing/invalid fields.

## Output

Return ranked rows with:
- `state`
- `county`
- `metric`
- `value`
- `rank`
- `direction`
