# Column Requirements

## Required

- `county`
- One state column (any one of):
  - `state`
  - `state_name`
  - `state_abbrev`

## Metrics

Provide one or more numeric metric columns, for example:

- `total_population`
- `median_household_income`
- `poverty_rate`
- `median_gross_rent`
- `median_age`

## Notes

- This skill does not download data.
- Use local CSV files exported from Census products or newsroom data pipelines.
- State matching is case-insensitive, but value text must otherwise match the dataset values.
