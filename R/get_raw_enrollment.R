# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data from the
# Arizona Department of Education (ADE).
#
# Data comes from the Accountability & Research division:
# https://www.azed.gov/accountability-research/data
#
# The October 1 enrollment reports contain enrollment counts at state, county,
# LEA (district/charter), and school levels with demographic breakdowns.
#
# Data Availability:
# - Excel files are available from FY2018 (end_year 2018) onwards
# - Data from FY2011-FY2017 (end_year 2011-2017) may be available through
#   manual requests to ADE, but automatic download URLs are no longer accessible
# - PDF-only financial reports exist for earlier years (1990s-2000s) but are
#   not currently supported by this package
# - Note: ADE uses different URL patterns across years, so this package tries
#   multiple URL patterns to locate each year's file
#
# Format Eras:
# - Era 1 (2011-2017): Original Excel format with multiple tabs by level
#   URL pattern examples:
#     /2017/06/october-1-2012-2013.enrollment_count.xlsx
#     /2017/06/october-1-fy16-enrollment.xlsx
# - Era 2 (2018-2023): Updated format with FY notation
#   URL pattern examples:
#     /2019/10/Fiscal Year 2019 Accountabilty October Enrollment REDACTED.xlsx
#     /2021/05/2017-2018 October 1 Public Enrollment File UPDATED 2021 V2.xlsx
# - Era 3 (2024-present): Newest format with simplified naming
#   URL pattern examples:
#     /2023/11/Oct1Enrollment2024_publish.xlsx
#     /2025/04/Oct1EnrollmentFY2025.xlsx
#
# ==============================================================================

#' Download raw enrollment data from ADE
#'
#' Downloads the October 1 enrollment report Excel file from ADE's website.
#' ADE publishes enrollment counts annually with breakdowns by demographics.
#'
#' @param end_year School year end (2023-24 = 2024)
#' @return List with school and district data frames
#' @keywords internal
get_raw_enr <- function(end_year) {

  # Validate year - data available from 2018 onwards
  if (end_year < 2018 || end_year > 2026) {
    stop("end_year must be between 2018 and 2026")
  }

  message(paste("Downloading ADE enrollment data for", end_year, "..."))

  # Download the Excel file
  excel_path <- download_enrollment_file(end_year)

  if (is.null(excel_path)) {
    stop(paste("Failed to download enrollment data for year", end_year))
  }

  # Read and parse the Excel file based on format era
  if (end_year <= 2017) {
    result <- parse_era1_excel(excel_path, end_year)
  } else {
    result <- parse_era2_excel(excel_path, end_year)
  }

  # Clean up temp file
  unlink(excel_path)

  result
}


#' Download enrollment Excel file from ADE
#'
#' Tries multiple URL patterns to find the enrollment file.
#' ADE uses inconsistent naming conventions across years.
#'
#' @param end_year School year end
#' @return Path to downloaded temp file, or NULL if download failed
#' @keywords internal
download_enrollment_file <- function(end_year) {

  # First, try to use bundled file if available (fallback for Cloudflare blocking)
  bundled_file <- system.file("extdata", "enrollment",
                              paste0("Oct1Enrollment", end_year, "_publish.xlsx"),
                              package = "azschooldata")
  if (bundled_file != "" && file.exists(bundled_file)) {
    message(paste("  Using bundled file:", basename(bundled_file)))
    return(bundled_file)
  }

  # Build potential URLs based on observed patterns
  urls <- build_enrollment_urls(end_year)

  # Try each URL until one works
  tname <- tempfile(
    pattern = paste0("ade_enr_", end_year, "_"),
    tmpdir = tempdir(),
    fileext = ".xlsx"
  )

  for (url in urls) {
    message(paste("  Trying:", url))

    tryCatch({
      response <- httr::GET(
        url,
        httr::write_disk(tname, overwrite = TRUE),
        httr::timeout(120),
        httr::user_agent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"),
        httr::add_headers(
          "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
          "Accept-Language" = "en-US,en;q=0.9",
          "Referer" = "https://www.azed.gov/"
        )
      )

      # Check for successful download
      if (!httr::http_error(response)) {
        # Verify it's actually an Excel file (check file size and magic bytes)
        file_info <- file.info(tname)
        if (file_info$size > 1000) {
          # Check if it's a valid Excel file by trying to read sheet names
          sheets <- tryCatch(
            readxl::excel_sheets(tname),
            error = function(e) NULL
          )

          if (!is.null(sheets) && length(sheets) > 0) {
            message(paste("  Downloaded successfully:", basename(url)))
            message(paste("  Sheets found:", paste(sheets, collapse = ", ")))
            return(tname)
          }
        }
      }
    }, error = function(e) {
      # Continue to next URL
    })
  }

  # If all URLs failed, return NULL
  message("  All download attempts failed")
  NULL
}


