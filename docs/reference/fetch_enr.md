# Fetch Arizona enrollment data

Downloads and processes enrollment data from the Arizona Department of
Education's October 1 enrollment reports.

## Usage

``` r
fetch_enr(end_year, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_year:

  A school year. Year is the end of the academic year - eg 2023-24
  school year is year '2024'. Valid values are 2018-2026.

  Data availability notes:

  - Excel files are available from FY2018 (end_year 2018) onwards

  - Older data (2011-2017) may be available through manual requests to
    ADE

  - Earlier years (1990s-2000s) exist only as PDF reports and are not
    supported

  - ADE uses varying URL patterns across years; download may take a few
    seconds as the package tries multiple URL patterns

- tidy:

  If TRUE (default), returns data in long (tidy) format with subgroup
  column. If FALSE, returns wide format.

- use_cache:

  If TRUE (default), uses locally cached data when available. Set to
  FALSE to force re-download from ADE.

## Value

Data frame with enrollment data. Wide format includes columns for
district_id, campus_id, names, and enrollment counts by
demographic/grade. Tidy format pivots these counts into subgroup and
grade_level columns.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 enrollment data (2023-24 school year)
enr_2024 <- fetch_enr(2024)

# Get wide format
enr_wide <- fetch_enr(2024, tidy = FALSE)

# Force fresh download (ignore cache)
enr_fresh <- fetch_enr(2024, use_cache = FALSE)

# Get historical data from 2018
enr_2018 <- fetch_enr(2018)

# Filter to specific district
phoenix_union <- enr_2024 |>
  dplyr::filter(grepl("Phoenix Union", district_name, ignore.case = TRUE))
} # }
```
