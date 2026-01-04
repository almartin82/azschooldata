# azschooldata: Fetch and Process Arizona School Data

Downloads and processes school enrollment data from the Arizona
Department of Education (ADE). Provides functions for fetching October 1
enrollment data from the Accountability & Research division and
transforming it into tidy format for analysis.

## Main functions

- [`fetch_enr`](https://almartin82.github.io/azschooldata/reference/fetch_enr.md):

  Fetch enrollment data for a school year

- [`fetch_enr_multi`](https://almartin82.github.io/azschooldata/reference/fetch_enr_multi.md):

  Fetch enrollment data for multiple years

- [`tidy_enr`](https://almartin82.github.io/azschooldata/reference/tidy_enr.md):

  Transform wide data to tidy (long) format

- [`id_enr_aggs`](https://almartin82.github.io/azschooldata/reference/id_enr_aggs.md):

  Add aggregation level flags

- [`enr_grade_aggs`](https://almartin82.github.io/azschooldata/reference/enr_grade_aggs.md):

  Create grade-level aggregations

## Cache functions

- [`cache_status`](https://almartin82.github.io/azschooldata/reference/cache_status.md):

  View cached data files

- [`clear_cache`](https://almartin82.github.io/azschooldata/reference/clear_cache.md):

  Remove cached data files

## ID System

Arizona uses the following ID system:

- Entity IDs (CTDSNumber): Variable length numeric IDs for LEAs and
  schools

- Entity names identify whether it's a district, charter, or school

## Data Sources

Data is sourced from the Arizona Department of Education:

- Accountability & Research:
  <https://www.azed.gov/accountability-research/data>

- October 1 Enrollment Reports published annually

## Available Years

Data is available from 2011 through the present:

- Era 1 (2011-2017): Original Excel format with multiple tabs

- Era 2 (2018-2023): Updated format with FY notation and demographic
  breakdowns

- Era 3 (2024-present): Simplified naming convention

Note: Historical data from the 1990s-2000s exists only as PDF reports
and is not currently supported by this package.

## See also

Useful links:

- <https://almartin82.github.io/azschooldata/>

- <https://github.com/almartin82/azschooldata>

- Report bugs at <https://github.com/almartin82/azschooldata/issues>

## Author

**Maintainer**: Al Martin <almartin@example.com>
