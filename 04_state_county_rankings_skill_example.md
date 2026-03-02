# 04: Real-World Skill Example (State County Rankings From Local Census CSV)

This tutorial demonstrates a reporter-friendly skill that ranks counties within a state for one or more demographic metrics, using a local CSV file and no credentials.

## Reporting Use Case

Prompts this skill should handle:
- "Show me the top 10 counties in Ohio by median household income."
- "Rank North Carolina counties by poverty rate, highest first."
- "Give me the bottom 15 counties in California by median gross rent."

## What You Will Build

- Skill folder: `skills/state-county-rankings/`
- Script: `scripts/get_state_county_rankings.R`
- Reference doc: `references/COLUMN_REQUIREMENTS.md`
- Reusable workflow in `SKILL.md`

This repo already includes a full implementation in those paths.

## No-Credentials Data Source

Use local CSV exports (for example, county-level ACS tables downloaded from Census tools and saved to `data/source/`).

Required columns:
- `county`
- one state column: `state`, `state_name`, or `state_abbrev`
- numeric metrics such as `total_population`, `median_household_income`, `poverty_rate`, `median_gross_rent`

## Script Pattern (Tidyverse)

File: `skills/state-county-rankings/scripts/get_state_county_rankings.R`

Key design:
1. Parse CLI args (`--input`, `--state`, `--metrics`, `--top-n`, `--direction`)
2. Validate columns and metric availability
3. Filter to one state
4. Pivot metrics long and rank by metric
5. Write CSV or JSON output

Core ranking block:

```r
ranked <- filtered %>%
  transmute(
    state = as.character(state_value),
    county = as.character(county),
    across(all_of(metrics), as.numeric)
  ) %>%
  pivot_longer(cols = all_of(metrics), names_to = "metric", values_to = "value") %>%
  filter(!is.na(value)) %>%
  group_by(metric) %>%
  {
    if (direction == "desc") arrange(., desc(value), county) else arrange(., value, county)
  } %>%
  mutate(
    rank = if_else(direction == "desc", min_rank(desc(value)), min_rank(value)),
    direction = direction
  ) %>%
  filter(rank <= top_n) %>%
  ungroup()
```

## Try It

```bash
Rscript skills/state-county-rankings/scripts/get_state_county_rankings.R \
  --input data/source/county_demographics.csv \
  --state "Ohio" \
  --metrics "median_household_income,poverty_rate" \
  --top-n 10 \
  --direction desc \
  --format csv \
  --output data/processed/ohio_rankings.csv
```

## Skill Definition

File: `skills/state-county-rankings/SKILL.md`

The skill description is tuned to trigger on ranking requests and local demographic files.

## Suggested Session Exercise

1. Run income ranking for one state.
2. Run poverty ranking for the same state.
3. Compare whether the top/bottom counties overlap.
4. Draft one finding sentence from the output table.

## Why This Skill Is Useful

- Fast leaderboard generation for local stories
- Repeatable and auditable command-based workflow
- No key management or live API dependencies
