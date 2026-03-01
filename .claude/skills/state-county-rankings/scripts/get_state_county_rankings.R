#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(stringr)
  library(jsonlite)
})

# ------------------------------
# 1) Parse CLI arguments
# ------------------------------
args <- commandArgs(trailingOnly = TRUE)

if (length(args) %% 2 != 0) {
  stop("Arguments must be provided as --flag value pairs")
}

if (length(args) > 0) {
  arg_tbl <- tibble::tibble(
    flag = args[seq(1, length(args), by = 2)],
    value = args[seq(2, length(args), by = 2)]
  ) %>%
    mutate(
      flag = str_squish(flag),
      value = str_squish(value)
    )
} else {
  arg_tbl <- tibble::tibble(flag = character(), value = character())
}

if (any(!str_starts(arg_tbl$flag, "--"))) {
  bad_flag <- arg_tbl$flag[!str_starts(arg_tbl$flag, "--")][[1]]
  stop(str_c("Unexpected token: ", bad_flag))
}

allowed_flags <- c(
  "--input",
  "--state",
  "--metrics",
  "--top-n",
  "--direction",
  "--format",
  "--output"
)
unknown_flags <- setdiff(unique(arg_tbl$flag), allowed_flags)
if (length(unknown_flags) > 0) {
  stop(str_c("Unknown flag: ", unknown_flags[[1]]))
}

get_arg_value <- function(flag_name, default = NA_character_) {
  values <- arg_tbl %>%
    filter(.data$flag == .env$flag_name) %>%
    pull(value)
  if (length(values) == 0) {
    return(default)
  }
  values[[length(values)]]
}

input <- get_arg_value("--input")
state_query <- get_arg_value("--state")
metrics_text <- get_arg_value("--metrics", "total_population,median_household_income,poverty_rate,median_gross_rent")
top_n <- suppressWarnings(as.integer(get_arg_value("--top-n", "10")))
direction <- get_arg_value("--direction", "desc")
format <- get_arg_value("--format", "csv")
output <- get_arg_value("--output")

input <- input %>% str_squish() %>% na_if("")
state_query <- state_query %>% str_squish() %>% na_if("")
direction <- direction %>% str_to_lower() %>% str_squish()
format <- format %>% str_to_lower() %>% str_squish()
output <- output %>% str_squish() %>% na_if("")

metrics <- unlist(str_split(metrics_text, ","), use.names = FALSE)
metrics <- str_squish(metrics)
metrics <- metrics[metrics != ""]

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
if (is.na(input) || is.na(state_query)) {
  stop("Usage: Rscript get_state_county_rankings.R --input <csv> --state <state> [--metrics a,b,c] [--top-n 10] [--direction desc|asc] [--format csv|json] [--output path]")
}
if (length(metrics) == 0) {
  stop("--metrics must include at least one metric column")
}
if (is.na(top_n) || top_n <= 0) {
  stop("--top-n must be a positive integer")
}
if (!direction %in% c("asc", "desc")) {
  stop("--direction must be 'asc' or 'desc'")
}
if (!format %in% c("csv", "json")) {
  stop("--format must be 'csv' or 'json'")
}

# ------------------------------
# 3) Read and validate input data
# ------------------------------
raw <- read_csv(input, show_col_types = FALSE)

state_col <- NA_character_
if ("state" %in% names(raw)) {
  state_col <- "state"
} else if ("state_name" %in% names(raw)) {
  state_col <- "state_name"
} else if ("state_abbrev" %in% names(raw)) {
  state_col <- "state_abbrev"
}

if (is.na(state_col)) {
  stop("Input file must include one of: state, state_name, state_abbrev")
}
if (!"county" %in% names(raw)) {
  stop("Input file must include a 'county' column")
}

missing_metrics <- setdiff(metrics, names(raw))
if (length(missing_metrics) > 0) {
  stop(str_c("Missing metric columns: ", str_c(missing_metrics, collapse = ", ")))
}

state_query_norm <- normalize_state_value(state_query)

filtered <- raw %>%
  mutate(state_value = .data[[state_col]]) %>%
  filter(normalize_state_value(state_value) == state_query_norm)

if (nrow(filtered) == 0) {
  stop("No rows matched --state in the selected state column")
}

# ------------------------------
# 4) Rank counties metric-by-metric
# ------------------------------
ranked <- filtered %>%
  transmute(
    state = as.character(state_value),
    county = as.character(county),
    across(all_of(metrics), ~as.numeric(.x))
  ) %>%
  pivot_longer(
    cols = all_of(metrics),
    names_to = "metric",
    values_to = "value"
  ) %>%
  filter(!is.na(value)) %>%
  group_by(metric) %>%
  {
    if (direction == "desc") {
      arrange(., desc(value), county, .by_group = TRUE)
    } else {
      arrange(., value, county, .by_group = TRUE)
    }
  } %>%
  mutate(
    rank = row_number(),
    direction = direction
  ) %>%
  filter(rank <= top_n) %>%
  ungroup() %>%
  select(state, county, metric, value, rank, direction)

if (nrow(ranked) == 0) {
  stop("No ranked rows produced. Check metric values for missing/non-numeric data.")
}

# ------------------------------
# 5) Write output
# ------------------------------
if (is.na(output)) {
  state_slug <- state_query %>%
    str_to_lower() %>%
    str_replace_all("[^a-z0-9]+", "_") %>%
    str_replace_all("^_|_$", "")
  ext <- if_else(format == "json", "json", "csv")
  output <- str_c("data/processed/", state_slug, "_county_rankings.", ext)
}

dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)

if (format == "json") {
  write_json(ranked, output, pretty = TRUE, dataframe = "rows", auto_unbox = TRUE, na = "null")
} else {
  write_csv(ranked, output)
}

message(str_c("Wrote ", nrow(ranked), " row(s) to ", output))
