# Fetch Arizona school directory data

Downloads and processes school directory data from the Arizona
Department of Education Report Cards. Includes schools and districts
with contact information.

## Usage

``` r
fetch_directory(
  end_year = NULL,
  tidy = TRUE,
  use_cache = TRUE,
  include_contact = TRUE
)
```

## Arguments

- end_year:

  Fiscal year end (default: current year). Data is returned for
  schools/districts active in that fiscal year.

- tidy:

  If TRUE (default), returns data in a standardized format with
  consistent column names. If FALSE, returns raw column names from the
  API.

- use_cache:

  If TRUE (default), uses locally cached data when available. Set to
  FALSE to force re-download from ADE.

- include_contact:

  If TRUE (default), fetches contact details (admin name, phone,
  website) for each entity. Set to FALSE for faster download of basic
  info only.

## Value

A tibble with school directory data. Columns include:

- `state_school_id`: ADE education organization ID (for schools)

- `state_district_id`: ADE education organization ID (for
  districts/LEAs)

- `school_name`: School name

- `district_name`: District/LEA name

- `school_type`: Type (e.g., "District School", "Charter School")

- `entity_type`: Entity level ("School" or "LEA")

- `grades_served`: Grade range (e.g., "Kindergarten - Grade 12")

- `is_title1`: Title I status

- `phone`: Phone number (if include_contact = TRUE)

- `website`: School/district website (if include_contact = TRUE)

- `principal_name`: Administrator name (if include_contact = TRUE)

## Details

The directory data is retrieved from the ADE Report Cards API. This data
represents schools and districts for the specified fiscal year and is
updated annually by ADE.

Note: Physical addresses (street, city, zip) are not available through
this API. If you need address data, consider using other state data
sources.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get school directory data for current year
dir_data <- fetch_directory()

# Get raw format (original API column names)
dir_raw <- fetch_directory(tidy = FALSE)

# Fast download without contact details
dir_basic <- fetch_directory(include_contact = FALSE)

# Force fresh download (ignore cache)
dir_fresh <- fetch_directory(use_cache = FALSE)

# Filter to schools only
library(dplyr)
schools_only <- dir_data |>
  filter(entity_type == "School")

# Find all schools in a district
mesa_schools <- dir_data |>
  filter(grepl("Mesa", district_name, ignore.case = TRUE),
         entity_type == "School")
} # }
```
