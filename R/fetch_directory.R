# ==============================================================================
# School Directory Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading school directory data from the
# Arizona Department of Education (ADE) Report Cards API.
#
# Data source: https://azreportcards.azed.gov
#
# API endpoints used:
# - /api/Entity/GetEntityList?fiscalYear=YYYY - list of schools/districts
# - /api/Entity/GetContactDetails?entityId=ID - contact info (name, phone, web)
#
# Note: Physical addresses are not available through this API. The directory
# includes school names, districts, grades served, school types, administrator
# names, phone numbers, and websites.
#
# ==============================================================================

#' Fetch Arizona school directory data
#'
#' Downloads and processes school directory data from the Arizona Department of
#' Education Report Cards. Includes schools and districts with contact information.
#'
#' @param end_year Fiscal year end (default: current year). Data is returned for
#'   schools/districts active in that fiscal year.
#' @param tidy If TRUE (default), returns data in a standardized format with
#'   consistent column names. If FALSE, returns raw column names from the API.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#'   Set to FALSE to force re-download from ADE.
#' @param include_contact If TRUE (default), fetches contact details (admin name,
#'   phone, website) for each entity. Set to FALSE for faster download of basic
#'   info only.
#' @return A tibble with school directory data. Columns include:
#'   \itemize{
#'     \item \code{state_school_id}: ADE education organization ID (for schools)
#'     \item \code{state_district_id}: ADE education organization ID (for districts/LEAs)
#'     \item \code{school_name}: School name
#'     \item \code{district_name}: District/LEA name
#'     \item \code{school_type}: Type (e.g., "District School", "Charter School")
#'     \item \code{entity_type}: Entity level ("School" or "LEA")
#'     \item \code{grades_served}: Grade range (e.g., "Kindergarten - Grade 12")
#'     \item \code{is_title1}: Title I status
#'     \item \code{phone}: Phone number (if include_contact = TRUE)
#'     \item \code{website}: School/district website (if include_contact = TRUE)
#'     \item \code{principal_name}: Administrator name (if include_contact = TRUE)
#'   }
#' @details
#' The directory data is retrieved from the ADE Report Cards API. This data
#' represents schools and districts for the specified fiscal year and is updated
#' annually by ADE.
#'
#' Note: Physical addresses (street, city, zip) are not available through this API.
#' If you need address data, consider using other state data sources.
#'
#' @export
#' @examples
#' \dontrun{
#' # Get school directory data for current year
#' dir_data <- fetch_directory()
#'
#' # Get raw format (original API column names)
#' dir_raw <- fetch_directory(tidy = FALSE)
#'
#' # Fast download without contact details
#' dir_basic <- fetch_directory(include_contact = FALSE)
#'
#' # Force fresh download (ignore cache)
#' dir_fresh <- fetch_directory(use_cache = FALSE)
#'
#' # Filter to schools only
#' library(dplyr)
#' schools_only <- dir_data |>
#'   filter(entity_type == "School")
#'
#' # Find all schools in a district
#' mesa_schools <- dir_data |>
#'   filter(grepl("Mesa", district_name, ignore.case = TRUE),
#'          entity_type == "School")
#' }
fetch_directory <- function(end_year = NULL, tidy = TRUE, use_cache = TRUE,
                            include_contact = TRUE) {

  # Default to current fiscal year if not specified
  if (is.null(end_year)) {
    # Arizona fiscal year ends in June
    current_month <- as.numeric(format(Sys.Date(), "%m"))
    current_year <- as.numeric(format(Sys.Date(), "%Y"))
    end_year <- if (current_month >= 7) current_year + 1 else current_year
  }

  # Validate year
  if (end_year < 2018 || end_year > 2030) {
    stop("end_year must be between 2018 and 2030")
  }

  # Determine cache type based on parameters
  cache_type <- paste0("directory_", end_year,
                       if (tidy) "_tidy" else "_raw",
                       if (include_contact) "_full" else "_basic")

  # Check cache first
  if (use_cache && cache_exists_directory(cache_type)) {
    message("Using cached school directory data")
    return(read_cache_directory(cache_type))
  }

  # Get raw data from API
  raw <- get_raw_directory(end_year, include_contact)

  # Process to standard schema
  if (tidy) {
    result <- process_directory(raw)
  } else {
    result <- raw
  }

  # Cache the result
  if (use_cache) {
    write_cache_directory(result, cache_type)
  }

  result
}


