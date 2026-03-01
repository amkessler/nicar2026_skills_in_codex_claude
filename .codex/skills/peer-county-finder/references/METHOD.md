# Similarity Method

## Input

- One county-level CSV with:
  - `state`
  - `county`
  - numeric feature columns (for example income, poverty, age, rent)

## Steps

1. Keep rows with complete values for selected features.
2. Standardize each selected feature (z-score).
3. Calculate Euclidean distance to the target county.
4. Rank peers by smallest distance.

## Interpretation

- Smaller distance = more similar profile across selected features.
- Results depend heavily on feature choice and input data quality.
