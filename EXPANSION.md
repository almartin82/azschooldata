# Arizona School Data Expansion Research

**Last Updated:** 2026-01-03
**Theme Researched:** Graduation Rates

## Data Sources Found

### Source 1: AZ Report Cards API (RECOMMENDED)

- **Base URL:** `https://azreportcards.azed.gov/api/`
- **HTTP Status:** 200 (working)
- **Format:** JSON API
- **Years Available:** FY2018-FY2025 (8 years)
- **Access Method:** Direct API calls (no authentication required)
- **Update Frequency:** Annual

#### Key API Endpoints Discovered:

| Endpoint | Purpose | Parameters |
|----------|---------|------------|
| `/api/DataApi/GetFiscalYears` | List available years | None |
| `/api/Entity/GetEntityList?fiscalYear=` | All LEAs and schools | fiscalYear |
| `/api/DataApi/GetGradRateTrendData` | Graduation rates by entity | educationOrganizationId, fiscalYear |
| `/api/DataApi/Graduation%20Rate` | Single-year graduation data | educationOrganizationId, fiscalYear |
| `/api/DataApi/GetDetailsForState` | State-level summary | fiscalYear |
| `/api/DataApi/GetStudentSubGroups` | Available demographic subgroups | None |
| `/api/DataApi/Dropout%20Rate` | Dropout rate data | educationOrganizationId, fiscalYear |

#### Sample API Response (GetGradRateTrendData):
```json
{
  "graduationRateId": 7593,
  "fiscalYear": 2018,
  "educationOrganizationId": 4216,
  "numInCohort": 33,
  "numGraduated": 13,
  "trendResult": 39.39,
  "redacted": 0,
  "studentGroupDescription": "All",
  "uiDescription": "All",
  "sortOrder": 1
}
```

### Source 2: ADE Static Excel Files (BLOCKED)

- **URL Pattern:** `https://www.azed.gov/sites/default/files/{year}/{month}/{filename}.xlsx`
- **HTTP Status:** 403 (Cloudflare blocking automated access)
- **Format:** Excel (.xlsx)
- **Years Available:** Cohort 2010-2025 (based on search results)
- **Access Method:** Blocked for programmatic access as of 2026

#### Known File URLs (all returning 403):
- Cohort 2023: `/2024/01/4Year_Grad_Rate_Cohort2023_publish[1].xlsx`
- Cohort 2022: `/2023/05/4Ygraduation_rate_cohort_2022_redacted.xlsx`
- Cohort 2020: `/2021/06/Cohort 2020 4 Year Graduation Rate Final.xlsx`

**Note:** The ADE main website has implemented Cloudflare protection that blocks all programmatic downloads. The AZ Report Cards API is NOT affected and works reliably.

### Source 3: ADE Technical Documentation

- **URL:** `https://www.azed.gov/sites/default/files/2021/11/FY22%20Grad%20Drop%20and%20Persistence%20Rate%20Tech%20Manual.pdf`
- **HTTP Status:** 403 (also blocked by Cloudflare)
- **Format:** PDF
- **Content:** Calculation methodology, business rules, code definitions

## Schema Analysis

### API Response Schema (GetGradRateTrendData)

| Field | Type | Description |
|-------|------|-------------|
| graduationRateId | integer | Unique record ID |
| fiscalYear | integer | School year end (2018 = 2017-18) |
| educationOrganizationId | integer | Entity ID (LEA or school) |
| numInCohort | integer | Students in graduation cohort (-1 = suppressed) |
| numGraduated | integer | Students who graduated (-1 = suppressed) |
| trendResult | decimal | Graduation rate percentage (-1 = suppressed) |
| redacted | integer | 1 = suppressed for FERPA, 0 = not suppressed |
| studentGroupDescription | string | Subgroup code (All, M, F, HL, BAA, etc.) |
| uiDescription | string | Human-readable subgroup name |
| sortOrder | integer | Display ordering |

### Student Subgroups Available

