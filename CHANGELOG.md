# MAIN

- simplify navbar menu

- zip code parsing : if multiple 4 digits numbers are found, check them all to find the first that match a valid zip code (if any)
# VERSION 0.10.0 - 16 January 2024

**BREAKING CHANGES**

- replace postgresql with sqlite3

**OTHER CHANGES**

- don't show the debug button on the edit publication page if no PNG and OCR files have been generated for a given publication (typically when using the `--skip-parsing` option flag)

- correct some typos and bugs

# VERSION 0.9.0 - 26 December 2023
