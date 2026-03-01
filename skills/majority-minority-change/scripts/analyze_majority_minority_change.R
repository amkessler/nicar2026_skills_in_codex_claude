#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(jsonlite)
})

# ------------------------------
# 1) Parse CLI arguments
# ------------------------------
args <- commandArgs(trailingOnly = TRUE)

input_start <- NA_character_
input_end <- NA_character_
start_label <- "2010"
end_label <- "2020"
state_filter <- NA_character_
format <- "csv"
output <- NA_character_

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

  if (flag == "--input-start") {
    input_start <- value
  } else if (flag == "--input-end") {
    input_end <- value
  } else if (flag == "--start-label") {
    start_label <- value
  } else if (flag == "--end-label") {
    end_label <- value
  } else if (flag == "--state") {
    state_filter <- value
  } else if (flag == "--format") {
    format <- value
  } else if (flag == "--output") {
    output <- value
  } else {
    stop(str_c("Unknown flag: ", flag))
  }

  i <- i + 2
}

input_start <- input_start %>% str_squish() %>% na_if("")
input_end <- input_end %>% str_squish() %>% na_if("")
start_label <- start_label %>% str_squish()
end_label <- end_label %>% str_squish()
state_filter <- state_filter %>% str_squish() %>% na_if("")
format <- format %>% str_to_lower() %>% str_squish()
output <- output %>% str_squish() %>% na_if("")

# ------------------------------
# 2) Validate arguments
# ------------------------------
if (is.na(input_start) || is.na(input_end)) {
  stop("Usage: Rscript analyze_majority_minority_change.R --input-start <csv> --input-end <csv> [--start-label 2010] [--end-label 2020] [--state <state>] [--format csv|json] [--output path]")
}
if (!format %in% c("csv", "json")) {
  stop("--format must be 'csv' or 'json'")
}

# ------------------------------
# 3) Read and validate input data
# ------------------------------
start_raw <- read_csv(input_start, show_col_types = FALSE)
end_raw <- read_csv(input_end, show_col_types = FALSE)

required_metrics <- c("total_population", "non_hispanic_white")
missing_start <- setdiff(required_metrics, names(start_raw))
missing_end <- setdiff(required_metrics, names(end_raw))
if (length(missing_start) > 0 || length(missing_end) > 0) {
  stop(str_c(
    "Missing required columns. Start missing: ", str_c(missing_start, collapse = ", "),
    " | End missing: ", str_c(missing_end, collapse = ", ")
  ))
}

join_keys <- character()
if ("county_fips" %in% names(start_raw) && "county_fips" %in% names(end_raw)) {
  join_keys <- c(join_keys, "county_fips")
}
if ("state" %in% names(start_raw) && "state" %in% names(end_raw)) {
  join_keys <- c(join_keys, "state")
}
if ("county" %in% names(start_raw) && "county" %in% names(end_raw)) {
  join_keys <- c(join_keys, "county")
}

if (!("county_fips" %in% join_keys) && !all(c("state", "county") %in% join_keys)) {
  stop("Inputs must share county_fips OR both state and county columns")
}

# ------------------------------
# 4) Prepare each year and join
# ------------------------------
start_df <- start_raw %>%
  mutate(
    total_population = as.numeric(total_population),
    non_hispanic_white = as.numeric(non_hispanic_white),
    nonwhite_share = if_else(total_population > 0, 1 - (non_hispanic_white / total_population), NA_real_)
  ) %>%
  select(all_of(join_keys), total_population, non_hispanic_white, nonwhite_share) %>%
  rename(
    !!str_c("total_population_", start_label) := total_population,
    !!str_c("non_hispanic_white_", start_label) := non_hispanic_white,
    !!str_c("nonwhite_share_", start_label) := nonwhite_share
  )

end_df <- end_raw %>%
  mutate(
    total_population = as.numeric(total_population),
    non_hispanic_white = as.numeric(non_hispanic_white),
    nonwhite_share = if_else(total_population > 0, 1 - (non_hispanic_white / total_population), NA_real_)
  ) %>%
  select(all_of(join_keys), total_population, non_hispanic_white, nonwhite_share) %>%
  rename(
    !!str_c("total_population_", end_label) := total_population,
    !!str_c("non_hispanic_white_", end_label) := non_hispanic_white,
    !!str_c("nonwhite_share_", end_label) := nonwhite_share
  )

joined <- inner_join(start_df, end_df, by = join_keys)

if (nrow(joined) == 0) {
  stop("No matched rows after join. Check key columns and values.")
}

if (!is.na(state_filter) && "state" %in% join_keys) {
  joined <- joined %>%
    filter(str_to_upper(as.character(state)) == str_to_upper(state_filter))
}

if (nrow(joined) == 0) {
  stop("No rows after state filter")
}

# ------------------------------
# 5) Compute change and threshold flags
# ------------------------------
start_share_col <- str_c("nonwhite_share_", start_label)
end_share_col <- str_c("nonwhite_share_", end_label)

out <- joined %>%
  mutate(
    delta_nonwhite_share_pp = (.data[[end_share_col]] - .data[[start_share_col]]) * 100,
    crossed_to_majority_minority = .data[[start_share_col]] < 0.5 & .data[[end_share_col]] >= 0.5,
    crossed_out_of_majority_minority = .data[[start_share_col]] >= 0.5 & .data[[end_share_col]] < 0.5
  ) %>%
  arrange(desc(abs(delta_nonwhite_share_pp)))

# ------------------------------
# 6) Write output
# ------------------------------
if (is.na(output)) {
  ext <- if_else(format == "json", "json", "csv")
  output <- str_c(
    "data/processed/majority_minority_change_",
    start_label,
    "_",
    end_label,
    ".",
    ext
  )
}

dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)

if (format == "json") {
  write_json(out, output, pretty = TRUE, dataframe = "rows", auto_unbox = TRUE, na = "null")
} else {
  write_csv(out, output)
}

message(str_c("Wrote ", nrow(out), " row(s) to ", output))
