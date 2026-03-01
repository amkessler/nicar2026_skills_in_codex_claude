---
name: majority-minority-change
description: This skill should be used when users need to analyze county-level racial composition change between two Census snapshots and identify where places crossed a majority-minority threshold.
---

# Majority Minority Change

Use this skill to compare county demographics across two years and flag threshold crossings.

## Requirements

- R with `dplyr`, `readr`, `stringr`, and `jsonlite`
- Two local CSV files with county identifiers and required race/population fields
- Bundled Census CSV snapshots for immediate use:
  - `skills/majority-minority-change/data/county_race_acs5_2010.csv`
  - `skills/majority-minority-change/data/county_race_acs5_2020.csv`
- No API key required

## Required Input Columns

- Join keys available in both files:
  - `county_fips` (preferred), or
  - both `state` and `county`
- Metrics in both files:
  - `total_population`
  - `non_hispanic_white`

## Standard Workflow

1. Confirm start/end files and year labels.
   - `--state` accepts full names or USPS abbreviations (for example, `Georgia` or `GA`).
   - Default bundled files:
     - start: `skills/majority-minority-change/data/county_race_acs5_2010.csv`
     - end: `skills/majority-minority-change/data/county_race_acs5_2020.csv`
2. Run script with optional state filter.
   - Example:
     `Rscript skills/majority-minority-change/scripts/analyze_majority_minority_change.R --input-start skills/majority-minority-change/data/county_race_acs5_2010.csv --input-end skills/majority-minority-change/data/county_race_acs5_2020.csv --start-label 2010 --end-label 2020`
3. Review counties with largest percentage-point shifts and threshold crossings.

## Output

Return:
- non-white share in each year
- percentage-point change
- `crossed_to_majority_minority`
- `crossed_out_of_majority_minority`