| Code | Description |
|------|-------------|
| All | All Students |
| M | Male |
| F | Female |
| BAA | Black/African American |
| AIAN | American Indian or Alaska Native |
| NHPI | Native Hawaiian or Pacific Islander |
| HL | Hispanic or Latino |
| W | White |
| A | Asian |
| MR | Multiple Races |
| IE | Economically Disadvantaged (Income Eligibility) |
| EL | English Learners |
| ELFEP4 | EL (Plus FEP 1-4) |
| CWD | Children with Disabilities |
| CWD/SPED | Special Education (legacy) |
| H | Homeless |
| MG | Migrant |
| FC | Foster Care |
| PAM | Parent Active Military |

### Entity Types

- LEA (Local Education Agency): Districts and charter organizations
- School: Individual campus/school sites

### Fiscal Year Mapping

Arizona uses fiscal year notation:
- FY2024 = 2023-24 school year = Cohort that should have graduated in 2024
- API fiscalYear parameter uses the end year (2024 for FY2024)

### Known Data Issues

1. **FERPA Suppression:** Small cohorts (<11 students) are redacted. Values show as -1 or -11.
2. **trendResult = -1:** Indicates suppressed/redacted data
3. **numInCohort = -1:** Indicates suppressed cohort size
4. **Rate Calculation:** `trendResult = (numGraduated / numInCohort) * 100`

### ID System

- educationOrganizationId: 4-5 digit integer (e.g., 4235 = Mesa Unified District)
- No leading zeros required (integer type)
- Mapping available via `/api/Entity/GetEntityList`

## Time Series Heuristics

Based on state-level data from API:

| Metric | Expected Range | Red Flag If |
|--------|---------------|-------------|
| State 4-year grad rate | 75% - 82% | Change >3% YoY |
| State enrollment (high schools) | ~300,000 | Change >10% YoY |
| District count | ~600 LEAs | Sudden change |
| Subgroup rates | Varies by group | Hispanic/AIAN consistently lower |

### State-Level Benchmarks (FY2024)

From `/api/DataApi/GetDetailsForState?fiscalYear=2024`:
- **Graduation Rate:** 77.86%
- **Dropout Rate:** 5%
- **Student Enrollment:** 1,113,609
- **School Count:** 2,464

### Historical State Graduation Rates (All Students)

| Year | Rate |
|------|------|
| FY2018 | ~77% |
| FY2019 | ~78% |
| FY2020 | ~79% |
| FY2021 | ~79% |
| FY2022 | ~78% |
| FY2023 | ~77% |
| FY2024 | ~78% |

## Recommended Implementation

### Priority: HIGH
- High-value data type frequently requested
- API access is reliable and comprehensive
- Complements existing enrollment data

### Complexity: EASY
- Clean JSON API with consistent schema
- No authentication required
- No file downloads needed
- Schema is stable across years

### Estimated Files to Modify: 4-5

1. `R/get_raw_graduation.R` - API access functions
2. `R/process_graduation.R` - Data processing
3. `R/tidy_graduation.R` - Long format transformation
4. `R/fetch_graduation.R` - Main user-facing function
5. `tests/testthat/test-graduation.R` - Test suite

### Implementation Steps:

1. **Create `get_entity_list()`** - Fetch all LEAs/schools for a fiscal year
2. **Create `get_raw_grad()`** - Fetch graduation data for one entity
3. **Create `get_raw_grad_all()`** - Batch fetch for all entities (with progress)
4. **Create `process_grad()`** - Clean and standardize column names
5. **Create `tidy_grad()`** - Pivot to long format with subgroup column
6. **Create `fetch_grad()`** - Main function with caching
7. **Create `fetch_grad_multi()`** - Multi-year convenience function
8. **Update caching** - Add graduation cache types
9. **Add tests** - Fidelity tests with known values

### API Call Strategy:

