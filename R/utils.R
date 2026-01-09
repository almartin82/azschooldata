# ==============================================================================
# Utility Functions
# ==============================================================================

#' @importFrom rlang .data
#' @importFrom tidyr pivot_wider
NULL


#' Get available years for Arizona enrollment data
#'
#' Returns the range of school years for which enrollment data is available
#' from the Arizona Department of Education.
#'
#' @return A list with three elements:
#'   \item{min_year}{The earliest available school year end (e.g., 2011 for 2010-11)}
#'   \item{max_year}{The latest available school year end (e.g., 2024 for 2023-24)}
#'   \item{description}{Human-readable description of data availability}
#' @export
#' @examples
#' get_available_years()
#' # Returns list with min_year, max_year, and description
get_available_years <- function() {
  list(
    min_year = 2018,
    max_year = 2024,
    description = "Arizona enrollment data is available from 2017-18 (end_year 2018) through 2023-24 (end_year 2024). Data comes from the October 1 enrollment reports published by the Arizona Department of Education. Older data (2011-2017) may be available through manual requests to ADE. Earlier years (1990s-2000s) exist only as PDF reports and are not currently supported."
  )
}


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
