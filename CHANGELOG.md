# VERSION 0.11.0 - 24 January 2024

- GUI - add a follow / unfollow feature (button) to various pages to more easily add an entity on the followed list

- GUI - simplify navbar menu

- ENGINE - zip code parsing : if multiple 4 digits numbers are found, check them all to find the first that match a valid zip code (if any)

- ALL : if the BASE_DB_PATH environment variable is set, ensure it is an absolute path - otherwise use default location.

- ENGINE : if the DB_BACKUP_DIR environment variable is set, ensure it is an absolute path - otherwise abort the `rake db:backup` task

# VERSION 0.10.0 - 16 January 2024

**BREAKING CHANGES**

- ALL : replace postgresql with sqlite3

**OTHER CHANGES**

- GUI - don't show the debug button on the edit publication page if no PNG and OCR files have been generated for a given publication (typically when using the `--skip-parsing` option flag)

- correct some typos and bugs

# VERSION 0.9.0 - 26 December 2023
