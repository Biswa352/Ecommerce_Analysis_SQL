/*
Project: E-commerce Marketplace User Activity Analysis
Database: SQLite
Expected imported table: users_data

IMPORTANT:
1. Import 6M-0K-99K.users.dataset.public.csv into SQLite as users_data first.
2. Run this file section-by-section, reviewing each result.
3. The countries table is a small demonstration lookup containing four codes only.
4. Indexes are created near the end; performance benefit is not claimed without benchmarking.
*/

/* ============================================================
   1. DATA PROFILE AND QUALITY CHECKS
   ============================================================ */

-- 1.1 Total records
SELECT COUNT(*) AS total_users
FROM users_data;

-- 1.2 Check whether identifierHash is unique
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT identifierHash) AS distinct_user_ids,
    COUNT(*) - COUNT(DISTINCT identifierHash) AS duplicate_id_rows
FROM users_data;

-- 1.3 Inspect pass-rate distribution before interpreting it
SELECT
    COUNT(*) AS total_users,
    SUM(CASE WHEN productsPassRate = 0 THEN 1 ELSE 0 END) AS zero_pass_rate_users,
    SUM(CASE WHEN productsPassRate > 0 THEN 1 ELSE 0 END) AS positive_pass_rate_users,
    SUM(CASE WHEN productsPassRate IS NULL THEN 1 ELSE 0 END) AS null_pass_rate_users,
    MIN(productsPassRate) AS minimum_pass_rate,
    MAX(productsPassRate) AS maximum_pass_rate,
    ROUND(AVG(productsPassRate), 4) AS overall_average_pass_rate
FROM users_data;

-- 1.4 General selling activity
SELECT
    CASE WHEN productsSold > 0 THEN 'Has sold products' ELSE 'No products sold' END AS seller_status,
    COUNT(*) AS total_users,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM users_data), 2) AS percentage_of_users,
    SUM(productsSold) AS total_products_sold,
    ROUND(AVG(productsSold), 2) AS average_products_sold_per_user
FROM users_data
GROUP BY CASE WHEN productsSold > 0 THEN 'Has sold products' ELSE 'No products sold' END
ORDER BY total_users DESC;

/* ============================================================
   2. FILTERING AND SELLER ANALYSIS
   ============================================================ */

-- 2.1 Users in the United States with more than 150 products sold
SELECT identifierHash, country, productsSold
FROM users_data
WHERE country = 'Etats-Unis'
  AND productsSold > 150
ORDER BY productsSold DESC;

-- 2.2 Top 10 users by products sold (window function)
WITH seller_ranking AS (
    SELECT
        identifierHash,
        country,
        productsSold,
        ROW_NUMBER() OVER (ORDER BY productsSold DESC, identifierHash) AS seller_rank
    FROM users_data
    WHERE productsSold > 0
)
SELECT seller_rank, identifierHash, country, productsSold
FROM seller_ranking
WHERE seller_rank <= 10
ORDER BY seller_rank;

-- 2.3 Compare pass-rate groups with selling activity.
-- Association only; do not interpret as causation or assume the metric's definition.
SELECT
    CASE WHEN productsPassRate > 0 THEN 'Positive pass rate' ELSE 'Zero pass rate' END AS pass_rate_group,
    COUNT(*) AS total_users,
    ROUND(AVG(productsSold), 2) AS average_products_sold,
    SUM(productsSold) AS total_products_sold,
    SUM(CASE WHEN productsSold > 0 THEN 1 ELSE 0 END) AS users_who_sold_products
FROM users_data
GROUP BY CASE WHEN productsPassRate > 0 THEN 'Positive pass rate' ELSE 'Zero pass rate' END
ORDER BY total_users DESC;

/* ============================================================
   3. COUNTRY-LEVEL ANALYSIS
   ============================================================ */

-- 3.1 Average productsPassRate by country.
-- HAVING excludes countries with fewer than 100 users; zero values require cautious interpretation.
SELECT
    country,
    COUNT(*) AS total_users,
    ROUND(AVG(productsPassRate), 4) AS avg_pass_rate
FROM users_data
GROUP BY country
HAVING COUNT(*) >= 100
ORDER BY avg_pass_rate DESC;

