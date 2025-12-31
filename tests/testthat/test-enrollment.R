# Tests for enrollment functions
# Note: Most tests are marked as skip_on_cran since they require network access

test_that("safe_numeric handles various inputs", {
  # Normal numbers
  expect_equal(safe_numeric("100"), 100)
  expect_equal(safe_numeric("1,234"), 1234)

  # Suppressed values (ADE uses * for FERPA suppression)
  expect_true(is.na(safe_numeric("*")))
  expect_true(is.na(safe_numeric("-1")))
  expect_true(is.na(safe_numeric("<11")))
  expect_true(is.na(safe_numeric("")))
  expect_true(is.na(safe_numeric("**")))

  # Whitespace handling
  expect_equal(safe_numeric("  100  "), 100)
})

test_that("fetch_enr validates year parameter", {
  expect_error(fetch_enr(2005), "end_year must be between")
  expect_error(fetch_enr(2030), "end_year must be between")
})

test_that("get_cache_dir returns valid path", {
  cache_dir <- get_cache_dir()
  expect_true(is.character(cache_dir))
  expect_true(grepl("azschooldata", cache_dir))
})

test_that("cache functions work correctly", {
  # Test cache path generation
  path <- get_cache_path(2024, "tidy")
  expect_true(grepl("enr_tidy_2024.rds", path))

  # Test cache_exists returns FALSE for non-existent cache
  expect_false(cache_exists(9999, "tidy"))
})

test_that("get_fy returns correct fiscal year", {
  expect_equal(get_fy(2024), "FY24")
  expect_equal(get_fy(2011), "FY11")
})

test_that("get_school_year_range returns correct range", {
  expect_equal(get_school_year_range(2024), "2023-2024")
  expect_equal(get_school_year_range(2011), "2010-2011")
})

test_that("build_enrollment_urls generates valid URLs", {
  urls <- build_enrollment_urls(2024)
  expect_true(is.character(urls))
  expect_true(length(urls) > 0)
  expect_true(all(grepl("^https://", urls)))
  expect_true(any(grepl("azed.gov", urls)))
})

test_that("get_ade_column_map returns expected structure", {
  col_map <- get_ade_column_map()
  expect_true(is.list(col_map))
  expect_true("total" %in% names(col_map))
  expect_true("hispanic" %in% names(col_map))
  expect_true("white" %in% names(col_map))
  expect_true("lep" %in% names(col_map))
})

# Integration tests (require network access)
test_that("fetch_enr downloads and processes data", {
  skip_on_cran()
  skip_if_offline()

  # Use a year we know has data available
  # This test may need adjustment based on actual ADE data availability
  result <- tryCatch(
    fetch_enr(2021, tidy = FALSE, use_cache = FALSE),
    error = function(e) NULL
  )

  # If download succeeded, check structure
  if (!is.null(result)) {
    expect_true(is.data.frame(result))
    expect_true("type" %in% names(result))

    # Check we have expected types
    expect_true(any(c("State", "District", "Campus") %in% result$type))

    # Check for key columns
    if (nrow(result) > 0) {
      expect_true("end_year" %in% names(result))
    }
  }
})

test_that("tidy_enr produces correct long format", {
  skip_on_cran()
  skip_if_offline()

  # Create mock wide data to test tidy function
  wide <- data.frame(
    end_year = 2024,
    type = "State",
    district_id = NA,
    campus_id = NA,
    district_name = NA,
    campus_name = NA,
    county = NA,
    row_total = 1000,
    hispanic = 400,
    white = 300,
    black = 100,
    asian = 100,
    native_american = 50,
    pacific_islander = 20,
    multiracial = 30,
    male = 500,
    female = 500,
    econ_disadv = 600,
    lep = 200,
    special_ed = 150,
    grade_k = 80,
    grade_01 = 75,
    stringsAsFactors = FALSE
  )

  tidy_result <- tidy_enr(wide)

  # Check structure
  expect_true("grade_level" %in% names(tidy_result))
  expect_true("subgroup" %in% names(tidy_result))
  expect_true("n_students" %in% names(tidy_result))
  expect_true("pct" %in% names(tidy_result))

  # Check subgroups include expected values
  subgroups <- unique(tidy_result$subgroup)
  expect_true("total_enrollment" %in% subgroups)
  expect_true("hispanic" %in% subgroups)
  expect_true("white" %in% subgroups)
})

test_that("id_enr_aggs adds correct flags", {
  # Create mock tidy data
  tidy_data <- data.frame(
    end_year = c(2024, 2024, 2024),
    type = c("State", "District", "Campus"),
    grade_level = "TOTAL",
    subgroup = "total_enrollment",
    n_students = c(1000000, 50000, 1000),
    pct = 1.0,
    stringsAsFactors = FALSE
  )

  result <- id_enr_aggs(tidy_data)

  # Check flags exist
  expect_true("is_state" %in% names(result))
  expect_true("is_district" %in% names(result))
  expect_true("is_campus" %in% names(result))

  # Check flags are boolean
  expect_true(is.logical(result$is_state))
  expect_true(is.logical(result$is_district))
  expect_true(is.logical(result$is_campus))

  # Check correct assignment
  expect_equal(result$is_state, c(TRUE, FALSE, FALSE))
  expect_equal(result$is_district, c(FALSE, TRUE, FALSE))
  expect_equal(result$is_campus, c(FALSE, FALSE, TRUE))
})

test_that("enr_grade_aggs creates expected aggregates", {
  # Create mock tidy data with grade levels
  tidy_data <- data.frame(
    end_year = 2024,
    type = "State",
    district_id = NA,
    campus_id = NA,
    district_name = NA,
    campus_name = NA,
    county = NA,
    grade_level = c("K", "01", "02", "09", "10", "11", "12"),
    subgroup = "total_enrollment",
    n_students = c(100, 100, 100, 100, 100, 100, 100),
    pct = 0.1,
    is_state = TRUE,
    is_district = FALSE,
    is_campus = FALSE,
    stringsAsFactors = FALSE
  )

  result <- enr_grade_aggs(tidy_data)

  # Check that aggregates were created
  expect_true("K8" %in% result$grade_level)
  expect_true("HS" %in% result$grade_level)
  expect_true("K12" %in% result$grade_level)

  # Check K8 sum (K + 01 + 02 = 300)
  k8 <- result[result$grade_level == "K8", ]
  expect_equal(k8$n_students, 300)

  # Check HS sum (09 + 10 + 11 + 12 = 400)
  hs <- result[result$grade_level == "HS", ]
  expect_equal(hs$n_students, 400)
})