#' Get raw school directory data from ADE Report Cards API
#'
#' Downloads the raw school directory data from the Arizona Department of
#' Education Report Cards API.
#'
#' @param end_year Fiscal year end
#' @param include_contact Whether to fetch contact details
#' @return Raw data frame from API
#' @keywords internal
get_raw_directory <- function(end_year, include_contact = TRUE) {

  message(paste("Downloading school directory data for FY", end_year, "..."))

  # Get entity list
  entity_url <- paste0(
    "https://azreportcards.azed.gov/api/Entity/GetEntityList?fiscalYear=",
    end_year
  )

  message("  Fetching entity list...")

  response <- httr::GET(
    entity_url,
    httr::timeout(120),
    httr::user_agent("Mozilla/5.0 (compatible; azschooldata R package)")
  )

  if (httr::http_error(response)) {
    stop(paste("Failed to fetch entity list from ADE Report Cards API:",
               httr::status_code(response)))
  }

  entity_data <- httr::content(response, as = "parsed", simplifyVector = TRUE)

  if (length(entity_data) == 0) {
    stop("No entities returned from API")
  }

  message(paste("  Found", nrow(entity_data), "entities"))

  # Convert to tibble
  result <- dplyr::as_tibble(entity_data)

  # Fetch contact details if requested

  if (include_contact) {
    result <- fetch_contact_details(result)
  }

  # Add metadata
  result$end_year <- end_year
  result$retrieved_at <- Sys.time()

  result
}


#' Fetch contact details for entities
#'
#' Retrieves administrator name, phone, and website for each entity.
#'
#' @param entity_data Data frame with entity information
#' @return Data frame with contact details added
#' @keywords internal
fetch_contact_details <- function(entity_data) {

  n_entities <- nrow(entity_data)
  message(paste("  Fetching contact details for", n_entities, "entities..."))

  # Initialize contact columns
  entity_data$admin_first_name <- NA_character_
  entity_data$admin_last_name <- NA_character_
  entity_data$telephone <- NA_character_
  entity_data$website <- NA_character_
  entity_data$mission_statement <- NA_character_

  # Fetch contact details for each entity
  # Use batching to avoid overwhelming the API
  batch_size <- 50
  n_batches <- ceiling(n_entities / batch_size)

  for (batch in seq_len(n_batches)) {
    start_idx <- (batch - 1) * batch_size + 1
    end_idx <- min(batch * batch_size, n_entities)

    if (batch %% 10 == 1 || batch == n_batches) {
      message(paste("    Processing entities", start_idx, "to", end_idx,
                    "of", n_entities))
    }

    for (i in start_idx:end_idx) {
      entity_id <- entity_data$educationOrganizationId[i]

      tryCatch({
        contact_url <- paste0(
          "https://azreportcards.azed.gov/api/Entity/GetContactDetails?entityId=",
          entity_id
        )

        response <- httr::GET(
          contact_url,
          httr::timeout(30),
          httr::user_agent("Mozilla/5.0 (compatible; azschooldata R package)")
        )

        if (!httr::http_error(response)) {
          contact <- httr::content(response, as = "parsed")

          if (!is.null(contact)) {
            entity_data$admin_first_name[i] <- contact$firstName %||% NA_character_
            entity_data$admin_last_name[i] <- trimws(contact$lastName %||% "")
            entity_data$telephone[i] <- contact$telephone %||% NA_character_
            entity_data$website[i] <- contact$webSite %||% NA_character_
            entity_data$mission_statement[i] <- contact$missionStatement %||% NA_character_
          }
        }

        # Small delay to be respectful of the API
        Sys.sleep(0.05)

      }, error = function(e) {
        # Continue on error - contact details are optional
      })
    }
  }

  entity_data
}


# Use rlang::`%||%` for null coalescing (already imported in package)


