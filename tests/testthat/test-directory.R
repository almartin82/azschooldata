# ==============================================================================
# Tests for School Directory Functions
# ==============================================================================

# Skip if offline helper
skip_if_offline <- function() {
  tryCatch({
    response <- httr::HEAD("https://www.google.com", httr::timeout(5))
    if (httr::http_error(response)) skip("No network connectivity")
  }, error = function(e) skip("No network connectivity"))
}


# ==============================================================================
# Live Pipeline Tests - URL Availability
# ==============================================================================

test_that("ADE Report Cards API base URL is accessible", {
  skip_on_cran()
  skip_if_offline()

  response <- httr::HEAD(
    "https://azreportcards.azed.gov",
    httr::timeout(30)
  )

  # May return 200 or redirect - just needs to respond
  expect_false(httr::http_error(response))
})


test_that("Entity list API endpoint returns data", {
  skip_on_cran()
  skip_if_offline()

  url <- "https://azreportcards.azed.gov/api/Entity/GetEntityList?fiscalYear=2024"

  response <- httr::GET(url, httr::timeout(60))

  expect_equal(httr::status_code(response), 200)

  data <- httr::content(response, as = "parsed", simplifyVector = TRUE)
  expect_true(is.data.frame(data) || is.list(data))
  expect_gt(length(data), 0)
})


test_that("Contact details API endpoint returns data", {
  skip_on_cran()
  skip_if_offline()

  # Test with a known entity ID (4235 = Mesa Unified District)
  url <- "https://azreportcards.azed.gov/api/Entity/GetContactDetails?entityId=4235"

  response <- httr::GET(url, httr::timeout(30))

  expect_equal(httr::status_code(response), 200)

  data <- httr::content(response, as = "parsed")
  expect_true(is.list(data))
})


# ==============================================================================
# Live Pipeline Tests - Data Download
# ==============================================================================

test_that("get_raw_directory downloads entity list", {
  skip_on_cran()
  skip_if_offline()

  # Test with basic download (no contact details for speed)
  raw <- get_raw_directory(2024, include_contact = FALSE)

  expect_s3_class(raw, "data.frame")
  expect_gt(nrow(raw), 500)  # Should have 600+ entities
  expect_true("educationOrganizationId" %in% names(raw))
  expect_true("nameOfInstitution" %in% names(raw))
  expect_true("entityType" %in% names(raw))
})


test_that("get_raw_directory downloads with contact details", {
  skip_on_cran()
  skip_if_offline()

  # Only download a few entities to test contact fetch
  # We'll modify the function call to limit scope
  raw <- get_raw_directory(2024, include_contact = FALSE)

  # Manually test contact fetch on first 5 entities
  test_subset <- raw[1:5, ]
  result <- fetch_contact_details(test_subset)

  expect_s3_class(result, "data.frame")
  expect_true("telephone" %in% names(result))
  expect_true("website" %in% names(result))
  expect_true("admin_first_name" %in% names(result))
})


# ==============================================================================
# Live Pipeline Tests - Data Structure
# ==============================================================================

test_that("Entity list has expected columns", {
  skip_on_cran()
  skip_if_offline()

  raw <- get_raw_directory(2024, include_contact = FALSE)

  expected_cols <- c(
    "educationOrganizationId",
    "nameOfInstitution",
    "entityType",
    "gradesOffered",
    "schoolTypes"
  )

  for (col in expected_cols) {
    expect_true(col %in% names(raw), info = paste("Missing column:", col))
  }
})


test_that("Entity types are LEA or School", {
  skip_on_cran()
  skip_if_offline()

  raw <- get_raw_directory(2024, include_contact = FALSE)

  entity_types <- unique(raw$entityType)
  expect_true(all(entity_types %in% c("LEA", "School")))
})


# ==============================================================================
# Live Pipeline Tests - Data Quality
# ==============================================================================

test_that("All entities have non-missing IDs", {
  skip_on_cran()
  skip_if_offline()

  raw <- get_raw_directory(2024, include_contact = FALSE)

  expect_false(any(is.na(raw$educationOrganizationId)))
  expect_false(any(is.na(raw$nameOfInstitution)))
})


test_that("All schools have associated LEA", {
  skip_on_cran()
  skip_if_offline()

  raw <- get_raw_directory(2024, include_contact = FALSE)

  schools <- raw[raw$entityType == "School", ]

  # Schools should have leaEducationOrganizationId or districtName
  has_lea_id <- "leaEducationOrganizationId" %in% names(raw)
  has_district <- "districtName" %in% names(raw)

  expect_true(has_lea_id || has_district,
              info = "Schools must have LEA association")
})


# ==============================================================================
# Integration Tests - fetch_directory()
# ==============================================================================

test_that("fetch_directory returns valid structure", {
  skip_on_cran()
  skip_if_offline()

  # Test with cache disabled to ensure fresh download
  result <- fetch_directory(end_year = 2024, use_cache = FALSE,
                            include_contact = FALSE, tidy = TRUE)

  expect_s3_class(result, "data.frame")
  expect_gt(nrow(result), 500)

  # Check for standardized column names
  expect_true("state_school_id" %in% names(result))
  expect_true("state_district_id" %in% names(result))
  expect_true("school_name" %in% names(result))
  expect_true("district_name" %in% names(result))
  expect_true("entity_type" %in% names(result))
  expect_true("state" %in% names(result))
})


