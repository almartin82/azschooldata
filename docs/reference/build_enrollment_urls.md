# Build potential enrollment file URLs

ADE uses various URL patterns across years. This function generates a
list of URLs to try based on observed patterns.

## Usage

``` r
build_enrollment_urls(end_year)
```

## Arguments

- end_year:

  School year end

## Value

Character vector of URLs to try

## Details

URL patterns discovered through research:

- FY24 (2024): /2023/11/Oct1Enrollment2024_publish.xlsx

- FY19 (2019): /2019/10/Fiscal Year 2019 Accountabilty October
  Enrollment REDACTED.xlsx

- FY19 (2019): /2021/05/October 1 Enrollment 2018 -2019 UPDATED 2021
  V2.xlsx

- FY18 (2018): /2021/05/2017-2018 October 1 Public Enrollment File
  UPDATED 2021 V2.xlsx

- FY16 (2016): /2017/06/october-1-fy16-enrollment.xlsx

- FY13 (2013): /2017/06/october-1-2012-2013.enrollment_count.xlsx
