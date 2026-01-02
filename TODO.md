# TODO: azschooldata pkgdown build issues

## Critical: Enrollment data download URLs are broken

**Date identified:** 2026-01-01

**Error:** All enrollment data downloads fail - no years work (tested 2018-2025)

```
Error in get_raw_enr(end_year):
  Failed to download enrollment data for year 2018
```

**Root cause:** The Arizona Department of Education has changed their file URL structure. The URL patterns in `build_enrollment_urls()` no longer match the actual file locations on azed.gov.

**Impact:**
- Vignette `enrollment_hooks.Rmd` cannot render (requires `fetch_enr_multi(2018:2025)`)
- pkgdown site build fails at article building step
- Core package functionality (fetching enrollment data) is broken

**Attempted URLs (all return 404):**
- `https://www.azed.gov/sites/default/files/2018/04/Oct1EnrollmentFY2018.xlsx`
- `https://www.azed.gov/sites/default/files/2018/FY18%20Oct%201%20Enrollment%20Redacted.xlsx`
- (25+ URL patterns tried per year, all failing)

**To fix:**
1. Navigate to https://www.azed.gov/accountability-research to find current enrollment file locations
2. Update `build_enrollment_urls()` in `R/enrollment.R` with correct URL patterns
3. Test with multiple years (2020-2024) to ensure patterns work
4. Re-run `pkgdown::build_site()` to verify vignette renders

**Workaround:**
None available without updating package code. The `get_available_years()` function reports 2011-2026 as available, but this is a documentation claim, not a verification of actual data availability.
