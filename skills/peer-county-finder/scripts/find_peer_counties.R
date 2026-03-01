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

input <- NA_character_
target_state <- NA_character_
target_county <- NA_character_
features_text <- "total_population,median_household_income,poverty_rate,median_age,median_gross_rent"
top_n <- 10L
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

  if (flag == "--input") {
    input <- value
  } else if (flag == "--target-state") {
    target_state <- value
  } else if (flag == "--target-county") {
    target_county <- value
  } else if (flag == "--features") {
    features_text <- value
  } else if (flag == "--top-n") {
    top_n <- as.integer(value)
  } else if (flag == "--format") {
    format <- value
  } else if (flag == "--output") {
    output <- value
  } else {
    stop(str_c("Unknown flag: ", flag))
  }

  i <- i + 2
}

input <- input %>% str_squish() %>% na_if("")
target_state <- target_state %>% str_squish() %>% na_if("")
target_county <- target_county %>% str_squish() %>% na_if("")
format <- format %>% str_to_lower() %>% str_squish()
output <- output %>% str_squish() %>% na_if("")

features <- unlist(str_split(features_text, ","), use.names = FALSE)
features <- str_squish(features)
features <- features[features != ""]

# ------------------------------
# 1b) State normalization helpers
# ------------------------------
normalize_state_key <- function(x) {
  x %>%
    as.character() %>%
    str_squish() %>%
    str_to_upper() %>%
    str_replace_all("[^A-Z0-9]", "")
}

state_name_values <- c(
  state.name,
  "District of Columbia",
  "Puerto Rico",
  "American Samoa",
  "Guam",
  "Northern Mariana Islands",
  "U.S. Virgin Islands",
  "United States Virgin Islands",
  "Virgin Islands"
)

state_abbrev_values <- c(
  state.abb,
  "DC",
  "PR",
  "AS",
  "GU",
  "MP",
  "VI",
  "VI",
  "VI"
)

state_lookup <- c(
  setNames(state_abbrev_values, normalize_state_key(state_name_values)),
  setNames(state_abbrev_values, normalize_state_key(state_abbrev_values))
)

normalize_state_value <- function(x) {
  x_chr <- as.character(x)
  out <- rep(NA_character_, length(x_chr))
  valid <- !is.na(x_chr)

  if (any(valid)) {
    keys <- normalize_state_key(x_chr[valid])
    mapped <- unname(state_lookup[keys])
    fallback <- x_chr[valid] %>% str_squish() %>% str_to_upper()
    out[valid] <- ifelse(!is.na(mapped), mapped, fallback)
  }

  out
}

# ------------------------------
# 2) Validate arguments
# ------------------------------
if (is.na(input) || is.na(target_state) || is.na(target_county)) {
  stop("Usage: Rscript find_peer_counties.R --input <csv> --target-state <state> --target-county <county> [--features a,b,c] [--top-n 10] [--format csv|json] [--output path]")
}
if (length(features) == 0) {
  stop("--features must include at least one feature column")
}
if (is.na(top_n) || top_n <= 0) {
  stop("--top-n must be a positive integer")
}
if (!format %in% c("csv", "json")) {
  stop("--format must be 'csv' or 'json'")
}

# ------------------------------
# 3) Read and validate input data
# ------------------------------
raw <- read_csv(input, show_col_types = FALSE)

required_base <- c("state", "county")
missing_base <- setdiff(required_base, names(raw))
if (length(missing_base) > 0) {
  stop(str_c("Missing required columns: ", str_c(missing_base, collapse = ", ")))
}

missing_features <- setdiff(features, names(raw))
if (length(missing_features) > 0) {
  stop(str_c("Missing feature columns: ", str_c(missing_features, collapse = ", ")))
}

target_state_norm <- normalize_state_value(target_state)

prepared <- raw %>%
  mutate(
    row_id = row_number(),
    state_norm = normalize_state_value(state),
    across(all_of(features), as.numeric)
  ) %>%
  filter(if_all(all_of(features), ~ !is.na(.x)))

if (nrow(prepared) == 0) {
  stop("No rows with complete feature values")
}

target_row <- prepared %>%
  filter(
    state_norm == target_state_norm,
    str_to_upper(as.character(county)) == str_to_upper(target_county)
  ) %>%
  slice_head(n = 1)

if (nrow(target_row) == 0) {
  stop("Target county/state not found with complete feature values")
}

target_id <- target_row$row_id[[1]]

# ------------------------------
# 4) Standardize features and compute distances
# ------------------------------
scaled <- prepared
for (feature_name in features) {
  scaled[[feature_name]] <- as.numeric(scale(scaled[[feature_name]]))
}

target_vector <- as.numeric(
  scaled %>%
    filter(row_id == target_id) %>%
    select(all_of(features))
)

distance_values <- rep(NA_real_, nrow(scaled))
for (row_idx in seq_len(nrow(scaled))) {
  row_vector <- as.numeric(scaled[row_idx, features, drop = TRUE])
  distance_values[[row_idx]] <- sqrt(sum((row_vector - target_vector)^2))
}

distance_frame <- scaled %>%
  transmute(row_id, distance = distance_values)

out <- prepared %>%
  select(row_id, state, county, all_of(features)) %>%
  left_join(distance_frame, by = "row_id") %>%
  filter(row_id != target_id) %>%
  arrange(distance, state, county) %>%
  mutate(similarity_rank = row_number()) %>%
  slice_head(n = top_n) %>%
  select(similarity_rank, state, county, distance, all_of(features))

if (nrow(out) == 0) {
  stop("No peer counties were found after filtering")
}

# ------------------------------
# 5) Write output
# ------------------------------
if (is.na(output)) {
  slug <- str_c(target_county, "_", target_state) %>%
    str_to_lower() %>%
    str_replace_all("[^a-z0-9]+", "_") %>%
    str_replace_all("^_|_$", "")
  ext <- if_else(format == "json", "json", "csv")
  output <- str_c("data/processed/", slug, "_peer_counties.", ext)
}

dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)

if (format == "json") {
  write_json(out, output, pretty = TRUE, dataframe = "rows", auto_unbox = TRUE, na = "null")
} else {
  write_csv(out, output)
}

message(str_c("Wrote ", nrow(out), " row(s) to ", output))
