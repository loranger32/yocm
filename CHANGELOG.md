# MAIN

- GUI - Improve styling and layout of the user and zip_code_results pages

# VERSION 0.13.0 - 12 February 2024

- GUI - Store active user in DB rather than in session **(run `rake db:migrate`)**

- GUI - Combine follow/unfollow buttons into 1 partial

- GUI - Search pages - Use regexp directly at the DB level

- GUI - Search page - Search by name - Fix bug when clicking on an enterprise number that refers to a natural person

- GEMFILE - Bump Nokogiri to 1.16.2 (from 1.15.5) to address [CVE-2024-25062](https://www.cve.org/CVERecord?id=CVE-2024-25062)

- GUI - Fix various bugs + refactoring

- GUI - Update Bootstrap (5.3.2 from  5.2.3) and Htmx (1.9.10 from 1.9.6)

- GEMFILE - Bump Sequel from 5.65 to 5.77

# VERSION 0.12.0 - 2 February 2024

- GUI - Add feature to allow a user to clean (unfollow) all old publications of enterprises that have ceased to exist

- DB - Rakefile - Refactor DB logging + set logging when accessing console on production DB

- GUI - Add feature to allow user to merge old followed publication with new enterprise records

- GUI - Allow user to follow entity not already in local DB via publication cbe_number **(run `rake db:migrate`)**

- various bug fixes and typos

# VERSION 0.11.0 - 24 January 2024

- GUI - add a follow / unfollow feature (button) to various pages to more easily add an entity on the followed list

- GUI - simplify navbar menu

- ENGINE - zip code parsing : if multiple 4 digits numbers are found, check them all to find the first that match a valid zip code (if any)

- ALL : if the BASE_DB_PATH environment variable is set, ensure it is an absolute path - otherwise use default location.

- ENGINE : if the DB_BACKUP_DIR environment variable is set, ensure it is an absolute path - otherwise abort the `rake db:backup` task

# VERSION 0.10.0 - 16 January 2024

**BREAKING CHANGES**

- ALL : replace PostgreSQL with sqlite3

**OTHER CHANGES**

- GUI - don't show the debug button on the edit publication page if no PNG and OCR files have been generated for a given publication (typically when using the `--skip-parsing` option flag)

- correct some typos and bugs

# VERSION 0.9.0 - 26 December 2023