-- 3.2 Seller participation by country, limited to countries with at least 500 users
SELECT
    country,
    COUNT(*) AS total_users,
    SUM(CASE WHEN productsSold > 0 THEN 1 ELSE 0 END) AS active_sellers,
    ROUND(100.0 * SUM(CASE WHEN productsSold > 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS seller_participation_pct,
    SUM(productsSold) AS total_products_sold
FROM users_data
GROUP BY country
HAVING COUNT(*) >= 500
ORDER BY seller_participation_pct DESC;

-- 3.3 Same seller-participation analysis using a CTE
WITH country_metrics AS (
    SELECT
        country,
        COUNT(*) AS total_users,
        SUM(CASE WHEN productsSold > 0 THEN 1 ELSE 0 END) AS active_sellers,
        SUM(productsSold) AS total_products_sold
    FROM users_data
    GROUP BY country
    HAVING COUNT(*) >= 500
)
SELECT
    country,
    total_users,
    active_sellers,
    ROUND(100.0 * active_sellers / total_users, 2) AS seller_participation_pct,
    total_products_sold
FROM country_metrics
ORDER BY seller_participation_pct DESC;

/* ============================================================
   4. LANGUAGE-LEVEL ENGAGEMENT
   ============================================================ */

SELECT
    language,
    COUNT(*) AS total_users,
    SUM(socialNbFollowers) AS total_followers,
    ROUND(AVG(socialNbFollowers), 2) AS average_followers_per_user,
    ROUND(AVG(socialNbFollows), 2) AS average_follows_per_user,
    SUM(socialProductsLiked) AS total_social_product_likes
FROM users_data
GROUP BY language
ORDER BY total_followers DESC;

/* ============================================================
   5. JOIN DEMONSTRATION AND COVERAGE CHECK
   ============================================================ */

-- Safe to rerun: code is a primary key and duplicate inserts are ignored.
CREATE TABLE IF NOT EXISTS countries (
    code TEXT PRIMARY KEY,
    name TEXT NOT NULL
);

INSERT OR IGNORE INTO countries (code, name) VALUES
    ('us', 'United States'),
    ('gb', 'United Kingdom'),
    ('fr', 'France'),
    ('mc', 'Monaco');

-- 5.1 INNER JOIN sample; only the four lookup codes can match
SELECT u.identifierHash, u.countryCode, c.name AS country_name
FROM users_data AS u
INNER JOIN countries AS c
    ON LOWER(u.countryCode) = LOWER(c.code)
LIMIT 20;

-- 5.2 LEFT JOIN coverage: unmatched means absent from this small lookup,
-- not necessarily missing country data in the source dataset.
SELECT
    COUNT(*) AS total_users,
    SUM(CASE WHEN c.code IS NOT NULL THEN 1 ELSE 0 END) AS matched_users,
    SUM(CASE WHEN c.code IS NULL THEN 1 ELSE 0 END) AS unmatched_users,
    ROUND(100.0 * SUM(CASE WHEN c.code IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS matched_percentage
FROM users_data AS u
LEFT JOIN countries AS c
    ON LOWER(u.countryCode) = LOWER(c.code);

/* ============================================================
   6. VIEW FOR EXAMPLE SEGMENTATION
   ============================================================ */

-- Example thresholds only; they are not validated business definitions.
CREATE VIEW IF NOT EXISTS high_engagement_users AS
SELECT identifierHash, country, socialNbFollowers, socialProductsLiked, productsSold
FROM users_data
WHERE socialNbFollowers > 100
  AND productsSold > 100;

SELECT *
FROM high_engagement_users
ORDER BY productsSold DESC;

/* ============================================================
   7. OPTIONAL INDEXES
   ============================================================ */

-- Indexes may help some filters, but test query plans/runtime before claiming improvement.
CREATE INDEX IF NOT EXISTS idx_users_country ON users_data(country);
CREATE INDEX IF NOT EXISTS idx_users_products_sold ON users_data(productsSold);
CREATE INDEX IF NOT EXISTS idx_users_language ON users_data(language);

-- Example plan inspection. Run before and after index creation to compare.
EXPLAIN QUERY PLAN
SELECT identifierHash, country, productsSold
FROM users_data
WHERE country = 'Etats-Unis'
  AND productsSold > 150
ORDER BY productsSold DESC;