#' Build potential enrollment file URLs
#'
#' ADE uses various URL patterns across years. This function generates
#' a list of URLs to try based on observed patterns.
#'
#' URL patterns discovered through research:
#' - FY24 (2024): /2023/11/Oct1Enrollment2024_publish.xlsx
#' - FY19 (2019): /2019/10/Fiscal Year 2019 Accountabilty October Enrollment REDACTED.xlsx
#' - FY19 (2019): /2021/05/October 1 Enrollment 2018 -2019 UPDATED 2021 V2.xlsx
#' - FY18 (2018): /2021/05/2017-2018 October 1 Public Enrollment File UPDATED 2021 V2.xlsx
#' - FY16 (2016): /2017/06/october-1-fy16-enrollment.xlsx
#' - FY13 (2013): /2017/06/october-1-2012-2013.enrollment_count.xlsx
#'
#' @param end_year School year end
#' @return Character vector of URLs to try
#' @keywords internal
build_enrollment_urls <- function(end_year) {

  # Fiscal year notation (FY24 for 2023-24 school year)
  fy <- paste0("FY", substr(as.character(end_year), 3, 4))
  fy_lower <- tolower(fy)

  # School year notation (2023-2024)
  sy <- paste0(end_year - 1, "-", end_year)
  sy_short <- paste0(end_year - 1, "-", substr(as.character(end_year), 3, 4))

  # Base URL for ADE files
  base <- "https://www.azed.gov/sites/default/files"

  # Generate URLs based on observed patterns - ordered by likelihood of success
  urls <- c(
    # ===========================================================================
    # Pattern 1a: Recent years (FY25+) - Oct1EnrollmentFY{YEAR}.xlsx
    # Example: /2025/04/Oct1EnrollmentFY2025.xlsx
    # ===========================================================================
    paste0(base, "/", end_year, "/04/Oct1EnrollmentFY", end_year, ".xlsx"),
    paste0(base, "/", end_year, "/01/Oct1EnrollmentFY", end_year, ".xlsx"),
    paste0(base, "/", end_year, "/11/Oct1EnrollmentFY", end_year, ".xlsx"),

    # ===========================================================================
    # Pattern 1b: Recent years (FY24) - Oct1Enrollment{YEAR}_publish.xlsx
    # Example: /2023/11/Oct1Enrollment2024_publish.xlsx
    # ===========================================================================
    paste0(base, "/", end_year - 1, "/11/Oct1Enrollment", end_year, "_publish.xlsx"),
    paste0(base, "/", end_year, "/01/Oct1Enrollment", end_year, "_publish.xlsx"),
    paste0(base, "/", end_year, "/11/Oct1Enrollment", end_year, "_publish.xlsx"),

    # ===========================================================================
    # Pattern 2: FY format with year folder (FY19-FY23)
    # Example: /2024/01/FY24 Oct 1 Enrollment Redacted.xlsx
    # ===========================================================================
    paste0(base, "/", end_year, "/", fy, "%20Oct%201%20Enrollment%20Redacted.xlsx"),
    paste0(base, "/", end_year, "/01/", fy, "%20Oct%201%20Enrollment%20Redacted.xlsx"),
    paste0(base, "/", end_year + 1, "/01/", fy, "%20Oct%201%20Enrollment%20Redacted.xlsx"),
    paste0(base, "/", end_year + 1, "/05/", fy, "%20Oct%201%20Enrollment%20Redacted%20Formatted%20UPDATED.xlsx"),

    # ===========================================================================
    # Pattern 3: Fiscal Year spelled out (FY19)
    # Example: /2019/10/Fiscal Year 2019 Accountabilty October Enrollment REDACTED.xlsx
    # Note: "Accountabilty" is a typo in the original ADE filename
    # ===========================================================================
    paste0(base, "/", end_year, "/10/Fiscal%20Year%20", end_year, "%20Accountabilty%20October%20Enrollment%20REDACTED.xlsx"),
    paste0(base, "/", end_year, "/10/Fiscal%20Year%20", end_year, "%20Accountability%20October%20Enrollment%20REDACTED.xlsx"),

    # ===========================================================================
    # Pattern 4: Updated versions in 2021 folder (FY18-FY19)
    # Example: /2021/05/October 1 Enrollment 2018 -2019 UPDATED 2021 V2.xlsx
    # Example: /2021/05/2017-2018 October 1 Public Enrollment File UPDATED 2021 V2.xlsx
    # ===========================================================================
    paste0(base, "/2021/05/October%201%20Enrollment%20", end_year - 1, "%20-", end_year, "%20UPDATED%202021%20V2.xlsx"),
    paste0(base, "/2021/05/", end_year - 1, "-", end_year, "%20October%201%20Public%20Enrollment%20File%20UPDATED%202021%20V2.xlsx"),

    # ===========================================================================
    # Pattern 5: FY format lowercase (FY16-FY17)
    # Example: /2017/06/october-1-fy16-enrollment.xlsx
    # ===========================================================================
    paste0(base, "/2017/06/october-1-", fy_lower, "-enrollment.xlsx"),
    paste0(base, "/2018/06/october-1-", fy_lower, "-enrollment.xlsx"),

    # ===========================================================================
    # Pattern 6: School year format with underscore/hyphen (FY11-FY17)
    # Example: /2017/06/october-1-2012-2013.enrollment_count.xlsx
    # ===========================================================================
    paste0(base, "/2017/06/october-1-", end_year - 1, "-", end_year, ".enrollment_count.xlsx"),
    paste0(base, "/2017/06/october_1_", end_year - 1, "_", end_year, "_enrollment_count.xlsx"),
    paste0(base, "/2017/06/october-1-", end_year - 1, "-", end_year, "_enrollment_count.xlsx"),

    # ===========================================================================
    # Pattern 7: Alternative dash patterns
    # ===========================================================================
    paste0(base, "/", end_year, "/", fy, "-Oct-1-Enrollment-Redacted.xlsx"),
    paste0(base, "/", end_year, "/", fy, "_Oct_1_Enrollment.xlsx"),
    paste0(base, "/", end_year, "/October-1-Enrollment-", fy, ".xlsx"),
    paste0(base, "/", end_year, "/10/", fy, "-October-1-Enrollment.xlsx"),

    # ===========================================================================
    # Pattern 8: Year folder variations
    # ===========================================================================
    paste0(base, "/", end_year - 1, "/10/", fy, "%20Oct%201%20Enrollment%20Redacted.xlsx"),
    paste0(base, "/", end_year - 1, "/11/", fy, "%20Oct%201%20Enrollment%20Redacted.xlsx")
  )

  urls
}


