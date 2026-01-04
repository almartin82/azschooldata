# Convert to numeric, handling suppression markers

ADE uses asterisks (\*) for suppressed data (groups with fewer than 11
students) and may use commas in large numbers.

## Usage

``` r
safe_numeric(x)
```

## Arguments

- x:

  Vector to convert

## Value

Numeric vector with NA for non-numeric values
