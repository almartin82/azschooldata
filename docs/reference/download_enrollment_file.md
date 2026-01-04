# Download enrollment Excel file from ADE

Tries multiple URL patterns to find the enrollment file. ADE uses
inconsistent naming conventions across years.

## Usage

``` r
download_enrollment_file(end_year)
```

## Arguments

- end_year:

  School year end

## Value

Path to downloaded temp file, or NULL if download failed
