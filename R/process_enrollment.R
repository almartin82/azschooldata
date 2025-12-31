# ==============================================================================
# Enrollment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw ADE enrollment data into a
# clean, standardized format.
#
# ==============================================================================

#' Process raw ADE enrollment data
#'
#' Transforms raw ADE data into a standardized schema combining school
#' and district data.
#'
#' @param raw_data List containing school and district data frames from get_raw_enr
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_enr <- function(raw_data, end_year) {

  # Process school (campus) data
  school_processed <- process_school_enr(raw_data$school, end_year)

  # Process district/LEA data
  district_processed <- process_district_enr(raw_data$district, end_year)

  # Create state aggregate
  state_processed <- create_state_aggregate(district_processed, end_year)

  # Combine all levels
  result <- dplyr::bind_rows(state_processed, district_processed, school_processed)

  result
}


#' Process school-level enrollment data
#'
#' @param df Raw school data frame
#' @param end_year School year end
#' @return Processed school data frame
#' @keywords internal
process_school_enr <- function(df, end_year) {

  if (is.null(df) || nrow(df) == 0) {
    return(data.frame())
  }

  cols <- names(df)
  n_rows <- nrow(df)

  # Helper to find column by pattern (case-insensitive, partial match)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      # Try exact match first
      matched <- grep(paste0("^", pattern, "$"), cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])

      # Try partial match
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Get column mappings
  col_map <- get_ade_column_map()

  # Build result dataframe
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("Campus", n_rows),
    stringsAsFactors = FALSE
  )

  # Entity ID and name
  id_col <- find_col(col_map$entity_id)
  if (!is.null(id_col)) {
    result$campus_id <- trimws(df[[id_col]])
  }

  name_col <- find_col(col_map$entity_name)
  if (!is.null(name_col)) {
    result$campus_name <- trimws(df[[name_col]])
  }

  # Try to extract district ID from campus ID or from separate column
  district_id_col <- find_col(c("LEA Entity ID", "District ID", "LEA ID", "DistrictID"))
  if (!is.null(district_id_col)) {
    result$district_id <- trimws(df[[district_id_col]])
  } else if (!is.null(id_col)) {
    # AZ campus IDs often contain LEA ID as prefix
    result$district_id <- NA_character_
  }

  district_name_col <- find_col(c("LEA Name", "District Name", "LEA", "District"))
  if (!is.null(district_name_col)) {
    result$district_name <- trimws(df[[district_name_col]])
  }

  # County
  county_col <- find_col(col_map$county)
  if (!is.null(county_col)) {
    result$county <- trimws(df[[county_col]])
  }

  # Total enrollment
  total_col <- find_col(col_map$total)
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  }

  # Demographics - Ethnicity
  demo_map <- list(
    white = col_map$white,
    black = col_map$black,
    hispanic = col_map$hispanic,
    asian = col_map$asian,
    native_american = col_map$native_american,
    pacific_islander = col_map$pacific_islander,
    multiracial = col_map$multiracial
  )

  for (name in names(demo_map)) {
    col <- find_col(demo_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  # Demographics - Gender
  male_col <- find_col(col_map$male)
  if (!is.null(male_col)) {
    result$male <- safe_numeric(df[[male_col]])
  }

  female_col <- find_col(col_map$female)
  if (!is.null(female_col)) {
    result$female <- safe_numeric(df[[female_col]])
  }

  # Special populations
  special_map <- list(
    econ_disadv = col_map$econ_disadv,
    lep = col_map$lep,
    special_ed = col_map$special_ed
  )

  for (name in names(special_map)) {
    col <- find_col(special_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  # Grade levels
  grade_map <- list(
    grade_pk = col_map$grade_pk,
    grade_k = col_map$grade_k,
    grade_01 = col_map$grade_01,
    grade_02 = col_map$grade_02,
    grade_03 = col_map$grade_03,
    grade_04 = col_map$grade_04,
    grade_05 = col_map$grade_05,
    grade_06 = col_map$grade_06,
    grade_07 = col_map$grade_07,
    grade_08 = col_map$grade_08,
    grade_09 = col_map$grade_09,
    grade_10 = col_map$grade_10,
    grade_11 = col_map$grade_11,
    grade_12 = col_map$grade_12
  )

  for (name in names(grade_map)) {
    col <- find_col(grade_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  # Remove rows with no ID or no total (likely header rows or empty)
  if ("campus_id" %in% names(result) && "row_total" %in% names(result)) {
    result <- result[!is.na(result$campus_id) | !is.na(result$row_total), ]
  }

  result
}


#' Process district-level enrollment data
#'
#' @param df Raw district data frame
#' @param end_year School year end
#' @return Processed district data frame
#' @keywords internal
process_district_enr <- function(df, end_year) {

  if (is.null(df) || nrow(df) == 0) {
    return(data.frame())
  }

  cols <- names(df)
  n_rows <- nrow(df)

  # Helper to find column by pattern
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(paste0("^", pattern, "$"), cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Get column mappings
  col_map <- get_ade_column_map()

  # Build result dataframe
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("District", n_rows),
    stringsAsFactors = FALSE
  )

  # District ID and name
  id_col <- find_col(col_map$entity_id)
  if (!is.null(id_col)) {
    result$district_id <- trimws(df[[id_col]])
  }

  name_col <- find_col(col_map$entity_name)
  if (!is.null(name_col)) {
    result$district_name <- trimws(df[[name_col]])
  }

  # No campus for district level
  result$campus_id <- rep(NA_character_, n_rows)
  result$campus_name <- rep(NA_character_, n_rows)

  # County
  county_col <- find_col(col_map$county)
  if (!is.null(county_col)) {
    result$county <- trimws(df[[county_col]])
  }

  # Total enrollment
  total_col <- find_col(col_map$total)
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  }

  # Demographics - Ethnicity
  demo_map <- list(
    white = col_map$white,
    black = col_map$black,
    hispanic = col_map$hispanic,
    asian = col_map$asian,
    native_american = col_map$native_american,
    pacific_islander = col_map$pacific_islander,
    multiracial = col_map$multiracial
  )

  for (name in names(demo_map)) {
    col <- find_col(demo_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  # Gender
  male_col <- find_col(col_map$male)
  if (!is.null(male_col)) {
    result$male <- safe_numeric(df[[male_col]])
  }

  female_col <- find_col(col_map$female)
  if (!is.null(female_col)) {
    result$female <- safe_numeric(df[[female_col]])
  }

  # Special populations
  special_map <- list(
    econ_disadv = col_map$econ_disadv,
    lep = col_map$lep,
    special_ed = col_map$special_ed
  )

  for (name in names(special_map)) {
    col <- find_col(special_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  # Grade levels
  grade_map <- list(
    grade_pk = col_map$grade_pk,
    grade_k = col_map$grade_k,
    grade_01 = col_map$grade_01,
    grade_02 = col_map$grade_02,
    grade_03 = col_map$grade_03,
    grade_04 = col_map$grade_04,
    grade_05 = col_map$grade_05,
    grade_06 = col_map$grade_06,
    grade_07 = col_map$grade_07,
    grade_08 = col_map$grade_08,
    grade_09 = col_map$grade_09,
    grade_10 = col_map$grade_10,
    grade_11 = col_map$grade_11,
    grade_12 = col_map$grade_12
  )

  for (name in names(grade_map)) {
    col <- find_col(grade_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  # Remove rows with no ID or no total
  if ("district_id" %in% names(result) && "row_total" %in% names(result)) {
    result <- result[!is.na(result$district_id) | !is.na(result$row_total), ]
  }

  result
}


#' Create state-level aggregate from district data
#'
#' @param district_df Processed district data frame
#' @param end_year School year end
#' @return Single-row data frame with state totals
#' @keywords internal
create_state_aggregate <- function(district_df, end_year) {

  if (is.null(district_df) || nrow(district_df) == 0) {
    return(data.frame(
      end_year = end_year,
      type = "State",
      district_id = NA_character_,
      campus_id = NA_character_,
      district_name = NA_character_,
      campus_name = NA_character_,
      stringsAsFactors = FALSE
    ))
  }

  # Columns to sum
  sum_cols <- c(
    "row_total",
    "white", "black", "hispanic", "asian",
    "pacific_islander", "native_american", "multiracial",
    "male", "female",
    "econ_disadv", "lep", "special_ed",
    "grade_pk", "grade_k",
    "grade_01", "grade_02", "grade_03", "grade_04",
    "grade_05", "grade_06", "grade_07", "grade_08",
    "grade_09", "grade_10", "grade_11", "grade_12"
  )

  # Filter to columns that exist
  sum_cols <- sum_cols[sum_cols %in% names(district_df)]

  # Create state row
  state_row <- data.frame(
    end_year = end_year,
    type = "State",
    district_id = NA_character_,
    campus_id = NA_character_,
    district_name = NA_character_,
    campus_name = NA_character_,
    county = NA_character_,
    stringsAsFactors = FALSE
  )

  # Sum each column
  for (col in sum_cols) {
    state_row[[col]] <- sum(district_df[[col]], na.rm = TRUE)
  }

  state_row
}