```r
# 1. Get list of all entities
entities <- httr::GET(
  "https://azreportcards.azed.gov/api/Entity/GetEntityList",
  query = list(fiscalYear = 2024)
)

# 2. For each entity, get graduation data
grad_data <- httr::GET(
  "https://azreportcards.azed.gov/api/DataApi/GetGradRateTrendData",
  query = list(
    educationOrganizationId = entity_id,
    fiscalYear = 2024
  )
)
```

### Rate Limiting Considerations:

- No documented rate limits
- Recommend 100ms delay between calls for politeness
- Batch by fiscal year to minimize API calls
- Use caching aggressively

## Test Requirements

### Raw Data Fidelity Tests Needed:

```r
test_that("FY2024 state graduation rate matches API", {
  # From /api/DataApi/GetDetailsForState?fiscalYear=2024
  # Expected: 77.86%
  state_data <- fetch_grad(2024) |>
    filter(entity_type == "state", subgroup == "All")
  expect_equal(state_data$grad_rate, 77.86, tolerance = 0.01)
})

test_that("FY2024 Mesa Unified graduation rate matches API", {
  # educationOrganizationId = 4235
  # Verify against direct API call
  data <- fetch_grad(2024) |>
    filter(entity_id == 4235, subgroup == "All")
  expect_true(nrow(data) > 0)
  expect_true(data$grad_rate > 0 & data$grad_rate <= 100)
})

test_that("Subgroup data available for major districts", {
  data <- fetch_grad(2024) |>
    filter(entity_id == 4235)
  subgroups <- unique(data$subgroup)
  expect_true("All" %in% subgroups)
  expect_true("Hispanic" %in% subgroups | "HL" %in% subgroups)
})
```

### Data Quality Checks:

```r
test_that("Graduation rates are valid percentages", {
  data <- fetch_grad(2024, tidy = TRUE)
  valid_data <- data |> filter(!is.na(grad_rate) & grad_rate >= 0)
  expect_true(all(valid_data$grad_rate >= 0))
  expect_true(all(valid_data$grad_rate <= 100))
})

test_that("No missing entity names", {
  data <- fetch_grad(2024)
  expect_false(any(is.na(data$entity_name)))
})

test_that("Suppressed values properly coded", {
  data <- fetch_grad(2024)
  suppressed <- data |> filter(redacted == 1)
  # Suppressed records should have NA or -1 values
  expect_true(all(suppressed$num_in_cohort <= 0 | is.na(suppressed$num_in_cohort)))
})
```

### LIVE Pipeline Tests:

```r
test_that("API is accessible", {
  skip_if_offline()
  response <- httr::GET(
    "https://azreportcards.azed.gov/api/DataApi/GetFiscalYears",
    httr::timeout(30)
  )
  expect_equal(httr::status_code(response), 200)
})

test_that("Entity list returns data", {
  skip_if_offline()
  response <- httr::GET(
    "https://azreportcards.azed.gov/api/Entity/GetEntityList",
    query = list(fiscalYear = 2024),
    httr::timeout(60)
  )
  expect_equal(httr::status_code(response), 200)
  data <- httr::content(response)
  expect_gt(length(data), 500)  # Expect 600+ entities
})
```

## Additional Notes

### Advantages of API Approach:

1. **No Cloudflare blocking** - API works while static files are blocked
2. **Consistent schema** - JSON structure is stable across years
3. **Granular access** - Can fetch specific entities/years
4. **Includes suppression flags** - Clear indicator of redacted data
5. **Subgroup data included** - Race, gender, EL, SPED, etc.

### Comparison with Excel File Approach:

| Feature | API | Excel Files |
|---------|-----|-------------|
| Access | Working | Blocked (403) |
| Format | JSON | xlsx |
| Entity-level | Yes | Yes |
| Subgroups | Yes | Yes |
| Historical | 2018-2025 | 2010-2025 |
| Batch download | Requires iteration | Single file per year |
| Rate | May vary slightly | Official published |

### Future Considerations:

1. **5-Year Graduation Rate** - Also available via API, could add later
2. **Dropout Rate** - Available at same endpoints
3. **Persistence Rate** - May be available
4. **Caching strategy** - Cache entire years to minimize API calls
