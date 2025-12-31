# ==============================================================================
# Utility Functions
# ==============================================================================

#' Pipe operator
#'
#' See \code{dplyr::\link[dplyr:reexports]{\%>\%}} for details.
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom dplyr %>%
#' @usage lhs \%>\% rhs
#' @param lhs A value or the magrittr placeholder.
#' @param rhs A function call using the magrittr semantics.
#' @return The result of calling `rhs(lhs)`.
NULL


#' Convert to numeric, handling suppression markers
#'
#' ADE uses asterisks (*) for suppressed data (groups with fewer than 11 students)
#' and may use commas in large numbers.
#'
#' @param x Vector to convert
#' @return Numeric vector with NA for non-numeric values
#' @keywords internal
safe_numeric <- function(x) {
  # Remove commas and whitespace
  x <- gsub(",", "", x)
  x <- trimws(x)

  # Handle common suppression markers
  # ADE uses * for FERPA suppression (groups < 11 students)
  x[x %in% c("*", ".", "-", "-1", "<11", "N/A", "NA", "", "**")] <- NA_character_

  suppressWarnings(as.numeric(x))
}


#' Clean column names for consistency
#'
#' Standardizes column names by converting to lowercase, replacing spaces
#' and special characters with underscores.
#'
#' @param names Character vector of column names
#' @return Cleaned column names
#' @keywords internal
clean_names <- function(names) {
  names <- tolower(names)
  names <- gsub("[^a-z0-9]+", "_", names)
  names <- gsub("^_|_$", "", names)
  names <- gsub("__+", "_", names)
  names
}


#' Get fiscal year from end_year
#'
#' Arizona uses fiscal year notation (FY24 = 2023-24 school year).
#' The end_year (2024) corresponds to FY24.
#'
#' @param end_year School year end (e.g., 2024 for 2023-24 school year)
#' @return Fiscal year string (e.g., "FY24")
#' @keywords internal
get_fy <- function(end_year) {
  paste0("FY", substr(as.character(end_year), 3, 4))
}


#' Get school year range from end_year
#'
#' @param end_year School year end (e.g., 2024 for 2023-24 school year)
#' @return School year range string (e.g., "2023-2024")
#' @keywords internal
get_school_year_range <- function(end_year) {
  paste0(end_year - 1, "-", end_year)
}
