-- =======================================
-- TOY STORE E-COMMERCE ANALYSIS 
-- 01. DATA EXPLORATION & VALIDATION 
-- Purpose: Verify imports, date coverage, missing values, and
--          relationships before interpreting business results.
-- =======================================

-- 1. ROW COUNT VALIDATION
-- check the total number of records
-- verify that all six CSV files were imported.
SELECT 'products' AS table_name, 
        COUNT(*) AS row_count 
        FROM products
UNION ALL
SELECT 'website_sessions',
        COUNT(*) 
        FROM website_sessions
UNION ALL
SELECT 'website_pageviews', 
        COUNT(*)
		FROM website_pageviews
UNION ALL
SELECT 'orders', 
        COUNT(*)
		FROM orders
UNION ALL
SELECT 'order_items', 
        COUNT(*)
		FROM order_items
UNION ALL
SELECT 'order_item_refunds',
        COUNT(*)
		FROM order_item_refunds;

-- 2. DATE RANGE VALIDATION
-- Identify the earliest and latest orders 
-- Note: March 2012 and March 2015 are partial months. 
-- Avoid treating their lower monthly totals as directly comparable to full months.

SELECT 
     MIN(created_at) AS first_order_date,
	 MAX(created_at) AS last_order_date
FROM orders;

--3. NULL VALUE CHECk
-- Missing marketing attribution: distinguish SQL NULL from
-- the literal string 'NULL' contained in the imported CSV.

SELECT COUNT(*)
FROM website_sessions
WHERE utm_source IS NULL;

SELECT COUNT(*) AS total_sessions,
COUNT(utm_source) AS non_null_sessions,
COUNT(*) - COUNT(utm_source) AS null_sessions
FROM website_sessions;

--4. DUPLICATE CHECK 
-- Should return no duplicate order IDs.
SELECT order_id,
       COUNT(*) AS duplicate_order
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

--5. RELATIONSHIP VALIDATION
-- Validate relationships between tables

SELECT
     COUNT(*) AS missing_orders
FROM order_items AS oi
LEFT JOIN orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;
-- Query result showed 0, so we will move on. 

