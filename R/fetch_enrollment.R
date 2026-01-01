# ==============================================================================
# Enrollment Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading enrollment data from the
# Arizona Department of Education (ADE) website.
#
# ==============================================================================

#' Fetch Arizona enrollment data
#'
#' Downloads and processes enrollment data from the Arizona Department of
#' Education's October 1 enrollment reports.
#'
#' @param end_year A school year. Year is the end of the academic year - eg 2023-24
#'   school year is year '2024'. Valid values are 2018-2026.
#'
#'   Data availability notes:
#'   - Excel files are available from FY2018 (end_year 2018) onwards
#'   - Older data (2011-2017) may be available through manual requests to ADE
#'   - Earlier years (1990s-2000s) exist only as PDF reports and are not supported
#'   - ADE uses varying URL patterns across years; download may take a few seconds
#'     as the package tries multiple URL patterns
#'
#' @param tidy If TRUE (default), returns data in long (tidy) format with subgroup
#'   column. If FALSE, returns wide format.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#'   Set to FALSE to force re-download from ADE.
#' @return Data frame with enrollment data. Wide format includes columns for
#'   district_id, campus_id, names, and enrollment counts by demographic/grade.
#'   Tidy format pivots these counts into subgroup and grade_level columns.
#' @export
#' @examples
#' \dontrun{
#' # Get 2024 enrollment data (2023-24 school year)
#' enr_2024 <- fetch_enr(2024)
#'
#' # Get wide format
#' enr_wide <- fetch_enr(2024, tidy = FALSE)
#'
#' # Force fresh download (ignore cache)
#' enr_fresh <- fetch_enr(2024, use_cache = FALSE)
#'
#' # Get historical data from 2018
#' enr_2018 <- fetch_enr(2018)
#'
#' # Filter to specific district
#' phoenix_union <- enr_2024 |>
#'   dplyr::filter(grepl("Phoenix Union", district_name, ignore.case = TRUE))
#' }
fetch_enr <- function(end_year, tidy = TRUE, use_cache = TRUE) {

  # Validate year - ADE data available from 2018 onwards
  if (end_year < 2018 || end_year > 2026) {
    stop("end_year must be between 2018 and 2026")
  }

  # Determine cache type based on tidy parameter
  cache_type <- if (tidy) "tidy" else "wide"

  # Check cache first
  if (use_cache && cache_exists(end_year, cache_type)) {
    message(paste("Using cached data for", end_year))
    return(read_cache(end_year, cache_type))
  }

  # Get raw data from ADE
  raw <- get_raw_enr(end_year)

  # Process to standard schema
  processed <- process_enr(raw, end_year)

  # Optionally tidy
  if (tidy) {
    processed <- tidy_enr(processed) |>
      id_enr_aggs()
  }

  # Cache the result
  if (use_cache) {
    write_cache(processed, end_year, cache_type)
  }

  processed
}


#' Fetch enrollment data for multiple years
#'
#' Downloads and combines enrollment data for multiple school years.
#'
#' @param end_years Vector of school year ends (e.g., c(2022, 2023, 2024)).
#'   Valid range is 2018-2026.
#' @param tidy If TRUE (default), returns data in long (tidy) format.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#' @return Combined data frame with enrollment data for all requested years
#' @export
#' @examples
#' \dontrun{
#' # Get 3 years of data
#' enr_multi <- fetch_enr_multi(2022:2024)
#'
#' # Get full available range
#' enr_all <- fetch_enr_multi(2018:2025)
#'
#' # Track enrollment trends
#' enr_multi |>
#'   dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
#'   dplyr::select(end_year, n_students)
#' }
fetch_enr_multi <- function(end_years, tidy = TRUE, use_cache = TRUE) {

  # Validate years
  invalid_years <- end_years[end_years < 2018 | end_years > 2026]
  if (length(invalid_years) > 0) {
    stop(paste("Invalid years:", paste(invalid_years, collapse = ", "),
               "\nend_year must be between 2018 and 2026"))
  }

  # Fetch each year
  results <- purrr::map(
    end_years,
    function(yr) {
      message(paste("Fetching", yr, "..."))
      fetch_enr(yr, tidy = tidy, use_cache = use_cache)
    }
  )

  # Combine
  dplyr::bind_rows(results)
}