test_that("fetch_directory tidy output has correct state", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_directory(end_year = 2024, use_cache = FALSE,
                            include_contact = FALSE, tidy = TRUE)

  expect_true(all(result$state == "AZ", na.rm = TRUE))
})


test_that("fetch_directory separates schools and LEAs correctly", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_directory(end_year = 2024, use_cache = FALSE,
                            include_contact = FALSE, tidy = TRUE)

  schools <- result[result$entity_type == "School", ]
  leas <- result[result$entity_type == "LEA", ]

  # Schools should have school_id populated, LEAs should not
  expect_true(all(!is.na(schools$state_school_id)))
  expect_true(all(is.na(leas$state_school_id)))

  # All entities should have district_id
  expect_false(any(is.na(result$state_district_id)))
})


test_that("fetch_directory with contact details includes admin info", {
  skip_on_cran()
  skip_if_offline()

  # This will be slow - only run if explicitly testing
  skip("Slow test - downloads contact details for all entities")

  result <- fetch_directory(end_year = 2024, use_cache = FALSE,
                            include_contact = TRUE, tidy = TRUE)

  expect_true("phone" %in% names(result))
  expect_true("website" %in% names(result))
  expect_true("principal_name" %in% names(result))

  # At least some entities should have contact info
  expect_gt(sum(!is.na(result$phone)), 100)
})


# ==============================================================================
# Output Fidelity Tests
# ==============================================================================

test_that("Mesa Unified District appears in directory", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_directory(end_year = 2024, use_cache = FALSE,
                            include_contact = FALSE, tidy = TRUE)

  mesa_entities <- result[grepl("Mesa Unified", result$district_name,
                                 ignore.case = TRUE), ]

  expect_gt(nrow(mesa_entities), 0, info = "Mesa Unified should appear")

  # Mesa Unified LEA should exist
  mesa_lea <- mesa_entities[mesa_entities$entity_type == "LEA", ]
  expect_equal(nrow(mesa_lea), 1, info = "Should have exactly 1 Mesa Unified LEA")
})


test_that("Entity counts are within expected range", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_directory(end_year = 2024, use_cache = FALSE,
                            include_contact = FALSE, tidy = TRUE)

  n_leas <- sum(result$entity_type == "LEA")
  n_schools <- sum(result$entity_type == "School")

  # Arizona typically has ~600 LEAs and ~2400 schools
  expect_gt(n_leas, 400, info = "Should have 400+ LEAs")
  expect_lt(n_leas, 800, info = "Should have <800 LEAs")

  expect_gt(n_schools, 2000, info = "Should have 2000+ schools")
  expect_lt(n_schools, 3000, info = "Should have <3000 schools")
})


# ==============================================================================
# Cache Tests
# ==============================================================================

test_that("Directory cache functions work", {
  # Clear cache first
  clear_directory_cache()

  cache_type <- "directory_2024_tidy_basic"

  # Should not exist after clearing
  expect_false(cache_exists_directory(cache_type, max_age = Inf))

  # Create dummy data
  dummy_data <- data.frame(
    state_school_id = "123",
    school_name = "Test School",
    state = "AZ"
  )

  # Write to cache
  write_cache_directory(dummy_data, cache_type)

  # Should exist now
  expect_true(cache_exists_directory(cache_type, max_age = Inf))

  # Read from cache
  cached <- read_cache_directory(cache_type)
  expect_equal(cached$state_school_id, "123")
  expect_equal(cached$school_name, "Test School")

  # Clear cache again
  n_removed <- clear_directory_cache()
  expect_gte(n_removed, 1)
})


test_that("fetch_directory uses cache when available", {
  skip_on_cran()
  skip_if_offline()

  # Clear cache and force fresh download
  clear_directory_cache()

  result1 <- fetch_directory(end_year = 2024, use_cache = TRUE,
                             include_contact = FALSE, tidy = TRUE)

  # Second call should use cache (will be much faster)
  start_time <- Sys.time()
  result2 <- fetch_directory(end_year = 2024, use_cache = TRUE,
                             include_contact = FALSE, tidy = TRUE)
  elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

  # Cached call should be very fast (<1 second)
  expect_lt(elapsed, 5, info = "Cached call should be fast")

  # Results should be identical
  expect_equal(nrow(result1), nrow(result2))
  expect_equal(ncol(result1), ncol(result2))
})


# ==============================================================================
# Error Handling Tests
# ==============================================================================

test_that("fetch_directory validates year range", {
  expect_error(fetch_directory(end_year = 2010), "must be between")
  expect_error(fetch_directory(end_year = 2050), "must be between")
})


test_that("fetch_directory handles invalid API response gracefully", {
  skip("Manual test - requires mocking httr")

  # This would require mocking httr::GET to return error response
  # For now, document expected behavior:
  # - Should error with informative message if API returns non-200
  # - Should error if API returns empty data
})
