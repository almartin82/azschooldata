# Parse Era 2 Excel file (2018-present)

Newer ADE enrollment files have multiple sheets that must be merged:

- School by Grade (grade-level enrollment)

- School By Gender (male/female breakdown)

- School by Ethnicity (race/ethnicity breakdown)

- School by Subgroup (special populations: EL, SPED, FRL)

- LEA by Grade (district grade enrollment)

- LEA by Gender (district gender breakdown)

- LEA by Ethnicity (district race/ethnicity)

## Usage

``` r
parse_era2_excel(excel_path, end_year)
```

## Arguments

- excel_path:

  Path to downloaded Excel file

- end_year:

  School year end

## Value

List with school and district data frames
