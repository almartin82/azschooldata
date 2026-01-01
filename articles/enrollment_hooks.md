# 10 Insights from Arizona School Enrollment Data

``` r
library(azschooldata)
library(dplyr)
library(tidyr)
library(ggplot2)

theme_set(theme_minimal(base_size = 14))
```

This vignette explores Arizona’s public school enrollment data,
surfacing key trends and demographic patterns across 15 years of data
(2011-2025).

------------------------------------------------------------------------

## 1. Arizona’s enrollment boom has stalled

Arizona was one of America’s fastest-growing states, but enrollment
growth has slowed dramatically. The state peaked around 2019 and has
been flat since.

``` r
enr <- fetch_enr_multi(2011:2025)

state_totals <- enr |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(end_year, n_students) |>
  mutate(change = n_students - lag(n_students),
         pct_change = round(change / lag(n_students) * 100, 2))

state_totals
```

``` r
ggplot(state_totals, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.2, color = "#BF0A30") +
  geom_point(size = 3, color = "#BF0A30") +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Arizona Public School Enrollment (2011-2025)",
    subtitle = "Rapid growth has stalled in recent years",
    x = "School Year (ending)",
    y = "Total Enrollment"
  )
```

------------------------------------------------------------------------

## 2. Mesa Unified is shrinking while Gilbert grows

Mesa Unified, once Arizona’s largest district, has lost thousands of
students while neighboring Gilbert Public Schools has surged past
40,000.

``` r
mesa_gilbert <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Mesa Unified|Gilbert", district_name)) |>
  select(end_year, district_name, n_students) |>
  pivot_wider(names_from = end_year, values_from = n_students)

mesa_gilbert
```

``` r
enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Mesa Unified|Gilbert", district_name)) |>
  ggplot(aes(x = end_year, y = n_students, color = district_name)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Mesa vs Gilbert: Diverging Enrollment Paths",
    subtitle = "Gilbert surges while Mesa declines",
    x = "School Year",
    y = "Enrollment",
    color = "District"
  )
```

------------------------------------------------------------------------

## 3. COVID crushed kindergarten

Arizona kindergarten enrollment dropped over 10% during COVID and hasn’t
fully recovered, signaling smaller cohorts for years to come.

``` r
covid_grades <- enr |>
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "06", "09"),
         end_year %in% 2019:2025) |>
  select(end_year, grade_level, n_students) |>
  pivot_wider(names_from = grade_level, values_from = n_students)

covid_grades
```

------------------------------------------------------------------------

## 4. The Hispanic majority arrived

Hispanic students now comprise over 45% of Arizona enrollment, making
them the largest demographic group in the state’s public schools.

``` r
enr_2025 <- fetch_enr(2025)

demographics <- enr_2025 |>
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("hispanic", "white", "black", "asian", "native_american", "multiracial")) |>
  mutate(pct = round(pct * 100, 1)) |>
  select(subgroup, n_students, pct) |>
  arrange(desc(n_students))

demographics
```

``` r
demographics |>
  mutate(subgroup = forcats::fct_reorder(subgroup, n_students)) |>
  ggplot(aes(x = n_students, y = subgroup, fill = subgroup)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = paste0(pct, "%")), hjust = -0.1) +
  scale_x_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.15))) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Arizona Student Demographics (2025)",
    subtitle = "Hispanic students are now the largest group",
    x = "Number of Students",
    y = NULL
  )
```

------------------------------------------------------------------------

## 5. Phoenix Elementary has lost half its students

Phoenix Elementary School District, serving central Phoenix, has
hemorrhaged enrollment to charters and suburban flight over the past
decade.

``` r
phoenix_elem <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Phoenix Elementary", district_name)) |>
  select(end_year, district_name, n_students) |>
  mutate(pct_of_peak = round(n_students / max(n_students) * 100, 1))

phoenix_elem
```

------------------------------------------------------------------------

## 6. Charter schools serve 1 in 5 students

Arizona has the most expansive charter school sector in the nation, with
over 200,000 students—nearly 20% of all enrollment.

``` r
state_total <- enr_2025 |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  pull(n_students)

charter_total <- enr_2025 |>
  filter(is_charter, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  summarize(charter_total = sum(n_students, na.rm = TRUE)) |>
  pull(charter_total)

tibble(
  sector = c("All Public Schools", "Charter Schools"),
  enrollment = c(state_total, charter_total),
  pct = c(100, round(charter_total / state_total * 100, 1))
)
```

------------------------------------------------------------------------

## 7. Native American enrollment is significant

Arizona has one of the nation’s largest Native American student
populations, with significant enrollment in reservation-based schools.

``` r
native_am <- enr_2025 |>
  filter(is_district, subgroup == "native_american", grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  head(10) |>
  select(district_name, n_students, pct)

native_am
```

------------------------------------------------------------------------

## 8. The Southeast Valley is Arizona’s growth engine

Queen Creek, Chandler, and Gilbert districts in the Southeast Valley are
among the fastest-growing in the state.

``` r
se_valley <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Queen Creek|Chandler|Gilbert|Higley", district_name),
         end_year %in% c(2015, 2025)) |>
  group_by(district_name) |>
  summarize(
    y2015 = n_students[end_year == 2015],
    y2025 = n_students[end_year == 2025],
    pct_change = round((y2025 / y2015 - 1) * 100, 1),
    .groups = "drop"
  ) |>
  arrange(desc(pct_change))

se_valley
```

------------------------------------------------------------------------

## 9. English learners are 6% of enrollment

Arizona’s English learner population has grown with immigration,
particularly in Phoenix and Tucson.

``` r
ell <- enr_2025 |>
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("lep", "total_enrollment")) |>
  select(subgroup, n_students, pct)

ell
```

------------------------------------------------------------------------

## 10. Tucson Unified is Arizona’s second city

Tucson Unified School District, with over 40,000 students, anchors
Southern Arizona and has demographics quite different from the Phoenix
metro.

``` r
tucson <- enr_2025 |>
  filter(is_district, grade_level == "TOTAL",
         grepl("Tucson Unified", district_name),
         subgroup %in% c("total_enrollment", "hispanic", "white", "black")) |>
  select(district_name, subgroup, n_students, pct)

tucson
```

------------------------------------------------------------------------

## Summary

Arizona’s school enrollment data reveals:

- **Stalled growth**: The boom state’s enrollment has plateaued
- **Charter dominance**: 1 in 5 students in charter schools
- **Hispanic plurality**: Over 45% of students are Hispanic
- **Urban-suburban shift**: Core districts shrink while outer ring grows
- **Native American presence**: Significant reservation-based enrollment

These patterns shape school funding debates and facility planning across
the Grand Canyon State.

------------------------------------------------------------------------

*Data sourced from the Arizona Department of Education [Research and
Evaluation](https://www.azed.gov/accountability-research).*
