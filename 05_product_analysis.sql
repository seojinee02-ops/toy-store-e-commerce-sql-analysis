-- ==============================================
-- ANALYSIS 04: PRODUCT PERFORMANCE
-- ==============================================

-- Q1. Revenue by Product.
-- Business Question. Which product generate highest revenue?

SELECT
    p.product_name,
    COUNT(*) AS units_sold,
	SUM(oi.price_usd) AS total_revenue

FROM order_items AS oi
JOIN products AS p
    ON oi.product_id = p.product_id

GROUP BY p.product_name
ORDER BY total_revenue DESC;


-- Q2. Product Profitability
-- To see whether the Original Mr. Fuzzy is the most profitable one using COGS


SELECT
    p.product_name,
    COUNT(*) AS units_sold,
    SUM(oi.price_usd) AS total_revenue,

    -- 1. Gross Profit
    SUM(oi.price_usd - oi.cogs_usd) AS gross_profit,

    -- 2. Gross Margin (%)
    ROUND(
        SUM(oi.price_usd - oi.cogs_usd) * 100.0
        / NULLIF(SUM(oi.price_usd), 0),
        2
    ) AS gross_margin_pct

FROM order_items AS oi
JOIN products AS p
    ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_revenue DESC;

-- sugar panda showed the highest gross margin percentage. 
-- Now we will see whether the sugar panda has the highest refund rate(or not)


-- Q3. Refund Analysis by Product
-- Business Question. Which product has the highest refund rates?

SELECT
    p.product_name,

    -- Count unique sold and refunded items.
    COUNT(DISTINCT oi.order_item_id) AS units_sold,
    COUNT(DISTINCT r.order_item_id) AS refunded_items,

 -- Refund rate = refunded items / sold items * 100.
    -- NULLIF prevents division by zero.
    ROUND(
        COUNT(DISTINCT r.order_item_id) * 100.0
        / NULLIF(COUNT(DISTINCT oi.order_item_id), 0),
        2
    ) AS refund_rate_pct,
	
-- Replace NULL refund totals with zero.
    COALESCE(SUM(r.refund_amount_usd), 0) AS total_refund_amount

FROM order_items AS oi

JOIN products AS p
    ON oi.product_id = p.product_id

-- LEFT JOIN preserves items that were not refunded.
LEFT JOIN order_item_refunds AS r
    ON oi.order_item_id = r.order_item_id

GROUP BY p.product_name
ORDER BY refund_rate_pct DESC;
