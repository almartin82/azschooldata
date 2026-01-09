# Read and merge enrollment sheets

Reads data from Grade, Gender, Ethnicity, and Subgroup sheets and merges
them into a single wide-format dataframe.

## Usage

``` r
read_and_merge_sheets(excel_path, sheets, level)
```

## Arguments

- excel_path:

  Path to Excel file

- sheets:

  Vector of sheet names

- level:

  Either "school" or "lea"

## Value

Merged data frame
