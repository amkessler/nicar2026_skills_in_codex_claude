---
name: state-county-rankings
description: This skill should be used when users need ranked county-level demographic metrics within a state from a local CSV file, such as income, population, poverty, or rent.
---

# State County Rankings

Use this skill to rank counties within a state for one or more metrics from a local dataset.

## Requirements

- R with `dplyr`, `tidyr`, `readr`, `stringr`, and `jsonlite`
- Local CSV input with `county`, a state column (`state`, `state_name`, or `state_abbrev`), and requested metric columns
- No API key required

## Standard Workflow

1. Confirm input CSV path and state value exactly as represented in the dataset.
2. Ask for metrics (or use defaults) and ranking direction.
3. Run:
   - `Rscript skills/state-county-rankings/scripts/get_state_county_rankings.R --input <csv> --state "<state>"`
4. Return top/bottom county rankings and note missing/invalid fields.

## Output

Return ranked rows with:
- `state`
- `county`
- `metric`
- `value`
- `rank`
- `direction`
