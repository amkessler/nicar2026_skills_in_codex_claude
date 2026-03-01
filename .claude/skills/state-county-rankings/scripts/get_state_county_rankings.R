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

input <- NA_character_
state_query <- NA_character_
metrics_text <- "total_population,median_household_income,poverty_rate,median_gross_rent"
top_n <- 10L
direction <- "desc"
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
  } else if (flag == "--state") {
    state_query <- value
  } else if (flag == "--metrics") {
    metrics_text <- value
  } else if (flag == "--top-n") {
    top_n <- as.integer(value)
  } else if (flag == "--direction") {
    direction <- value
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
state_query <- state_query %>% str_squish() %>% na_if("")
direction <- direction %>% str_to_lower() %>% str_squish()
format <- format %>% str_to_lower() %>% str_squish()
output <- output %>% str_squish() %>% na_if("")

metrics <- unlist(str_split(metrics_text, ","), use.names = FALSE)
metrics <- str_squish(metrics)
metrics <- metrics[metrics != ""]

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

filtered <- raw %>%
  mutate(state_value = .data[[state_col]]) %>%
  filter(str_to_upper(as.character(state_value)) == str_to_upper(state_query))

if (nrow(filtered) == 0) {
  stop("No rows matched --state in the selected state column")
}

# ------------------------------
# 4) Rank counties metric-by-metric
# ------------------------------
ranked_list <- list()

for (metric_name in metrics) {
  metric_df <- filtered %>%
    transmute(
      state = as.character(state_value),
      county = as.character(county),
      metric = metric_name,
      value = as.numeric(.data[[metric_name]])
    ) %>%
    filter(!is.na(value))

  if (nrow(metric_df) == 0) {
    next
  }

  if (direction == "desc") {
    metric_df <- metric_df %>% arrange(desc(value), county)
  } else {
    metric_df <- metric_df %>% arrange(value, county)
  }

  metric_df <- metric_df %>%
    mutate(
      rank = row_number(),
      direction = direction
    ) %>%
    filter(rank <= top_n)

  ranked_list[[metric_name]] <- metric_df
}

if (length(ranked_list) == 0) {
  stop("No ranked rows produced. Check metric values for missing/non-numeric data.")
}

ranked <- bind_rows(ranked_list) %>%
  select(state, county, metric, value, rank, direction)

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
