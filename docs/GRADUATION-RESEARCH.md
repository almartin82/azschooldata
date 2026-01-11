# Arizona Graduation Rate Data Research Report

**State:** Arizona (AZ)
**Research Date:** 2025-01-10
**Target Years:** 2021-2025

---

## Executive Summary

**Viability Tier:** 4 - SKIP (Technical Barriers)

**Recommendation:** **DO NOT IMPLEMENT** graduation rate data for Arizona at this time.

**Rationale:**
- Arizona Department of Education (ADE) hosts graduation rate data but protects it with Cloudflare anti-bot protection
- All direct download URLs (both www.azed.gov and cms.azed.gov) return JavaScript challenges instead of files
- Data exists in Excel format but is not programmatically accessible without browser automation
- No alternative state-level sources found that provide comprehensive district/school graduation data

---

## Data Sources Investigated

### 1. Arizona Department of Education - Accountability & Research Data
**URL:** https://www.alyzed.gov/accountability-research/data
**Status:** BLOCKED - Cloudflare Protection

**Description:**
- Official ADE portal for accountability data
- Lists multiple cohorts of four-year graduation rate data:
  - Cohort 2025 Four-Year Graduation Rate Data
  - Cohort 2024 Four-Year Graduation Rate Data
  - Cohort 2023 Four-Year Graduation Rate Data
  - Cohort 2022 Four-Year Graduation Rate Data
  - Cohort 2021 Four-Year Graduation Rate Data

**Technical Barrier:**
- File download attempts return HTML/JavaScript challenge pages
- Example URL pattern: `https://www.azed.gov/sites/default/files/2024/01/4Year_Grad_Rate_Cohort2023_publish%5B1%5D.xlsx`
- Response: "Just a moment..." Cloudflare challenge page
- Requires JavaScript execution and browser cookies to proceed

**Data Structure (from documentation):**
The files reportedly contain:
- Graduation rate type (4-year, 5-year, 6-year, 7-year)
- LEA Entity ID and Name
- School Entity ID and School Name
- County
- Subgroup (demographic categories)
- Number in Cohort
- Number Graduated
- Percent Graduated

---

### 2. Arizona Department of Education - CMS Document System
**URL Pattern:** https://cms.azed.gov/home/GetDocumentFile?id={DOCUMENT_ID}
**Status:** BLOCKED - Cloudflare Protection

**Documents Identified:**
1. **"School by Subgroup" Report**
   - ID: 5db3490c03e2b31bf8308ce9
   - URL: https://cms.azed.gov/home/GetDocumentFile?id=5db3490c03e2b31bf8308ce9
   - Contains: Cohort Year, Graduation Rate Type, LEA Entity ID, School Name, County, Subgroup, Number Graduated, Number in Cohort, Percent

2. **"School" Graduation Data**
   - ID: 5c4b4dea1dcb250678aa6304
   - URL: https://cms.azed.gov/home/GetDocumentFile?id=5c4b4dea1dcb250678aa6304
   - Contains: Cohort Year, Graduation Rate Type, LEA Entity, Cohort, Percent Graduated in 4 Years

3. **Technical Manual (FY22)**
   - URL: https://www.azed.gov/sites/default/files/2021/11/FY22%20Grad%20Drop%20and%20Persistence%20Rate%20Tech%20Manual.pdf
   - Explains methodology for 4-, 5-, 6-, and 7-year graduation rates

**Technical Barrier:**
- All CMS.azed.gov URLs return Cloudflare challenge pages
- Same "Just a moment..." JavaScript challenge as main site
- Files exist but are not accessible via HTTP clients like curl/Python requests

---

### 3. Arizona School Report Cards
**URL:** https://azreportcards.azed.gov/
**Status:** NOT SUITABLE - JavaScript-rendered interface

**Description:**
- Interactive portal for viewing school performance data
- Includes graduation/dropout rates for high schools
- Searchable by school, district, city, or ZIP code

**Issues:**
- Purely interactive interface
- No bulk download option
- Requires user to navigate to individual school pages
- Data rendered via JavaScript
- No API endpoint identified

---

### 4. Arizona Auditor General - District Spending Reports
**URL:** https://www.azauditor.gov/sites/default/files/2023-11/AZ%20School%20District%20Spending%20FY18%20Data%20File.xlsx
**Status:** LIMITED HISTORICAL DATA

**Description:**
- Excel files with district-level data including graduation rates
- Example: FY18 file contains FY2017 four-year cohort graduation rates
- Not comprehensive across all years
- Graduation rate is secondary metric in financial reports

**Issues:**
- Only sporadic historical years available
- Not a dedicated graduation rate data source
- Auditor General reports are financial, not educational accountability focused

---

### 5. Municipal Data Portals (Tempe Example)
**URL:** https://data.tempe.gov/datasets/1d651044fbaa41eeb112f77178b42979_0
**Status:** NOT SUITABLE - Limited Geographic Coverage

