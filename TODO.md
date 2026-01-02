# TODO: azschooldata

## Cloudflare Protection Blocking Downloads (Ongoing)

**Date identified:** 2026-01-01
**Status:** Mitigated for pkgdown builds; data access still blocked

**Issue:** The Arizona Department of Education website (azed.gov) has Cloudflare challenge-based protection that blocks programmatic downloads. All HTTP requests to Excel file URLs return `403 Forbidden` with `cf-mitigated: challenge` headers.

**pkgdown Fix Applied:**
- Vignette `enrollment_hooks.Rmd` now uses `eval=FALSE` to skip code execution during builds
- Created `ERRATA.md` documenting the data access issue
- This allows pkgdown to build successfully without network access

**Remaining Work:**
1. Monitor ADE website for changes to Cloudflare configuration
2. Consider adding sample/cached data for offline usage
3. Explore browser automation (Selenium/Playwright) as alternative download method
4. Contact ADE (dataoperations@azed.gov) about programmatic access options

**See also:** `ERRATA.md` for full technical details.