#' Parse Era 1 Excel file (2011-2017)
#'
#' Older ADE enrollment files have multiple tabs for different levels.
#'
#' @param excel_path Path to downloaded Excel file
#' @param end_year School year end
#' @return List with school and district data frames
#' @keywords internal
parse_era1_excel <- function(excel_path, end_year) {

  sheets <- readxl::excel_sheets(excel_path)
  message(paste("  Available sheets:", paste(sheets, collapse = ", ")))

  # Find school-level sheet
  school_sheet <- grep("school|campus|site", sheets, ignore.case = TRUE, value = TRUE)
  if (length(school_sheet) == 0) {
    school_sheet <- sheets[1]  # Default to first sheet
  } else {
    school_sheet <- school_sheet[1]
  }

  # Find LEA/district-level sheet
  lea_sheet <- grep("lea|district|charter|entity", sheets, ignore.case = TRUE, value = TRUE)
  if (length(lea_sheet) == 0) {
    # Try to find a sheet that isn't the school sheet
    lea_sheet <- sheets[sheets != school_sheet]
    if (length(lea_sheet) > 0) {
      lea_sheet <- lea_sheet[1]
    } else {
      lea_sheet <- school_sheet  # Fallback
    }
  } else {
    lea_sheet <- lea_sheet[1]
  }

  message(paste("  Reading school data from sheet:", school_sheet))
  school_data <- readxl::read_excel(
    excel_path,
    sheet = school_sheet,
    col_types = "text",
    .name_repair = "minimal"
  )

  message(paste("  Reading LEA data from sheet:", lea_sheet))
  lea_data <- readxl::read_excel(
    excel_path,
    sheet = lea_sheet,
    col_types = "text",
    .name_repair = "minimal"
  )

  # Add end_year
  school_data$end_year <- end_year
  lea_data$end_year <- end_year

  list(
    school = school_data,
    district = lea_data
  )
}


