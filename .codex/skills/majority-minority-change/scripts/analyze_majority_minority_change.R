#!/usr/bin/env Rscript

library(dplyr)
library(readr)
library(stringr)
library(jsonlite)


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
  "--input-start",
  "--input-end",
  "--start-label",
  "--end-label",
  "--state",
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

input_start <- get_arg_value("--input-start")
input_end <- get_arg_value("--input-end")
start_label <- get_arg_value("--start-label", "2010")
end_label <- get_arg_value("--end-label", "2020")
state_filter <- get_arg_value("--state")
format <- get_arg_value("--format", "csv")
output <- get_arg_value("--output")

input_start <- input_start %>% str_squish() %>% na_if("")
input_end <- input_end %>% str_squish() %>% na_if("")
start_label <- start_label %>% str_squish()
end_label <- end_label %>% str_squish()
state_filter <- state_filter %>% str_squish() %>% na_if("")
format <- format %>% str_to_lower() %>% str_squish()
output <- output %>% str_squish() %>% na_if("")

# ------------------------------
# 2a) State normalization helpers
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
  rlang::set_names(state_abbrev_values, normalize_state_key(state_name_values)),
  rlang::set_names(state_abbrev_values, normalize_state_key(state_abbrev_values))
)

normalize_state_value <- function(x) {
  x_chr <- as.character(x)
  out <- rep(NA_character_, length(x_chr))
  valid <- !is.na(x_chr)

  if (any(valid)) {
    keys <- normalize_state_key(x_chr[valid])
    mapped <- unname(state_lookup[keys])
    fallback <- x_chr[valid] %>% str_squish() %>% str_to_upper()
    out[valid] <- if_else(!is.na(mapped), mapped, fallback)
  }

  out
}

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

common_cols <- intersect(names(start_raw), names(end_raw))
has_county_fips <- "county_fips" %in% common_cols
has_state_county <- all(c("state", "county") %in% common_cols)
if (has_county_fips) {
  # Prefer stable FIPS IDs to avoid dropping valid rows on name/encoding changes.
  join_keys <- "county_fips"
} else if (has_state_county) {
  join_keys <- c("state", "county")
} else {
  stop("Inputs must share county_fips OR both state and county columns")
}
end_label_cols <- setdiff(intersect(c("state", "county"), names(end_raw)), join_keys)

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
  select(all_of(c(join_keys, end_label_cols)), total_population, non_hispanic_white, nonwhite_share) %>%
  rename(
    !!str_c("total_population_", end_label) := total_population,
    !!str_c("non_hispanic_white_", end_label) := non_hispanic_white,
    !!str_c("nonwhite_share_", end_label) := nonwhite_share
  )

joined <- inner_join(start_df, end_df, by = join_keys)

if (nrow(joined) == 0) {
  stop("No matched rows after join. Check key columns and values.")
}

if (!is.na(state_filter)) {
  if (!"state" %in% names(joined)) {
    stop("Cannot apply --state filter because neither input contains a shared state column")
  }
  state_filter_norm <- normalize_state_value(state_filter)
  joined <- joined %>%
    filter(normalize_state_value(state) == state_filter_norm)
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
