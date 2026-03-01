---
name: peer-county-finder
description: This skill should be used when users need to find counties that are demographically similar to a target county using local numeric indicators.
---

# Peer County Finder

Use this skill to identify demographically similar counties to a target county.

## Requirements

- R with `dplyr`, `readr`, `stringr`, and `jsonlite`
- Local CSV with `state`, `county`, and numeric feature columns
- Bundled Census CSV for immediate use:
  `skills/peer-county-finder/data/county_demographics_acs5_2023.csv`
- No API key required

## Standard Workflow

1. Confirm target county + state.
2. Confirm feature columns and top-N count.
3. Run similarity script.
   - Example:
     `Rscript skills/peer-county-finder/scripts/find_peer_counties.R --input skills/peer-county-finder/data/county_demographics_acs5_2023.csv --target-state "<state>" --target-county "<county>"`
4. Return top peers and explain distance metric.

## Method

- Z-score normalize selected features
- Compute Euclidean distance from target county
- Sort ascending distance

## Output

Return top peers with:
- `similarity_rank`
- `state`
- `county`
- `distance`
- selected feature values