**Description:**
- "3.08 High School Graduation Rates (summary)"
- Tracks four-year graduation rates for Tempe high schools
- Data sourced from ADE

**Issues:**
- Single city only
- Not comprehensive statewide data
- Derivative data (sourced from ADE, not original source)

---

## Data Availability by Year

| Cohort/Year | Data Exists | Accessible | Notes |
|-------------|-------------|------------|-------|
| 2025 (Cohort) | Likely | No | Most recent cohort, may not yet be published |
| 2024 (Cohort) | Yes | No | Listed on Accountability page, but Cloudflare blocked |
| 2023 (Cohort) | Yes | No | Excel file exists: `4Year_Grad_Rate_Cohort2023_publish[1].xlsx` |
| 2022 (Cohort) | Yes | No | Referenced in Accountability documentation |
| 2021 (Cohort) | Yes | No | Referenced in Accountability documentation |

**Note:** "Cohort" year refers to the year students entered 9th grade. Four-year graduation rates are typically published the year after cohort completion (e.g., Cohort 2021 graduates in 2025, data published 2025 or later).

---

## Known Subgroups (from Technical Manual)

Arizona graduation rate data includes breakdowns by:
- **Total:** All students
- **Race/Ethnicity:** White, Black, Hispanic, Asian, Native American, Pacific Islander, Multiracial
- **Special Populations:** Students with Disabilities, English Learners, Economically Disadvantaged
- **Gender:** Male, Female

---

## Methodology Information

**Source:** FY22 Graduation, Dropout, and Persistence Rate Technical Manual
**URL:** https://www.azed.gov/sites/default/files/2021/11/FY22%20Grad%20Drop%20and%20Persistence%20Rate%20Tech%20Manual.pdf

**Key Points:**
- Arizona uses the Adjusted Cohort Graduation Rate (ACGR) methodology
- Four-year graduation rate: Students who graduate within 4 years of entering 9th grade
- Also calculates 5-, 6-, and 7-year graduation rates
- Cohort assignment occurs when students first enroll in grade 10
- Transfers handled according to federal guidance
- FERPA suppression: Counts < 11 masked with asterisks (*)

---

## Alternative Approaches Considered

### 1. Browser Automation (Selenium/Playwright)
**Pros:** Could potentially bypass Cloudflare challenges
**Cons:**
- Adds significant complexity and maintenance burden
- Requires headless browser setup
- Cloudflare may detect automated browsers
- Violates project preference for "Avoid: JavaScript-rendered sites, sites requiring browser automation"
- Not scalable across 49 state packages

**Verdict:** NOT RECOMMENDED

---

### 2. Arizona Data Request
**Process:** ADE offers a "Data Requests" page for custom data pulls
**URL:** https://www.alyzed.gov/data-requests (if available)

**Pros:** Could get exactly what's needed in desired format
**Cons:**
- Manual process
- May have fees or approval requirements
- Not automatable for annual updates
- Unclear turnaround time

**Verdict:** NOT SUITABLE for automated package

---

### 3. Federal Sources (NCES CCD, Urban Institute API)
**Status:** **PROHIBITED** per project rules

**Project Rule:** "NEVER use Urban Institute API, NCES CCD, or ANY federal data source — packages MUST use state DOE data directly. Federal sources aggregate/transform data differently and lose state-specific details."

**Verdict:** NOT AN OPTION

---

## Conclusion

Arizona graduation rate data **exists** in the ideal format (Excel files by school, district, and subgroup with multiple years available) but is **technically inaccessible** due to Cloudflare anti-bot protection on the Arizona Department of Education website.

**Key Technical Obstacles:**
1. All direct file downloads return JavaScript challenges
2. No public API endpoint identified
3. Interactive portals (AZ School Report Cards) are JavaScript-rendered
4. Browser automation complexity makes this impractical for a 49-state package family

**Recommendation: SKIP Arizona graduation rate implementation.**

The data would be excellent to include if accessible, but the technical barriers make this a Tier 4 (Skip) case rather than a viable implementation target.

---

## Sources

- [Accountability & Research Data](https://www.azed.gov/accountability-research/data) - Arizona Department of Education
- [Public Data Sets](https://www.azed.gov/data/public-data-sets) - Arizona Department of Education
- [FY22 Graduation, Dropout, and Persistence Rate Technical Manual](https://www.azed.gov/sites/default/files/2021/11/FY22%20Grad%20Drop%20and%20Persistence%20Rate%20Tech%20Manual.pdf) - Arizona Department of Education
- [AZ School Report Cards](https://azreportcards.azed.gov/) - Arizona Department of Education
- [Tempe High School Graduation Rates](https://data.tempe.gov/datasets/1d651044fbaa41eeb112f77178b42979_0) - City of Tempe
- [Arizona Auditor General District Spending Data](https://www.azauditor.gov/sites/default/files/2023-11/AZ%20School%20District%20Spending%20FY18%20Data%20File.xlsx)
