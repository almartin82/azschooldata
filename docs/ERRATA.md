# ERRATA: Known Data Access Issues

## Cloudflare Protection Blocking Automated Downloads

**Date identified:** January 2026

**Issue:** The Arizona Department of Education (ADE) website at azed.gov
has implemented Cloudflare challenge-based protection that blocks
automated downloads of enrollment data files. HTTP requests to Excel
file URLs return 403 Forbidden with `cf-mitigated: challenge` headers,
indicating a browser-based CAPTCHA challenge is required.

**Impact:** -
[`fetch_enr()`](https://almartin82.github.io/azschooldata/reference/fetch_enr.md)
and
[`fetch_enr_multi()`](https://almartin82.github.io/azschooldata/reference/fetch_enr_multi.md)
cannot download data directly from ADE - The vignette cannot render with
live data during automated builds - Package functionality requires
manual data download or cached data

**Technical details:**

    HTTP/2 403
    cf-mitigated: challenge
    critical-ch: Sec-CH-UA-Bitness, Sec-CH-UA-Arch, ...

The protection applies to all file downloads from
`azed.gov/sites/default/files/`, including: - Oct1Enrollment\*.xlsx
files - Historical enrollment reports - All Excel/CSV data exports

**Workarounds:**

1.  **Manual download**: Download files manually from the [ADE
    Accountability & Research Data
    page](https://www.azed.gov/accountability-research/data) using a web
    browser, then use `import_local_enr()` (if available) or place files
    in the package cache directory.

2.  **Browser automation**: Use tools like Selenium or Playwright to
    automate browser-based downloads that can complete Cloudflare
    challenges.

3.  **Cached data**: If you have previously downloaded data, it may be
    stored in the package cache and accessible without network requests.

**Status:** Unresolved. Monitoring for changes to ADE’s Cloudflare
configuration.

**ADE Contact:** For data access questions, contact
<dataoperations@azed.gov>.