#' Parse Era 2 Excel file (2018-present)
#'
#' Newer ADE enrollment files have multiple sheets that must be merged:
#' - School by Grade (grade-level enrollment)
#' - School By Gender (male/female breakdown)
#' - School by Ethnicity (race/ethnicity breakdown)
#' - School by Subgroup (special populations: EL, SPED, FRL)
#' - LEA by Grade (district grade enrollment)
#' - LEA by Gender (district gender breakdown)
#' - LEA by Ethnicity (district race/ethnicity)
#'
#' @param excel_path Path to downloaded Excel file
#' @param end_year School year end
#' @return List with school and district data frames
#' @keywords internal
parse_era2_excel <- function(excel_path, end_year) {

  sheets <- readxl::excel_sheets(excel_path)
  message(paste("  Available sheets:", paste(sheets, collapse = ", ")))

  # Read and merge school-level data from multiple sheets
  school_data <- read_and_merge_sheets(
    excel_path,
    sheets,
    level = "school"
  )

  # Read and merge LEA/district-level data from multiple sheets
  district_data <- read_and_merge_sheets(
    excel_path,
    sheets,
    level = "lea"
  )

  # Add end_year
  school_data$end_year <- end_year
  district_data$end_year <- end_year

  list(
    school = school_data,
    district = district_data
  )
}


#' Read and merge enrollment sheets
#'
#' Reads data from Grade, Gender, Ethnicity, and Subgroup sheets
#' and merges them into a single wide-format dataframe.
#'
#' @param excel_path Path to Excel file
#' @param sheets Vector of sheet names
#' @param level Either "school" or "lea"
#' @return Merged data frame
#' @keywords internal
read_and_merge_sheets <- function(excel_path, sheets, level) {

  # Find relevant sheets for this level
  if (level == "school") {
    grade_sheet <- "School by Grade"
    gender_sheet <- "School By Gender"
    ethnicity_sheet <- "School by Ethnicity"
    subgroup_sheet <- "School by Subgroup"
    entity_col <- "School Entity ID"
  } else {
    grade_sheet <- "LEA by Grade"
    gender_sheet <- "LEA by Gender"
    ethnicity_sheet <- "LEA by Ethnicity"
    subgroup_sheet <- NULL  # LEA by Subgroup doesn't exist in all years
    entity_col <- "LEA Entity ID"
  }

  # Read Grade sheet (base data with entity IDs and names)
  if (grade_sheet %in% sheets) {
    message(paste("  Reading", level, "data from sheet:", grade_sheet))
    base_data <- readxl::read_excel(
      excel_path,
      sheet = grade_sheet,
      col_types = "text",
      .name_repair = "minimal"
    )
  } else {
    stop(paste("Required sheet not found:", grade_sheet))
  }

  # Read and merge Gender sheet
  if (gender_sheet %in% sheets) {
    message(paste("  Merging gender data from:", gender_sheet))
    gender_data <- readxl::read_excel(
      excel_path,
      sheet = gender_sheet,
      col_types = "text",
      .name_repair = "minimal"
    )
    base_data <- merge_safely(base_data, gender_data, entity_col)
  }

  # Read and merge Ethnicity sheet
  if (ethnicity_sheet %in% sheets) {
    message(paste("  Merging ethnicity data from:", ethnicity_sheet))
    ethnicity_data <- readxl::read_excel(
      excel_path,
      sheet = ethnicity_sheet,
      col_types = "text",
      .name_repair = "minimal"
    )
    base_data <- merge_safely(base_data, ethnicity_data, entity_col)
  }

  # Read and merge Subgroup sheet (school level only)
  if (!is.null(subgroup_sheet) && subgroup_sheet %in% sheets) {
    message(paste("  Merging subgroup data from:", subgroup_sheet))
    subgroup_data <- readxl::read_excel(
      excel_path,
      sheet = subgroup_sheet,
      col_types = "text",
      .name_repair = "minimal"
    )
    base_data <- merge_subgroup_data(base_data, subgroup_data, entity_col)
  }

  base_data
}


