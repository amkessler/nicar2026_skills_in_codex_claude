# 07: Real-World Skill Example (Peer County Finder)

This tutorial demonstrates a skill that finds counties most similar to a target county using local demographic indicators and Euclidean distance on z-scored features.

Estimated time: 30-40 minutes.

## Reporting Use Case

Prompts this skill should handle:
- "Which counties are most demographically similar to Milwaukee County, WI?"
- "Find peers for Maricopa County, AZ using income, poverty, age, and rent."
- "Give me 15 peer counties for Cook County, IL and show distances."

## What You Will Build

- Skill folder: `skills/peer-county-finder/`
- Script: `scripts/find_peer_counties.R`
- Method note: `references/METHOD.md`
- Trigger/workflow guidance in `SKILL.md`

This repo already includes a complete implementation in those paths.

## No-Credentials Data Source

Use one local county-level CSV with:
- `state`
- `county`
- numeric features you want to compare

Example feature set:
- `total_population`
- `median_household_income`
- `poverty_rate`
- `median_age`
- `median_gross_rent`

## Script Pattern (Tidyverse)

File: `skills/peer-county-finder/scripts/find_peer_counties.R`

Key design:
1. Parse target county/state and feature list
2. Keep rows with complete feature values
3. Z-score normalize selected features
4. Compute Euclidean distance from target
5. Rank and return nearest peers

Core distance logic:

```r
distance_frame <- scaled %>%
  rowwise() %>%
  mutate(distance = sqrt(sum((c_across(all_of(features)) - target_vector)^2))) %>%
  ungroup() %>%
  select(row_id, distance)
```

## Try It

```bash
Rscript skills/peer-county-finder/scripts/find_peer_counties.R \
  --input data/source/county_demographics.csv \
  --target-state "Wisconsin" \
  --target-county "Milwaukee" \
  --features "median_household_income,poverty_rate,median_age,median_gross_rent" \
  --top-n 10 \
  --format csv \
  --output data/processed/milwaukee_peer_counties.csv
```

## Skill Definition

File: `skills/peer-county-finder/SKILL.md`

The skill triggers on "similar places" and "peer county" requests and explains the distance method in plain language.

## Suggested Classroom Exercise

1. Run peers for one target county with default features.
2. Rerun with a different feature set.
3. Compare how the peer list changes.
4. Discuss why feature selection changes results.

## Why This Skill Is Useful

- Helps reporters contextualize a place against comparable places
- Supports "is this place unusual?" story framing
- Method is transparent, reproducible, and key-free
