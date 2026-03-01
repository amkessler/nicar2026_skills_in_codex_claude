# 04: Real-World Skill Example (R + tidycensus)

This tutorial shows a concrete newsroom use case: building a skill that runs an R script with `tidycensus` to pull key demographics for a user-specified state or county.

Estimated time: 30-45 minutes.

## Scenario

You want a reusable skill for prompts like:
- "Get key demographics for Pennsylvania."
- "Pull the same metrics for Allegheny County, PA."
- "Compare median household income and total population for Maricopa County, AZ."

The skill should run your R script, return clean output, and avoid manual data pulls.

## What You Will Build

By the end, you will have:
1. A new skill folder: `skills/census-demographics/`
2. An R script: `scripts/get_demographics.R`
3. A `SKILL.md` that tells the assistant when/how to run the script
4. A packaged skill zip for distribution

## Prerequisites

From repo root:

```bash
uv sync
```

R + packages:

```bash
Rscript --version
Rscript -e 'install.packages(c("tidycensus","dplyr","tidyr","readr","jsonlite","stringr","tibble"))'
```

Census API key in your shell:

```bash
export CENSUS_API_KEY="your_census_api_key_here"
```

Get a key: https://api.census.gov/data/key_signup.html

## Step 1: Initialize The Skill Skeleton

```bash
uv run python skills/skill-creator/scripts/init_skill.py census-demographics --path skills
```

This creates:

```text
skills/census-demographics/
  SKILL.md
  scripts/
  references/
  assets/
```

## Step 2: Add The R Script

Create `skills/census-demographics/scripts/get_demographics.R` with this content:

```r
#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidycensus)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(jsonlite)
  library(stringr)
  library(tibble)
})

parse_cli <- function(tokens) {
  tibble(token = tokens) %>%
    mutate(
      is_flag = str_starts(token, "--"),
      flag = if_else(is_flag, token, lag(token)),
      value = if_else(is_flag, NA_character_, token)
    ) %>%
    filter(!is.na(value), str_starts(flag, "--")) %>%
    group_by(flag) %>%
    slice_tail(n = 1) %>%
    ungroup() %>%
    select(flag, value)
}

get_opt <- function(cli, flag_name, default = NA_character_) {
  val <- cli %>% filter(flag == flag_name) %>% pull(value)
  if (length(val) == 0) default else val[[1]]
}

cli <- parse_cli(commandArgs(trailingOnly = TRUE))

state <- get_opt(cli, "--state") %>% str_squish() %>% na_if("")
county <- get_opt(cli, "--county") %>% str_squish() %>% na_if("")
year <- get_opt(cli, "--year", "2023") %>% as.integer()
format <- get_opt(cli, "--format", "csv") %>% str_to_lower()
output <- get_opt(cli, "--output") %>% na_if("")
survey <- get_opt(cli, "--survey", "acs5") %>% str_to_lower()

if (is.na(state)) {
  stop("Usage: Rscript get_demographics.R --state <state> [--county <county>] [--year <year>] [--survey acs5] [--format csv|json] [--output path]")
}
if (is.na(year)) {
  stop("--year must be an integer (example: 2023)")
}
if (!format %in% c("csv", "json")) {
  stop("--format must be 'csv' or 'json'")
}

api_key <- Sys.getenv("CENSUS_API_KEY") %>% str_squish()
if (api_key == "") {
  stop("CENSUS_API_KEY is not set in the environment")
}

# Core metrics students can explain and reporters commonly use
metrics <- c(
  total_population = "B01001_001",
  median_age = "B01002_001",
  median_household_income = "B19013_001",
  poverty_count = "B17001_002",
  median_home_value = "B25077_001",
  median_gross_rent = "B25064_001"
)

geo <- if_else(is.na(county), "state", "county")

if (geo == "state") {
  acs <- get_acs(
    geography = "state",
    state = state,
    variables = metrics,
    year = year,
    survey = survey,
    key = api_key
  )
} else {
  acs <- get_acs(
    geography = "county",
    state = state,
    county = county,
    variables = metrics,
    year = year,
    survey = survey,
    key = api_key
  )
}

variable_lookup <- setNames(names(metrics), metrics)

out <- acs %>%
  select(NAME, variable, estimate, moe) %>%
  mutate(variable = recode(variable, !!!variable_lookup)) %>%
  pivot_wider(
    names_from = variable,
    values_from = c(estimate, moe),
    names_glue = "{variable}_{.value}"
  ) %>%
  mutate(
    geography_type = geo,
    state_input = state,
    county_input = county,
    year = year,
    survey = survey
  )

if (is.na(output)) {
  slug <- coalesce(county, state) %>%
    str_to_lower() %>%
    str_replace_all("[^a-z0-9]+", "_") %>%
    str_replace_all("^_|_$", "")
  ext <- if_else(format == "json", "json", "csv")
  output <- str_c("data/processed/", slug, "_demographics_", year, ".", ext)
}

if (format == "json") {
  write_json(out, output, pretty = TRUE, auto_unbox = TRUE, na = "null")
} else {
  write_csv(out, output)
}

message(str_c("Wrote ", nrow(out), " row(s) to ", output))
```