#' Process raw directory data to standard schema
#'
#' Takes raw directory data from ADE and standardizes column names.
#'
#' @param raw_data Raw data frame from get_raw_directory()
#' @return Processed data frame with standard schema
#' @keywords internal
process_directory <- function(raw_data) {

  result <- dplyr::tibble(
    # IDs
    state_school_id = ifelse(
      raw_data$entityType == "School",
      as.character(raw_data$educationOrganizationId),
      NA_character_
    ),
    state_district_id = ifelse(
      raw_data$entityType == "LEA",
      as.character(raw_data$educationOrganizationId),
      as.character(raw_data$leaEducationOrganizationId)
    ),

    # Names
    school_name = ifelse(
      raw_data$entityType == "School",
      raw_data$nameOfInstitution,
      NA_character_
    ),
    district_name = ifelse(
      raw_data$entityType == "LEA",
      raw_data$nameOfInstitution,
      raw_data$districtName
    ),

    # Classification
    entity_type = raw_data$entityType,
    school_type = raw_data$schoolTypes,
    grades_served = raw_data$gradesOffered,

    # Status
    is_title1 = raw_data$isTitle1,
    is_csi = raw_data$isCSI,
    is_tsi = raw_data$isTSI,
    accountability_grade = raw_data$accountabilityLetterGrade,

    # Metadata
    fiscal_year = raw_data$fiscalYear,
    end_year = raw_data$end_year
  )

  # Add contact details if present
  if ("telephone" %in% names(raw_data)) {
    # Combine admin first and last name
    admin_name <- ifelse(
      is.na(raw_data$admin_first_name) & is.na(raw_data$admin_last_name),
      NA_character_,
      trimws(paste(
        ifelse(is.na(raw_data$admin_first_name), "", raw_data$admin_first_name),
        ifelse(is.na(raw_data$admin_last_name), "", raw_data$admin_last_name)
      ))
    )
    admin_name <- ifelse(admin_name == "", NA_character_, admin_name)

    result$phone <- raw_data$telephone
    result$website <- raw_data$website
    result$principal_name <- admin_name
  }

  # Add state column
  result$state <- "AZ"

  # Reorder columns
  preferred_order <- c(
    "state_school_id", "state_district_id",
    "school_name", "district_name",
    "entity_type", "school_type", "grades_served",
    "is_title1", "is_csi", "is_tsi", "accountability_grade",
    "phone", "website", "principal_name",
    "state", "fiscal_year", "end_year"
  )

  existing_cols <- preferred_order[preferred_order %in% names(result)]
  other_cols <- setdiff(names(result), preferred_order)

  result <- result |>
    dplyr::select(dplyr::all_of(c(existing_cols, other_cols)))

  result
}


# ==============================================================================
# Directory-specific cache functions
# ==============================================================================

#' Build cache file path for directory data
#'
#' @param cache_type Type of cache
#' @return File path string
#' @keywords internal
build_cache_path_directory <- function(cache_type) {
  cache_dir <- get_cache_dir()
  file.path(cache_dir, paste0(cache_type, ".rds"))
}


#' Check if cached directory data exists
#'
#' @param cache_type Type of cache
#' @param max_age Maximum age in days (default 30). Set to Inf to ignore age.
#' @return Logical indicating if valid cache exists
#' @keywords internal
cache_exists_directory <- function(cache_type, max_age = 30) {
  cache_path <- build_cache_path_directory(cache_type)

  if (!file.exists(cache_path)) {
    return(FALSE)
  }

  # Check age
  file_info <- file.info(cache_path)
  age_days <- as.numeric(difftime(Sys.time(), file_info$mtime, units = "days"))

  age_days <= max_age
}


#' Read directory data from cache
#'
#' @param cache_type Type of cache
#' @return Cached data frame
#' @keywords internal
read_cache_directory <- function(cache_type) {
  cache_path <- build_cache_path_directory(cache_type)
  readRDS(cache_path)
}


#' Write directory data to cache
#'
#' @param data Data frame to cache
#' @param cache_type Type of cache
#' @return Invisibly returns the cache path
#' @keywords internal
write_cache_directory <- function(data, cache_type) {
  cache_path <- build_cache_path_directory(cache_type)
  cache_dir <- dirname(cache_path)

  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }

  saveRDS(data, cache_path)
  invisible(cache_path)
}


#' Clear school directory cache
#'
#' Removes cached school directory data files.
#'
#' @return Invisibly returns the number of files removed
#' @export
#' @examples
#' \dontrun{
#' # Clear cached directory data
#' clear_directory_cache()
#' }
clear_directory_cache <- function() {
  cache_dir <- get_cache_dir()

  if (!dir.exists(cache_dir)) {
    message("Cache directory does not exist")
    return(invisible(0))
  }

  files <- list.files(cache_dir, pattern = "^directory_", full.names = TRUE)

  if (length(files) > 0) {
    file.remove(files)
    message(paste("Removed", length(files), "cached directory file(s)"))
  } else {
    message("No cached directory files to remove")
  }

  invisible(length(files))
}
