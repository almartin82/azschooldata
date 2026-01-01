# azschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/azschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/azschooldata/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/almartin82/azschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/azschooldata/actions/workflows/pkgdown.yaml)
<!-- badges: end -->

Fetch and analyze Arizona public school enrollment data from the Arizona Department of Education (ADE).

**[Documentation](https://almartin82.github.io/azschooldata/)** | **[10 Key Insights](https://almartin82.github.io/azschooldata/articles/enrollment_hooks.html)** | **[Getting Started](https://almartin82.github.io/azschooldata/articles/quickstart.html)**

## What can you find with azschooldata?

> **See the full analysis with charts and data output:** [10 Insights from Arizona Enrollment Data](https://almartin82.github.io/azschooldata/articles/enrollment_hooks.html)

**15 years of enrollment data (2011-2025).** 1.1 million students across 230+ districts in the Grand Canyon State. Here are ten stories hiding in the numbers:

---

### 1. Arizona's enrollment boom has stalled

Arizona was one of America's fastest-growing states, but enrollment growth has slowed dramatically. The state peaked around 2019 and has been flat since.

```r
library(azschooldata)
library(dplyr)

enr <- fetch_enr_multi(2011:2025)

enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, n_students) %>%
  mutate(change = n_students - lag(n_students))
```

![Arizona enrollment trend](https://almartin82.github.io/azschooldata/articles/enrollment_hooks_files/figure-html/statewide-chart-1.png)

---

### 2. Mesa Unified is shrinking while Gilbert grows

Mesa Unified, once Arizona's largest district, has lost thousands of students while neighboring Gilbert Public Schools has surged past 40,000.

```r
enr <- fetch_enr_multi(2015:2025)

enr %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Mesa Unified|Gilbert", district_name)) %>%
  select(end_year, district_name, n_students) %>%
  tidyr::pivot_wider(names_from = end_year, values_from = n_students)
```

![Mesa vs Gilbert](https://almartin82.github.io/azschooldata/articles/enrollment_hooks_files/figure-html/mesa-gilbert-chart-1.png)

---

### 3. COVID crushed kindergarten

Arizona kindergarten enrollment dropped over 10% during COVID and hasn't fully recovered, signaling smaller cohorts for years to come.

```r
enr <- fetch_enr_multi(2019:2025)

enr %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "06", "09")) %>%
  select(end_year, grade_level, n_students) %>%
  tidyr::pivot_wider(names_from = grade_level, values_from = n_students)
```

---

### 4. The Hispanic majority arrived

Hispanic students now comprise over 45% of Arizona enrollment, making them the largest demographic group in the state's public schools.

```r
enr_2025 <- fetch_enr(2025)

enr_2025 %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("hispanic", "white", "black", "asian", "native_american", "multiracial")) %>%
  mutate(pct = round(pct * 100, 1)) %>%
  select(subgroup, n_students, pct) %>%
  arrange(desc(n_students))
```

![Arizona demographics](https://almartin82.github.io/azschooldata/articles/enrollment_hooks_files/figure-html/demographics-chart-1.png)

---

### 5. Phoenix Elementary has lost half its students

Phoenix Elementary School District, serving central Phoenix, has hemorrhaged enrollment to charters and suburban flight over the past decade.

```r
enr <- fetch_enr_multi(2011:2025)

enr %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Phoenix Elementary", district_name)) %>%
  select(end_year, district_name, n_students) %>%
  mutate(pct_of_peak = round(n_students / max(n_students) * 100, 1))
```

---

### 6. Charter schools serve 1 in 5 students

Arizona has the most expansive charter school sector in the nation, with over 200,000 students--nearly 20% of all enrollment.

```r
enr_2025 %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(n_students)

# Charter total
enr_2025 %>%
  filter(is_charter, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  summarize(charter_total = sum(n_students, na.rm = TRUE))
```

---

### 7. Native American enrollment is significant

Arizona has one of the nation's largest Native American student populations, with significant enrollment in reservation-based schools and districts like Window Rock and Kayenta.

```r
enr_2025 %>%
  filter(is_district, subgroup == "native_american", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(10) %>%
  select(district_name, n_students, pct)
```

---

### 8. The Southeast Valley is Arizona's growth engine

Queen Creek, Chandler, and Gilbert districts in the Southeast Valley are among the fastest-growing in the state.

```r
enr <- fetch_enr_multi(2015:2025)

enr %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Queen Creek|Chandler|Gilbert|Higley", district_name)) %>%
  group_by(district_name) %>%
  summarize(
    y2015 = n_students[end_year == 2015],
    y2025 = n_students[end_year == 2025],
    pct_change = round((y2025 / y2015 - 1) * 100, 1)
  ) %>%
  arrange(desc(pct_change))
```

---

### 9. English learners are 6% of enrollment

Arizona's English learner population has grown with immigration and refugee resettlement, particularly in Phoenix and Tucson.

```r
enr_2025 %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("lep", "total_enrollment")) %>%
  select(subgroup, n_students, pct)
```

---

### 10. Tucson Unified is Arizona's second city

Tucson Unified School District, with over 40,000 students, anchors Southern Arizona and has demographics quite different from the Phoenix metro.

```r
enr_2025 %>%
  filter(is_district, grade_level == "TOTAL",
         grepl("Tucson Unified", district_name),
         subgroup %in% c("total_enrollment", "hispanic", "white", "black")) %>%
  select(district_name, subgroup, n_students, pct)
```

---

## Installation

```r
# install.packages("remotes")
remotes::install_github("almartin82/azschooldata")
```

## Quick start

```r
library(azschooldata)
library(dplyr)

# Fetch one year
enr_2025 <- fetch_enr(2025)

# Fetch multiple years
enr_multi <- fetch_enr_multi(2020:2025)

# State totals
enr_2025 %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

# District breakdown
enr_2025 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students))

# Demographics
enr_2025 %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("hispanic", "white", "black", "asian", "native_american")) %>%
  select(subgroup, n_students, pct)
```

## Data availability

| Years | Source | Notes |
|-------|--------|-------|
| **2011-2025** | ADE October 1 Enrollment | Full demographic and grade-level data |

Data is sourced from the Arizona Department of Education October 1 enrollment reports.

### What's included

- **Levels:** State, district (~230), school (~2,400)
- **Demographics:** Hispanic, White, Black, Asian, Native American, Pacific Islander, Two or More Races
- **Special populations:** English learners, economically disadvantaged, students with disabilities
- **Grade levels:** K-12

### Caveats

- Pre-2011 data exists as PDF reports only (not supported)
- ADE URL patterns vary across years; downloads may take a few seconds

## Data source

Arizona Department of Education: [Research and Evaluation](https://www.azed.gov/accountability-research)

## Part of the 50 State Schooldata Family

This package is part of a family of R packages providing school enrollment data for all 50 US states. Each package fetches data directly from the state's Department of Education.

**See also:** [njschooldata](https://github.com/almartin82/njschooldata) - The original state schooldata package for New Jersey.

**All packages:** [github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (almartin@gmail.com)

## License

MIT
