# Get available years for Arizona enrollment data

Returns the range of school years for which enrollment data is available
from the Arizona Department of Education.

## Usage

``` r
get_available_years()
```

## Value

A list with three elements:

- min_year:

  The earliest available school year end (e.g., 2011 for 2010-11)

- max_year:

  The latest available school year end (e.g., 2026 for 2025-26)

- description:

  Human-readable description of data availability

## Examples

``` r
get_available_years()
#> $min_year
#> [1] 2018
#> 
#> $max_year
#> [1] 2026
#> 
#> $description
#> [1] "Arizona enrollment data is available from 2017-18 (end_year 2018) through 2025-26 (end_year 2026). Data comes from the October 1 enrollment reports published by the Arizona Department of Education. Older data (2011-2017) may be available through manual requests to ADE. Earlier years (1990s-2000s) exist only as PDF reports and are not currently supported."
#> 
# Returns list with min_year, max_year, and description
```
