# Data Schema Notes

This skill expects two tidy county-level files that can be joined by county identifiers.

## Minimum fields in each file

- `total_population`
- `non_hispanic_white`
- join keys:
  - `county_fips`, or
  - `state` + `county`

## Calculated fields

- `nonwhite_share = 1 - (non_hispanic_white / total_population)`
- `delta_nonwhite_share_pp = (end_share - start_share) * 100`

## Interpretation

- `crossed_to_majority_minority = TRUE` means the county moved from <50% non-white to >=50% non-white.
- `crossed_out_of_majority_minority = TRUE` means the reverse.
