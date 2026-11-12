-- ===========================================
-- Toy Store E-commerce Analysis
-- PART 2. BUSINESS ANALYSIS 
-- ===========================================

-- ==========================================
-- ANALYSIS 01:REVENUE & SALES PERFORMANCE
-- ==========================================

-- Business Question: 
-- How has the company's revenue changed over time? 
-- Metrics: Orders, Revenue, AOV, Items Sold,
--          Gross Profit, Gross Margin

SELECT
    DATE_TRUNC('month', created_at) AS order_month,
    COUNT(*) AS total_orders,
    SUM(price_usd) AS monthly_revenue,
    SUM(items_purchased) AS total_items_sold,
    ROUND(SUM(price_usd) / COUNT(*), 2) AS average_order_value,
    ROUND(AVG(items_purchased), 2) AS avg_items_per_order,
    SUM(price_usd) - SUM(cogs_usd) AS gross_profit,
    ROUND(
        (SUM(price_usd) - SUM(cogs_usd))
        / NULLIF(SUM(price_usd), 0) * 100,
        2
    ) AS gross_margin_pct
FROM orders
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY order_month ASC;
-- Interpretation note: the first and last months have partial
-- coverage. A full-month comparison should exclude/flag them.


-- Q2. Which month generated the highest revenue?

SELECT
    DATE_TRUNC('month', created_at) AS order_month,
    SUM(price_usd) AS monthly_revenue
FROM orders
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY monthly_revenue DESC
LIMIT 1;

-- Q3. Which month generated the highest gross profit?

SELECT
    DATE_TRUNC('month', created_at) AS order_month,
    SUM(price_usd) - SUM(cogs_usd) AS gross_profit
FROM orders
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY gross_profit DESC
LIMIT 1;

