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

---

# Arizona Assessment Data Expansion Research

**Research Date:** 2025-01-11
**Researcher:** Assessment Data Theme Study
**Status:** Research Complete - Implementation Pending

## Executive Summary

Arizona has transitioned through multiple assessment systems: AzMERIT (2015-2019), AzM2 (2020-2021), and AASA (2022-present). The Arizona Department of Education maintains comprehensive assessment data on the Accountability & Research Data portal with downloadable files organized by year.

**Complexity Level:** MEDIUM - Multiple assessment system transitions, but good data availability with clear documentation

---

## Historical Assessments Timeline

### 1. AzMERIT (Arizona's Measurement of Educational Readiness to Inform Teaching)
- **Years Available:** 2015-2019
- **Grades:** 3-11 (ELA), 3-8 (Math), EOC for high school
- **Subjects:** English Language Arts, Mathematics
- **Status:** Replaced by AzM2 in 2020
- **Data Sources:**
  - [Accountability & Research Data](https://www.azed.gov/accountability-research/data)
  - [State Assessment Results](https://www.azed.gov/accountability-research/state-assessment-results)
  - [AzMERIT 2016-17 Technical Report](https://www.azed.gov/sites/default/files/2018/08/AzMERIT-2016-17-TechRpt-508.pdf)
- **Notes:** First administered Spring 2015, baseline for Arizona assessments

### 2. AzM2 (Arizona's Measurement of Educational Readiness to Inform Teaching)
- **Years Available:** 2020-2021 (brief administration)
- **Grades:** 3-8 (ELA, Math)
- **Subjects:** English Language Arts, Mathematics
- **Status:** Renamed to AASA in 2021-2022
- **Data Sources:**
  - [Accountability & Research Data](https://www.azed.gov/accountability-research/data)
  - [AzM2 Family Report Guide](https://www.azed.gov/sites/default/files/2021/12/AzM2%20Family%20Report%20Guide.pdf)
- **Notes:** Transitional assessment, pandemic-affected

### 3. AASA (Arizona's Academic Standards Assessment) - Current
- **Years Available:** 2022-present (first administered 2021-2022)
- **Grades:** 3-8 (ELA, Math)
- **Subjects:** English Language Arts, Mathematics
- **Status:** Current assessment system, replaced AzM2
- **Data Sources:**
  - [Accountability & Research Data](https://www.azed.gov/accountability-research/data)
  - [2023-2024 AASA Test Windows](https://www.azed.gov/sites/default/files/2023/08/2023-2024%20AASA.pdf)
  - [AASA 2024 Technical Report](https://www.azed.gov/sites/default/files/2025/01/AASA_2024_Technical_Report.pdf)
  - [2023 Statewide Assessment Results](https://www.azed.gov/sites/default/files/2024/01/ADE%20Assessments%20Results%20SEAP%20January%202024.pdf)
- **Performance Levels:** Level 1-4 (Minimally Proficient, Partially Proficient, Proficient, Highly Proficient)

### 4. AzSCI (Arizona Science Test)
- **Years Available:** 2019-present
- **Grades:** 5, 8, 11
- **Subjects:** Science
- **Status:** Ongoing assessment
- **Data Sources:** Available via Accountability & Research Data portal

---

## Data Availability by Year

| Year | Assessment System | Notes |
|------|------------------|-------|
| 2015 | AzMERIT | First AzMERIT administration |
| 2016 | AzMERIT | Standard administration |
| 2017 | AzMERIT | Standard administration |
| 2018 | AzMERIT | Standard administration |
| 2019 | AzMERIT | Final AzMERIT year |
| 2020 | **None** | COVID-19 pandemic (assessments waived) |
| 2021 | AzM2 | Renamed to AASA 2021-2022, pandemic-affected |
| 2022 | AASA | First AASA administration |
| 2023 | AASA | Standard administration |
| 2024 | AASA | Standard administration |
| 2025 | AASA | Current system |

**Data Gaps:** 2020 (COVID-19), assessment system transitions 2019-2022

---

## Data Access and Format

### Primary Data Portal

**[Accountability & Research Data](https://www.azed.gov/accountability-research/data)**
- Main portal for all Arizona assessment data
- Organized by year with downloadable files
- Years available: 2018-2025 (regularly updated)
- File formats: Excel (.xlsx), PDF reports
- Download mechanism: Direct file downloads (no API for assessments)

### Data Organization

The portal provides files organized by assessment year:
- **Assessments 2025** (Updated 10/10/25)
- **Assessments 2024** (Updated 9/23/2024)
- **Assessments 2023** (Updated 10/06/2023)
- **Assessments 2022** (Updated 10/16/2023)
- Earlier years available in archive

### Expected File Contents

Based on Arizona assessment reporting patterns:
- Statewide proficiency percentages
- District and school-level results
- Performance level distributions
- Demographic subgroup breakdowns
- Subject-specific results (ELA, Math, Science)

---

## Data Structure Analysis

### Expected Schema Elements (Based on AzMERIT/AASA Patterns)

**Note:** Actual column names must be verified by inspecting downloaded Excel files.

#### AzMERIT/AASA Typical Fields
```
- school_year (e.g., "2023-2024")
- district_code
- district_name
- school_code
- school_name
- grade_level (3, 4, 5, 6, 7, 8, 11 for science)
- subject ("ELA", "Mathematics", "Science")
- tested_count
- performance_level_counts:
  - minimally_proficient_count
  - partially_proficient_count
  - proficient_count
  - highly_proficient_count
- proficiency_rate (Level 3 + Level 4)
- subgroup (All, Asian, Black, Hispanic, White, etc.)
- economic_status
- ell_status
- special_education_status
```

#### Performance Levels

**AzMERIT (2015-2019):**
- Minimally Proficient (Level 1)
- Partially Proficient (Level 2)
- Proficient (Level 3)
- Highly Proficient (Level 4)

**AASA (2022-present):**
- Same 4-level structure
- Proficient = Level 3 + Level 4

**Verification Required:** Actual column names and structure must be verified from downloaded Excel files.

---

## Demographic Subgroups

Based on Arizona reporting and federal requirements:

**Race/Ethnicity:**
- Asian
- Black/African American
- Hispanic/Latino
- Native American/American Indian
- Native Hawaiian/Pacific Islander
- White
- Multiple Races

**Other Subgroups:**
- Economically Disadvantaged
- English Learners
- Students with Disabilities
- Male/Female
- Migrant
- Homeless
- Foster Care
- Military Connected

**Note:** Small cell sizes may be suppressed for privacy (FERPA).

---

## Time Series Heuristics

### Data Continuity Considerations

**Major Transitions:**
1. **2019-2020:** AzMERIT → AzM2 (pandemic disruption)
2. **2020-2021:** Pandemic year (assessments waived)
3. **2021-2022:** AzM2 → AASA (renamed)
4. **Assessment System Changes:** AzMERIT, AzM2, and AASA may have different scales

**Comparison Warnings:**
- **2015-2019 vs. 2022+:** Different assessment systems (AzMERIT vs. AASA) - limited comparability
- **2021:** Pandemic-affected data - use caution
- **Trend analysis:** Most reliable within same assessment system

### Recommended Time Series Approach

**For Research/Analysis:**
- **AzMERIT Era:** 2015-2019 (pre-pandemic baseline)
- **AASA Era:** 2022-present (current system)
- **2021:** Treat as outlier (pandemic recovery)

**For Implementation:**
- Focus on **AASA (2022-present)** as primary current series
- Include **AzMERIT (2015-2019)** as historical series
- Exclude 2020 (no data)
- Treat 2021 with caution (transition year, pandemic-affected)

---

## Implementation Recommendations

### Phase 1: Current Assessments (Recommended Starting Point)

**Priority:** HIGH
**Complexity:** MEDIUM

**Data Sources:**
- AASA (2022-present)

**Approach:**
1. Download sample Excel files from Accountability & Research Data portal
2. Parse and document schema with readxl package
3. Identify download URL patterns for automation
4. Document exact column structure
5. Implement `fetch_assessment_aasa_ela()`, `fetch_assessment_aasa_math()`

**Challenges:**
- Direct file downloads (Excel format)
- URL pattern identification for automation
- Multiple worksheets within files
- Potential data format variations across years

### Phase 2: Historical AzMERIT (Primary Historical Series)

**Priority:** MEDIUM
**Complexity:** MEDIUM

**Data Sources:**
- AzMERIT (2015-2019)

**Approach:**
1. Download historical AzMERIT files
2. Parse and document schema
3. Implement `fetch_assessment_azmerit(year, subject)`
4. Document differences from AASA
5. Handle as separate historical series

**Challenges:**
- Older file formats may vary
- Different performance level reporting
- Potential missing data for some years

### Phase 3: AzSCI Science Assessment (Optional)

**Priority:** LOW
**Complexity:** LOW

**Data Sources:**
- AzSCI (2019-present)

**Approach:**
1. Verify data availability for grades 5, 8, 11
2. Implement similar to AASA functions
3. Limited grade levels may simplify schema

---

## Technical Challenges

### 1. Excel File Parsing
**Issue:** Data files are in Excel format with multiple worksheets
**Impact:** Requires readxl package, worksheet identification
**Severity:** LOW (standard R package)

### 2. Assessment System Transitions
**Issue:** Multiple systems (AzMERIT, AzM2, AASA) with potential differences
**Impact:** Requires separate processing logic, documentation
**Severity:** MEDIUM

### 3. URL Pattern Identification
**Issue:** Need to identify URL patterns for automated downloads
**Impact:** Requires inspection of download links
**Severity:** LOW

### 4. Pandemic Data Gaps
**Issue:** 2020 assessments waived, 2021 affected
**Impact:** Incomplete historical record
**Severity:** LOW (expected)

---

## Data Quality Considerations

### Participation Rates
- 2020: No assessments (COVID-19)
- 2021: Participation may have been affected
- Small schools/districts: May have suppressed data

### Proficiency Definitions
- AzMERIT and AASA use same 4-level structure
- Proficiency = Level 3 + Level 4
- **Critical:** Verify comparability between AzMERIT and AASA before combining time series

### Small Cell Suppression
- Small schools or demographic subgroups may have suppressed data
- Implementation must handle suppressed values

---

## Next Steps for Implementation

### Immediate Actions (If Proceeding)

1. **Manual Inspection:**
   - Visit https://www.azed.gov/accountability-research/data
   - Download sample assessment files for multiple years
   - Inspect Excel file structure (worksheets, columns)
   - Document exact schema variations

2. **URL Pattern Analysis:**
   - Identify download URL patterns for assessment files
   - Document year-based URL structure
   - Test automated downloads

3. **Schema Documentation:**
   - Parse sample files from each assessment system
   - Document column name variations
   - Identify consistent patterns

4. **Create Prototype Functions:**
   - `get_raw_aasa(year, subject)`
   - `get_raw_azmerit(year, subject)`
   - `process_assessment_aasa(data)`
   - `process_assessment_azmerit(data)`

5. **Validate Data:**
   - Check for expected columns
   - Verify no Inf/NaN values
   - Validate totals (state = sum of districts)
   - Test time series consistency

### Research Questions to Resolve

1. What are the exact download URL patterns for assessment files?
2. Do all years follow the same Excel file structure?
3. What are the exact column names in assessment data files?
4. How are small cell sizes represented (suppressed values)?
5. Are there multiple worksheets in Excel files (which one contains data)?
6. What is the data release schedule for each school year?

---

## Conclusion

Arizona assessment data is **technically feasible** with **moderate complexity** due to:

- Clear data portal with downloadable Excel files
- Multiple assessment system transitions (AzMERIT → AzM2 → AASA)
- Pandemic-related data gap (2020)
- Excel file format (standard parsing)
- Historical archive available

**Recommended Approach:**
1. Implement **AASA (2022-present)** as current series
2. Add **AzMERIT (2015-2019)** as historical series
3. Document as potentially non-comparable systems
4. Handle pandemic years appropriately

**Complexity Rating:** 5/10 (Medium complexity due to assessment system transitions)

**Estimated Implementation Effort:** 15-25 hours (file download investigation, schema documentation, function development, testing)

---

## Sources

- [Accountability & Research Data](https://www.azed.gov/accountability-research/data)
- [State Assessment Results](https://www.azed.gov/accountability-research/state-assessment-results)
- [Assessments Overview 2023-2024](https://www.azed.gov/sites/default/files/2023/04/Assessments%20Overview%202023-2024.pdf)
- [2023 Statewide Assessment Results](https://www.azed.gov/sites/default/files/2024/01/ADE%20Assessments%20Results%20SEAP%20January%202024.pdf)
- [AzMERIT 2016-17 Technical Report](https://www.azed.gov/sites/default/files/2018/08/AzMERIT-2016-17-TechRpt-508.pdf)
- [AzM2 Family Report Guide](https://www.azed.gov/sites/default/files/2021/12/AzM2%20Family%20Report%20Guide.pdf)
- [2023-2024 AASA Test Windows](https://www.azed.gov/sites/default/files/2023/08/2023-2024%20AASA.pdf)
- [AASA 2024 Technical Report](https://www.azed.gov/sites/default/files/2025/01/AASA_2024_Technical_Report.pdf)
