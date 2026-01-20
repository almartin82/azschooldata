# azschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/azschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/azschooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://github.com/almartin82/azschooldata/actions/workflows/python-test.yaml/badge.svg)](https://github.com/almartin82/azschooldata/actions/workflows/python-test.yaml)
[![pkgdown](https://github.com/almartin82/azschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/azschooldata/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

Fetch and analyze Arizona school enrollment data from the Arizona Department of Education (ADE) in R or Python.

**Part of the [njschooldata](https://github.com/almartin82/njschooldata) family** - providing consistent access to state education data across all 50 states.

**[Full Documentation](https://almartin82.github.io/azschooldata/)** | **[Vignette with 15 Stories](https://almartin82.github.io/azschooldata/articles/enrollment_simple.html)**

## What's in Arizona's school data?

**1.1 million students** across 638 districts in the Grand Canyon State. Data available for 2018 and 2024 (2019-2023 unavailable due to Cloudflare protection on ADE's website).

---

### 1. Arizona enrollment flat despite population boom

While Arizona's population grew 8% from 2018-2024, public school enrollment stayed nearly flat - adding just 2,400 students (0.2% growth). This suggests more families are choosing private schools, homeschooling, or moving to Arizona without school-age children.

```r
library(azschooldata)
library(dplyr)

enr <- fetch_enr_multi(c(2018, 2024), use_cache = TRUE)

enr |>
  filter(is_district, district_name != "Arizona",
         subgroup == "total_enrollment", grade_level == "TOTAL") |>
  group_by(end_year) |>
  summarize(total_students = sum(n_students, na.rm = TRUE), .groups = "drop") |>
  mutate(change = total_students - lag(total_students),
         pct_change = round(change / lag(total_students) * 100, 1))
```

```
# A tibble: 2 x 4
  end_year total_students change pct_change
     <dbl>          <dbl>  <dbl>      <dbl>
1     2018        1112682     NA       NA
2     2024        1115111   2429        0.2
```

![State enrollment chart](https://almartin82.github.io/azschooldata/articles/enrollment_simple_files/figure-html/state-enrollment-chart-1.png)

---

### 2. Hispanic students now 48% of Arizona schools

Hispanic students grew from 45.7% to 48.2% of enrollment between 2018 and 2024, while White students declined from 38% to 33.8%. Arizona's schools are becoming increasingly diverse.

```r
demographics <- enr |>
  filter(is_district, district_name != "Arizona", grade_level == "TOTAL",
         subgroup %in% c("hispanic", "white", "black", "asian",
                         "native_american", "multiracial", "total_enrollment")) |>
  group_by(end_year, subgroup) |>
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop") |>
  group_by(end_year) |>
  mutate(pct = round(n_students / n_students[subgroup == "total_enrollment"] * 100, 1)) |>
  filter(subgroup != "total_enrollment")

demographics |>
  select(end_year, subgroup, n_students, pct) |>
  arrange(end_year, desc(n_students))
```

```
# A tibble: 10 x 4
   end_year subgroup        n_students   pct
      <dbl> <chr>                <dbl> <dbl>
 1     2018 hispanic            508121  45.7
 2     2018 white               422414  38
 3     2018 black                58875   5.3
 4     2018 asian                31283   2.8
 5     2024 hispanic            536955  48.2
 6     2024 white               376562  33.8
 7     2024 black                63367   5.7
 8     2024 multiracial          46487   4.2
 9     2024 native_american      44791   4
10     2024 asian                34126   3.1
```

![Demographics chart](https://almartin82.github.io/azschooldata/articles/enrollment_simple_files/figure-html/demographics-chart-1.png)

---

### 3. Queen Creek doubled in size while Mesa lost 5,400 students

Queen Creek Unified grew 104% (from 7,095 to 14,474 students) as new subdivisions opened in the southeast Valley. Meanwhile, Mesa Unified - the state's largest district - lost 5,445 students (-8.7%).

```r
growth <- enr |>
  filter(is_district, district_name != "Arizona",
         subgroup == "total_enrollment", grade_level == "TOTAL") |>
  group_by(end_year, district_name) |>
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop") |>
  pivot_wider(names_from = end_year, values_from = n_students,
              names_prefix = "y") |>
  filter(!is.na(y2018), !is.na(y2024), y2018 >= 1000) |>
  mutate(change = y2024 - y2018,
         pct_change = round((y2024 / y2018 - 1) * 100, 1)) |>
  arrange(desc(change))

growth |>
  select(district_name, y2018, y2024, change, pct_change) |>
  head(10)
```

```
# A tibble: 10 x 5
   district_name                         y2018 y2024 change pct_change
   <chr>                                 <dbl> <dbl>  <dbl>      <dbl>
 1 Queen Creek Unified District           7095 14474   7379      104
 2 American Leadership Academy, Inc.      7904 13787   5883       74.4
 3 American Virtual Academy               4227  7147   2920       69.1
 4 Leman Academy of Excellence, Inc.      2042  4777   2735      134
 5 Tolleson Union High School District   11152 13785   2633       23.6
 6 Maricopa Unified School District       6661  9262   2601       39
 7 Agua Fria Union High School District   7766  9974   2208       28.4
 8 Saddle Mountain Unified School Dist    1630  3245   1615       99.1
 9 Buckeye Union High School District     4014  5520   1506       37.5
10 Glendale Union High School District   14997 16318   1321        8.8
```

![Growth chart](https://almartin82.github.io/azschooldata/articles/enrollment_simple_files/figure-html/growth-chart-1.png)

---

### 4. Arizona has 34% more seniors than kindergartners

There are 96,316 12th graders but only 71,728 kindergartners - a 34% difference. This "inverted pyramid" could signal declining birth rates or families with young children leaving public schools.

```r
grade_order <- c("PK", "K", "01", "02", "03", "04", "05",
                 "06", "07", "08", "09", "10", "11", "12")

grades <- enr |>
  filter(is_district, district_name != "Arizona",
         subgroup == "total_enrollment", grade_level %in% grade_order,
         end_year == 2024) |>
  group_by(grade_level) |>
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop") |>
  mutate(grade_level = factor(grade_level, levels = grade_order))

grades |>
  arrange(grade_level)
```

```
# A tibble: 14 x 2
   grade_level n_students
   <fct>            <dbl>
 1 PK               20326
 2 K                71728
 3 01               77610
 4 02               81369
 5 03               79268
 6 04               81776
 7 05               81887
 8 06               81836
 9 07               83291
10 08               84367
11 09               89135
12 10               91940
13 11               89531
14 12               96316
```

![Grade distribution chart](https://almartin82.github.io/azschooldata/articles/enrollment_simple_files/figure-html/grade-chart-1.png)

---

### 5. Charters serve nearly 1 in 4 Arizona students

Charter schools and other non-traditional districts now serve 24% of Arizona's students (270,000 students across 443 districts). Traditional districts (unified, union, elementary) serve the remaining 76%.

```r
charter_data <- enr |>
  filter(is_district, district_name != "Arizona",
         subgroup == "total_enrollment", grade_level == "TOTAL",
         end_year == 2024) |>
  mutate(district_type = case_when(
    grepl("Unified|Union|Elementary District|High School District", district_name) ~ "Traditional",
    TRUE ~ "Charter/Other"
  )) |>
  group_by(district_type) |>
  summarize(
    n_districts = n(),
    total_students = sum(n_students, na.rm = TRUE),
    avg_size = round(mean(n_students), 0),
    .groups = "drop"
  ) |>
  mutate(pct = round(total_students / sum(total_students) * 100, 1))

charter_data
```

```
# A tibble: 2 x 5
  district_type n_districts total_students avg_size   pct
  <chr>               <int>          <dbl>    <dbl> <dbl>
1 Charter/Other         443         270016      610  24.2
2 Traditional           195         845095     4334  75.8
```

![Charter chart](https://almartin82.github.io/azschooldata/articles/enrollment_simple_files/figure-html/charter-chart-1.png)

---

## Installation

### R

```r
# install.packages("remotes")
remotes::install_github("almartin82/azschooldata")
```

### Python

```bash
pip install pyazschooldata
```

---

## Quick Start

### R

```r
library(azschooldata)
library(dplyr)

# Fetch one year
enr_2024 <- fetch_enr(2024)

# Fetch multiple years
enr_multi <- fetch_enr_multi(c(2018, 2024))

# State totals
enr_2024 |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

# District breakdown
enr_2024 |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students))

# Demographics
enr_2024 |>
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("hispanic", "white", "black", "asian", "native_american")) |>
  select(subgroup, n_students, pct)
```

### Python

```python
import pyazschooldata as az

# Fetch one year
enr_2024 = az.fetch_enr(2024)

# Fetch multiple years
enr_multi = az.fetch_enr_multi([2018, 2024])

# State totals
state_total = enr_2024[
    (enr_2024['is_state'] == True) &
    (enr_2024['subgroup'] == 'total_enrollment') &
    (enr_2024['grade_level'] == 'TOTAL')
]

# District breakdown
districts = enr_2024[
    (enr_2024['is_district'] == True) &
    (enr_2024['subgroup'] == 'total_enrollment') &
    (enr_2024['grade_level'] == 'TOTAL')
].sort_values('n_students', ascending=False)

# Demographics
demographics = enr_2024[
    (enr_2024['is_state'] == True) &
    (enr_2024['grade_level'] == 'TOTAL') &
    (enr_2024['subgroup'].isin(['hispanic', 'white', 'black', 'asian', 'native_american']))
][['subgroup', 'n_students', 'pct']]
```

---

## Data Notes

**Source:** Arizona Department of Education October 1 Enrollment Reports

**URL:** https://www.azed.gov/accountability-research

**Available years:** 2018, 2024

**Missing years:** 2019-2023 (Cloudflare protection blocks automated downloads)

**Census Day:** October 1 of each school year

**Important caveats:**
- Small counts may be suppressed in the source data
- The ADE data includes a row named "Arizona" that appears to double-count state totals; this package's vignettes exclude this row for accurate district-level analysis
- Virtual and charter schools are counted separately from traditional districts

**What's included:**
- State, district, and school level enrollment
- Demographics: Hispanic, White, Black, Asian, Native American, Pacific Islander, Multiracial
- Gender: Male, Female
- Grade levels: PK through 12

---

## More Stories

See the [full vignette](https://almartin82.github.io/azschooldata/articles/enrollment_simple.html) for 10 more data stories including:

- San Carlos is 99% Native American
- Border districts are over 95% Hispanic
- Mesa Unified is still Arizona's largest district
- Top 27 districts educate half of Arizona's students
- Virtual schools serve 7,000+ students
- And more...

---

## Part of the State Schooldata Project

A simple, consistent interface for accessing state-published school data in Python and R.

Started with [njschooldata](https://github.com/almartin82/njschooldata), now expanding to all 50 states.

**All state packages:** [github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

---

## Author

[Andy Martin](https://github.com/almartin82) (almartin@gmail.com)

## License

MIT
