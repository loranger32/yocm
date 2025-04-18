# MAIN

# VERSION 0.15.0 - 4 April 2025

- GEMFILE - Add specific dependency on Webrick > 1.18.1 to fix a possible request smuggling issue ([CVE-2024-47220](https://www.cve.org/CVERecord?id=CVE-2024-47220))

- GEMFILE - Bump nokogiri to 1.18.6 to fix [CVE 2025-24855](https://www.cve.org/CVERecord?id=CVE-2025-24855) and [CVE 2024-55549](https://www.cve.org/CVERecord?id=CVE-2024-55549)

- GUI - Clean up index and report files when deleting publications

- GUI - Add pagination to users's results page

- GUI - Add a back to top button on long pages

- GUI - On results page based on zip code, show the new entities first and make them stand out

- ENGINE - Reports - show basic CPU info

- ENGINE - Reports - show execution time in minutes and seconds instead of an integer

- GEMFILE - Bump Rack to 3.1.12 to address [CVE-2025-27610](https://www.cve.org/CVERecord?id=CVE-2025-27610)

# VERSION 0.14.0 - 17 january 2025

- ENGINE - Generate a report in the terminal with user's results if a user is provided (or an active user is set)

- ENGINE - Generate a html report with user's results if a user is provided (or an active user is set)

- ENGINE - Rename skip-parsing option to skip-zipcodes

- GUI - Use local Ubuntu font files instead of fonts.google.apis.com

- GUI - Use Roda:assets#compile_assets when launching GUI from the `yocm -g` and `rake s` commands

- GUI - Finish removing of csrf_tokens

- GUI - Home Page - add links to results of the day

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