#' Safely merge two dataframes on entity ID
#'
#' @param base Base dataframe
#' @param new_data New dataframe to merge
#' @param entity_col Name of entity ID column
#' @return Merged dataframe
#' @keywords internal
merge_safely <- function(base, new_data, entity_col) {

  # Check if entity column exists in both dataframes
  if (!entity_col %in% names(base) || !entity_col %in% names(new_data)) {
    warning(paste("Entity column", entity_col, "not found in both dataframes, skipping merge"))
    return(base)
  }

  # Remove Fiscal Year column from new_data if it exists (it's redundant and causes merge issues)
  fy_col <- "Fiscal Year"
  if (fy_col %in% names(new_data)) {
    new_data <- new_data[, !(names(new_data) %in% fy_col), drop = FALSE]
  }
  if (fy_col %in% names(base)) {
    base <- base[, !(names(base) %in% fy_col), drop = FALSE]
  }

  # Merge, keeping all columns from both dataframes
  # Use all = TRUE to keep all rows from both dataframes
  result <- merge(
    base,
    new_data,
    by = entity_col,
    all = TRUE,
    suffixes = c("", ".drop")
  )

  # Drop duplicate columns (from merge)
  dup_cols <- grep("\\.drop$", names(result), value = TRUE)
  if (length(dup_cols) > 0) {
    result <- result[, !(names(result) %in% dup_cols)]
  }

  result
}


#' Merge subgroup data (special populations)
#'
#' The Subgroup sheet has multiple rows per entity (one per subgroup type).
#' We need to pivot it wider to get columns for EL, SPED, and FRL.
#'
#' @param base Base dataframe
#' @param subgroup_data Subgroup dataframe
#' @param entity_col Name of entity ID column
#' @return Merged dataframe with special population columns
#' @keywords internal
merge_subgroup_data <- function(base, subgroup_data, entity_col) {

  # Filter to the subgroup types we need
  # "English Language Learner" -> lep
  # "Students with Disabilities" -> special_ed
  # "Income Eligibility 1 or 2" -> econ_disadv
  needed_subgroups <- c(
    "English Language Learner",
    "Students with Disabilities",
    "Income Eligibility 1 or 2"
  )

  # Check if Subgroup column exists
  if (!"Subgroup" %in% names(subgroup_data)) {
    return(base)
  }

  filtered <- subgroup_data[subgroup_data$Subgroup %in% needed_subgroups, ]

  # Pivot to get columns for each subgroup
  if (nrow(filtered) > 0 && "Total" %in% names(filtered)) {
    # Convert Total column to numeric (handles "*" and other non-numeric values)
    filtered$n_students <- safe_numeric(filtered$Total)

    # Create mapping from subgroup name to standard column name
    subgroup_map <- c(
      "English Language Learner" = "lep",
      "Students with Disabilities" = "special_ed",
      "Income Eligibility 1 or 2" = "econ_disadv"
    )

    # Filter to only rows with matching subgroups
    filtered <- filtered[filtered$Subgroup %in% names(subgroup_map), ]
    filtered$standard_col <- subgroup_map[filtered$Subgroup]

    # Remove Fiscal Year column if present (causes issues with merge)
    if ("Fiscal Year" %in% names(filtered)) {
      filtered <- filtered[, !(names(filtered) %in% "Fiscal Year"), drop = FALSE]
    }

    # Pivot wider using base R reshape (more reliable than tidyr for this case)
    special_pops <- stats::reshape(
      filtered[, c(entity_col, "standard_col", "n_students")],
      idvar = entity_col,
      timevar = "standard_col",
      direction = "wide"
    )

    # Clean up column names after reshape (they get suffix like .n_students)
    names(special_pops) <- gsub("\\.n_students$", "", names(special_pops))

    # Merge back to base
    merge_safely(base, special_pops, entity_col)
  } else {
    base
  }
}


