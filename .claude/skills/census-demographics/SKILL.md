---
name: census-demographics
description: This skill should be used when users need ACS demographics for a U.S. state or county, including population, age, income, poverty, home value, and rent metrics.
---

# Census Demographics

Use this skill to fetch key ACS metrics for a state or county.

## Requirements

- `CENSUS_API_KEY` must be set in the environment.
- R with `tidycensus`, `dplyr`, `tidyr`, `readr`, `jsonlite`, and `stringr` installed.

## Standard Workflow

1. Confirm geography from the user:
   - State required
   - County optional
2. Run the R script:
   - State only:
     `Rscript skills/census-demographics/scripts/get_demographics.R --state "<state>"`
   - County + state:
     `Rscript skills/census-demographics/scripts/get_demographics.R --state "<state>" --county "<county>"`
3. Use `--format json` if structured output is requested.
4. Summarize results in plain language and include ACS caveats where relevant.

## Output

Return:
- Geography name
- Total population
- Median age
- Median household income
- Poverty count
- Median home value
- Median gross rent

## Notes

- Uses local script execution for reproducibility.
- Variable code mapping is documented in `references/VARIABLES.md`.