Make it executable:

```bash
chmod +x skills/census-demographics/scripts/get_demographics.R
```

## Step 3: Add A Reference File For Variables

Create `skills/census-demographics/references/VARIABLES.md`:

```md
# Variables Used

- total_population: B01001_001
- median_age: B01002_001
- median_household_income: B19013_001
- poverty_count: B17001_002
- median_home_value: B25077_001
- median_gross_rent: B25064_001
```

This helps students understand and audit the metric mapping.

## Step 4: Replace SKILL.md With A Practical Version

Edit `skills/census-demographics/SKILL.md`:

```md
---
name: census-demographics
description: This skill should be used when users need ACS demographics for a U.S. state or county, including population, age, income, poverty, home value, and rent metrics.
---

# Census Demographics

Use this skill to fetch key ACS metrics for a state or county.

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
4. Summarize results in plain language and include data caveats when relevant.

## Requirements

- `CENSUS_API_KEY` must be set in the environment.
- `tidycensus`, `dplyr`, `tidyr`, `readr`, `jsonlite`, `stringr`, and `tibble` must be installed in R.

## Output

Return:
- Geography name
- Population
- Median age
- Median household income
- Poverty count
- Median home value
- Median gross rent
```

## Step 5: Test The Script By Hand

State-level example:

```bash
Rscript skills/census-demographics/scripts/get_demographics.R \
  --state "Pennsylvania" \
  --year 2023 \
  --format csv \
  --output data/processed/pennsylvania_demographics_2023.csv
```

County-level example:

```bash
Rscript skills/census-demographics/scripts/get_demographics.R \
  --state "Pennsylvania" \
  --county "Allegheny" \
  --year 2023 \
  --format json \
  --output data/processed/allegheny_demographics_2023.json
```

## Step 6: Validate And Package

```bash
uv run python skills/skill-creator/scripts/quick_validate.py skills/census-demographics
uv run python skills/skill-creator/scripts/package_skill.py skills/census-demographics ./dist
```

Expected artifact:
- `dist/census-demographics.zip`

## Step 7: Mirror To Active Skill Directories

```bash
cp -R skills/census-demographics .claude/skills/census-demographics
cp -R skills/census-demographics .codex/skills/census-demographics
```

## Step 8: Try Real Prompts

- "Use census-demographics to pull key ACS metrics for North Carolina."
- "Get demographics for Maricopa County, Arizona."
- "Return JSON for Cook County, Illinois and summarize top takeaways."

## Common Teaching Notes

- Ask students to verify variable codes in `references/VARIABLES.md`.
- Emphasize that county queries should include a state to avoid ambiguity.
- Discuss ACS caveats: year, survey type (`acs5` vs `acs1`), and margins of error.
- Encourage students to keep scripts deterministic and argument-driven.