#' Get column mapping for ADE enrollment data
#'
#' Returns mappings from ADE column names to standardized names.
#' ADE uses various column naming conventions across years.
#'
#' @return Named list of column mappings
#' @keywords internal
get_ade_column_map <- function() {
  list(
    # ID columns (various naming conventions)
    entity_id = c("EntityID", "Entity ID", "CTDS", "CTDSNumber", "CTDS Number",
                  "EntityId", "LEA Entity ID", "School Entity ID"),
    entity_name = c("EntityName", "Entity Name", "Name", "LEA Name", "School Name",
                    "District Name", "Charter Name"),
    county = c("County", "CountyName", "County Name"),

    # Total enrollment
    total = c("Total", "TotalEnrollment", "Total Enrollment", "Total Count",
              "Enrollment", "All Students"),

    # Demographics - Ethnicity (exact names from ADE Excel files)
    white = c("White", "Caucasian", "White (Not Hispanic)"),
    black = c("Black", "African American", "Black or African American",
              "African American (Not Hispanic)", "Black/African American"),
    hispanic = c("Hispanic", "Hispanic/Latino", "Hispanic or Latino"),
    asian = c("Asian", "Asian (Not Hispanic)"),
    native_american = c("American Indian", "Native American",
                        "American Indian/Alaska Native", "American Indian or Alaska Native",
                        "American Indian/Alaskan Native"),
    pacific_islander = c("Pacific Islander", "Native Hawaiian/Pacific Islander",
                         "Native Hawaiian or Other Pacific Islander",
                         "Native Hawaiian/Pacific Islander"),
    multiracial = c("Two or More", "Two or More Races", "Multiracial", "Multi-Racial",
                    "Multiple Races"),

    # Demographics - Gender
    male = c("Male", "Males", "M"),
    female = c("Female", "Females", "F"),

    # Special populations
    econ_disadv = c("FRL", "Free/Reduced Lunch", "Income Eligibility",
                    "Economically Disadvantaged", "Low Income", "Free Reduced Lunch",
                    "Income Eligibility 1", "Income Eligibility 2", "Income Eligibility 1 or 2"),
    lep = c("EL", "ELL", "LEP", "English Learner", "English Learners",
            "Limited English Proficient", "English Language Learner"),
    special_ed = c("SPED", "Special Ed", "Special Education",
                   "Students with Disabilities", "SWD", "IEP"),

    # Grade levels
    grade_pk = c("PK", "Pre-K", "PreK", "Preschool", "Pre-Kindergarten", "PS"),
    grade_k = c("K", "KG", "Kindergarten"),
    grade_01 = c("1", "01", "Grade 1", "Grade 01", "1st"),
    grade_02 = c("2", "02", "Grade 2", "Grade 02", "2nd"),
    grade_03 = c("3", "03", "Grade 3", "Grade 03", "3rd"),
    grade_04 = c("4", "04", "Grade 4", "Grade 04", "4th"),
    grade_05 = c("5", "05", "Grade 5", "Grade 05", "5th"),
    grade_06 = c("6", "06", "Grade 6", "Grade 06", "6th"),
    grade_07 = c("7", "07", "Grade 7", "Grade 07", "7th"),
    grade_08 = c("8", "08", "Grade 8", "Grade 08", "8th"),
    grade_09 = c("9", "09", "Grade 9", "Grade 09", "9th"),
    grade_10 = c("10", "Grade 10", "10th"),
    grade_11 = c("11", "Grade 11", "11th"),
    grade_12 = c("12", "Grade 12", "12th")
  )
}
