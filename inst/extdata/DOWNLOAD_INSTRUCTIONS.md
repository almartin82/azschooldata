# Arizona Enrollment Files - Manual Download Required

Cloudflare protection prevents automated downloads. Please download these files manually using your browser.

## Instructions

1. Open each URL below in your browser
2. The file will download automatically (bypasses Cloudflare)
3. Save it to: `azschooldata/inst/extdata/enrollment/`
4. Rename to match the target filename

## Files to Download

| Year | URL | Save As |
|------|-----|---------|
| 2018 | https://www.azed.gov/sites/default/files/2021/05/2017-2018%20October%201%20Public%20Enrollment%20File%20UPDATED%202021%20V2.xlsx | `Oct1Enrollment2018_publish.xlsx` |
| 2019 | https://www.azed.gov/sites/default/files/2021/05/October%201%20Enrollment%202018%20-2019%20UPDATED%202021%20V2.xlsx | `Oct1Enrollment2019_publish.xlsx` |
| 2020 | https://www.azed.gov/sites/default/files/2021/05/October%201%20Enrollment%202019%20-2020%20UPDATED%202021%20V2.xlsx | `Oct1Enrollment2020_publish.xlsx` |
| 2021 | https://www.azed.gov/sites/default/files/2022/05/October%201%20Enrollment%202020-2021%20UPDATED%202021%20V2.xlsx | `Oct1Enrollment2021_publish.xlsx` |
| 2022 | https://www.azed.gov/sites/default/files/2023/01/Oct1Enrollment2022_publish.xlsx | `Oct1Enrollment2022_publish.xlsx` |
| 2023 | https://www.azed.gov/sites/default/files/2022/11/Oct1Enrollment2023_publish.xlsx | `Oct1Enrollment2023_publish.xlsx` |
| 2024 | https://www.azed.gov/sites/default/files/2023/11/Oct1Enrollment2024_publish.xlsx | `Oct1Enrollment2024_publish.xlsx` |

## Quick Method

Open your terminal and run this command - it will open all URLs in your browser:

```bash
cd /Users/almartin/Documents/state-schooldata/azschooldata/inst/extdata/enrollment

# 2018
open "https://www.azed.gov/sites/default/files/2021/05/2017-2018%20October%201%20Public%20Enrollment%20File%20UPDATED%202021%20V2.xlsx"

# 2019
open "https://www.azed.gov/sites/default/files/2021/05/October%201%20Enrollment%202018%20-2019%20UPDATED%202021%20V2.xlsx"

# 2020
open "https://www.azed.gov/sites/default/files/2021/05/October%201%20Enrollment%202019%20-2020%20UPDATED%202021%20V2.xlsx"

# 2021
open "https://www.azed.gov/sites/default/files/2022/05/October%201%20Enrollment%202020-2021%20UPDATED%202021%20V2.xlsx"

# 2022
open "https://www.azed.gov/sites/default/files/2023/01/Oct1Enrollment2022_publish.xlsx"

# 2023
open "https://www.azed.gov/sites/default/files/2022/11/Oct1Enrollment2023_publish.xlsx"

# 2024
open "https://www.azed.gov/sites/default/files/2023/11/Oct1Enrollment2024_publish.xlsx"
```

Then move the downloaded files from `~/Downloads/` to this directory and rename them.

## Verification

After downloading, verify you have all 7 files:

```bash
ls -lh *.xlsx
```

Should show:
- Oct1Enrollment2018_publish.xlsx
- Oct1Enrollment2019_publish.xlsx
- Oct1Enrollment2020_publish.xlsx
- Oct1Enrollment2021_publish.xlsx
- Oct1Enrollment2022_publish.xlsx
- Oct1Enrollment2023_publish.xlsx
- Oct1Enrollment2024_publish.xlsx

Each file should be roughly 1-5 MB in size.
