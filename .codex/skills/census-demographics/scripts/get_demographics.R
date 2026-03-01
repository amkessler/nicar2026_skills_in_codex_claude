#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidycensus)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(jsonlite)
  library(stringr)
})

# ------------------------------
# 1) Parse CLI args (sequential)
# ------------------------------
args <- commandArgs(trailingOnly = TRUE)

state <- NA_character_
county <- NA_character_
year <- 2023L
format <- "csv"
output <- NA_character_
survey <- "acs5"

i <- 1
while (i <= length(args)) {
  flag <- args[[i]]

  if (!str_starts(flag, "--")) {
    stop(str_c("Unexpected token: ", flag))
  }
  if (i == length(args)) {
    stop(str_c("Missing value for ", flag))
  }

  value <- args[[i + 1]]

  if (flag == "--state") {
    state <- value
  } else if (flag == "--county") {
    county <- value
  } else if (flag == "--year") {
    year <- as.integer(value)
  } else if (flag == "--format") {
    format <- value
  } else if (flag == "--output") {
    output <- value
  } else if (flag == "--survey") {
    survey <- value
  } else {
    stop(str_c("Unknown flag: ", flag))
  }

  i <- i + 2
}

state <- state %>% str_squish() %>% na_if("")
county <- county %>% str_squish() %>% na_if("")
format <- format %>% str_to_lower() %>% str_squish()
output <- output %>% str_squish() %>% na_if("")
survey <- survey %>% str_to_lower() %>% str_squish()

# ------------------------------
# 2) Validate args and env
# ------------------------------
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

# ------------------------------
# 3) Define metrics
# ------------------------------
metrics <- c(
  total_population = "B01001_001",
  median_age = "B01002_001",
  median_household_income = "B19013_001",
  poverty_count = "B17001_002",
  median_home_value = "B25077_001",
  median_gross_rent = "B25064_001"
)

# ------------------------------
# 4) Pull ACS data
# ------------------------------
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

# ------------------------------
# 5) Reshape output
# ------------------------------
variable_lookup <- data.frame(
  variable_code = unname(metrics),
  variable_name = names(metrics),
  stringsAsFactors = FALSE
)

out <- acs %>%
  select(NAME, variable, estimate, moe) %>%
  left_join(variable_lookup, by = c("variable" = "variable_code")) %>%
  mutate(variable = coalesce(variable_name, variable)) %>%
  select(-variable_name) %>%
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

# ------------------------------
# 6) Determine output path
# ------------------------------
if (is.na(output)) {
  slug <- coalesce(county, state) %>%
    str_to_lower() %>%
    str_replace_all("[^a-z0-9]+", "_") %>%
    str_replace_all("^_|_$", "")
  ext <- if_else(format == "json", "json", "csv")
  output <- str_c("data/processed/", slug, "_demographics_", year, ".", ext)
}

# ------------------------------
# 7) Write result
# ------------------------------
dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)

if (format == "json") {
  write_json(out, output, pretty = TRUE, auto_unbox = TRUE, na = "null")
} else {
  write_csv(out, output)
}

message(str_c("Wrote ", nrow(out), " row(s) to ", output))
