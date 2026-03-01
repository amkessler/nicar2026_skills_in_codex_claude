# 05: Real-World Skill Example (Majority-Minority Change Between Two Census Snapshots)

This tutorial shows how to build a skill that compares county-level racial composition across two local files and flags places that crossed the majority-minority threshold.

## Reporting Use Case

Prompts this skill should handle:
- "Which counties in Georgia crossed into majority-minority status between 2010 and 2020?"
- "Show biggest non-white share increases in Texas counties."
- "Find counties that moved out of majority-minority status."

## What You Will Build

- Skill folder: `skills/majority-minority-change/`
- Script: `scripts/analyze_majority_minority_change.R`
- Reference doc: `references/DATA_SCHEMA.md`
- Workflow and caveats in `SKILL.md`

This repo already includes a complete implementation in those paths.

## No-Credentials Data Source

Use two local county-level files (for example, decennial extracts prepared in your newsroom).

Each file must include:
- join keys: `county_fips` (preferred), or `state` + `county`
- `total_population`
- `non_hispanic_white`

## Script Pattern (Tidyverse)

File: `skills/majority-minority-change/scripts/analyze_majority_minority_change.R`

Key design:
1. Read start/end CSVs
2. Validate required columns and shared join keys
3. Compute non-white share in each file
4. Join files and compute percentage-point change
5. Flag threshold crossings
6. Export CSV/JSON

Core change logic:

```r
out <- joined %>%
  mutate(
    delta_nonwhite_share_pp = (.data[[end_share_col]] - .data[[start_share_col]]) * 100,
    crossed_to_majority_minority = .data[[start_share_col]] < 0.5 & .data[[end_share_col]] >= 0.5,
    crossed_out_of_majority_minority = .data[[start_share_col]] >= 0.5 & .data[[end_share_col]] < 0.5
  ) %>%
  arrange(desc(abs(delta_nonwhite_share_pp)))
```

## Try It

```bash
Rscript skills/majority-minority-change/scripts/analyze_majority_minority_change.R \
  --input-start data/source/county_race_2010.csv \
  --input-end data/source/county_race_2020.csv \
  --start-label 2010 \
  --end-label 2020 \
  --state "Georgia" \
  --format csv \
  --output data/processed/georgia_majority_minority_change.csv
```

## Skill Definition

File: `skills/majority-minority-change/SKILL.md`

The skill is designed to trigger on change-over-time threshold questions and force a deterministic comparison workflow.

## Suggested Session Exercise

1. Run all counties nationally (no state filter).
2. Run for one state.
3. Count `crossed_to_majority_minority == TRUE`.
4. Write one headline and one caution note about methodology.

## Why This Skill Is Useful

- Common election and demographic trend story pattern
- Transparent threshold logic
- Reproducible state and county breakdowns without API keys
