# E-commerce Marketplace User Activity Analysis (SQL / SQLite)

## Project overview

This project analyses a public user-level marketplace dataset with SQLite. It explores seller participation, product-selling activity, country-level differences, social engagement fields, data quality, joins, subqueries, CTEs, window functions, views, and indexes.

The work is intended to demonstrate practical SQL analysis and cautious interpretation of user activity data. It is **not** a transaction-level revenue or profitability analysis: the dataset does not provide order-level transactions, product prices, or revenue fields.

## Dataset

- **File:** `6M-0K-99K.users.dataset.public.csv`
- **Rows observed:** 98,913
- **Columns observed:** 24
- **Analysis table name:** `users_data`
- **Examples of fields:** `identifierHash`, `country`, `countryCode`, `language`, `productsSold`, `productsListed`, `productsBought`, `productsPassRate`, `socialNbFollowers`, `socialNbFollows`, `socialProductsLiked`, `daysSinceLastLogin`, and `seniorityAsYears`.

The project was explored in a browser-based SQLite playground. The SQL file is written for SQLite and expects the CSV to be imported as a table named `users_data`.

## Tools and SQL concepts

- SQLite
- CSV data import
- `SELECT`, `WHERE`, `ORDER BY`
- `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`, `ROUND`
- `CASE WHEN`, `GROUP BY`, `HAVING`
- Subqueries and percentage calculations
- `INNER JOIN` and `LEFT JOIN`
- Common Table Expressions (CTEs)
- `ROW_NUMBER()` window function
- Views, indexes, and `EXPLAIN QUERY PLAN`

## Questions explored

1. How many user records are present, and are user identifiers unique?
2. How many users have recorded product sales?
3. How does seller participation differ by country?
4. How do users with zero and positive `productsPassRate` values differ in recorded selling activity?
5. Which users have the highest recorded product-selling totals?
6. How do follower and social-product-like measures vary by language?
7. What proportion of rows match a deliberately limited four-country lookup table?

## Verified findings from the exploratory run

- The dataset contained **98,913 rows** and **24 columns**.
- **2,036 users (2.06%)** had `productsSold > 0`; **96,877 users (97.94%)** had no recorded product sales.
- Total recorded products sold were **12,027**; the average among all users was **5.91** when calculated only for the seller group.
- The top observed `productsSold` value was **174**.
- **97,979 users** had `productsPassRate = 0`, while **934** had a positive value; the overall average was **0.8123** and the observed range was 0–100.
- In the country comparison restricted to countries with at least 500 users, Italy had the highest observed seller participation among the displayed countries (**4.33%**, 347 of 8,015 users). France had the largest active-seller count in that result (**713**).
- The four-code demonstration lookup matched **57,083 users (57.71%)** and did not match **41,830 users (42.29%)**. These unmatched records are not necessarily missing country data; the lookup intentionally contains only four codes.

These are descriptive findings from the current exploratory run. Re-run the queries if the source file or import changes.

## Interpretation and limitations

- `productsPassRate` is heavily concentrated at zero. Its exact business definition has not been verified from the available dataset documentation, so zero must not automatically be interpreted as poor quality or failure.
- A positive pass rate is associated with more recorded selling activity in this dataset, but this does not establish causation.
- Country comparisons are descriptive and may be affected by differences in sample sizes, user composition, and data collection.
- The `countries` table is a **small teaching lookup**, not a complete country mapping. Join-coverage results only measure matches to those four entries.
- The `high_engagement_users` view uses illustrative thresholds (`socialNbFollowers > 100` and `productsSold > 100`), not validated business rules.
- Indexes are included as an optimization exercise. Do not claim a speed improvement without comparing query plans and/or runtime before and after indexing.
- The dataset contains user-level activity fields rather than order-level transaction records. Do not claim revenue, profit, average order value, or transaction trends from these columns.

## How to run

### Option A: Browser-based SQLite playground

1. Open [Katlab SQLite Playground](https://tools.katlab.dev/sqlite/).
2. Upload `6M-0K-99K.users.dataset.public.csv`.
3. Rename the imported table to `users_data` if the tool supports renaming; otherwise change `users_data` in the SQL script to the actual table name, quoting it if necessary.
4. Open `SQL_Project_Queries.sql` and run the sections one at a time, checking each result.

### Option B: DB Browser for SQLite

1. Create a new SQLite database.
2. Use **File → Import → Table from CSV file** to import the CSV.
3. Set the table name to `users_data` and confirm that the first row contains column names.
4. Open the **Execute SQL** tab and run `SQL_Project_Queries.sql` section by section.
5. Review each result grid. The setup for the `countries` table, view, and indexes uses `IF NOT EXISTS` / `INSERT OR IGNORE` so it can be rerun without duplicate-key errors.

Some queries use SQLite window-function support; use a modern SQLite version.

## Repository files

- `SQL_Project_Queries.sql` — analysis queries, setup for the sample lookup/view/indexes, and comments on interpretation.
- `README.md` — setup instructions, questions, findings, and limitations.
- `LICENSE` — include only the license that applies to this project and its own code; verify dataset licensing separately before redistributing the CSV.
- `6M-0K-99K.users.dataset.public.csv` — optional dataset file. Include it only if the dataset's redistribution terms permit it; otherwise document the original source and how to obtain it.

## Reproducibility

Import the source CSV into a table named `users_data`, then execute the SQL sections in order. The sample `countries` table is intentionally incomplete and should not be used as a complete reference mapping.
