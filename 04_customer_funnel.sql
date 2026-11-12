-- =============================================
-- 04. Customer Journey and Funnel Analysis
-- Business question: At which purchase stage do sessions drop off,
--                    and how does the funnel differ by device?
-- METHOD: Compare the FIRST visit time for each stage in a session.
-- LIMITATION: Repeated/backtracking page visits may be missed.
-- Purchase here means a thank-you pageview, not a verified order.
-- =============================================

-- Q1. Which pages are viewed most often?
-- Total pageviews and unique sessions are different measurements:
-- a session can revisit the same URL multiple times.
SELECT
    pageview_url,
    COUNT(*) AS total_pageviews,
    COUNT(DISTINCT website_session_id) AS unique_sessions
FROM website_pageviews
GROUP BY pageview_url
ORDER BY total_pageviews DESC;


-- Q2. Explore an example purchasing session's page sequence.
-- Session 20 is an illustrative case, not representative of all.
SELECT
    website_session_id,
    created_at,
    pageview_url
FROM website_pageviews
WHERE website_session_id = 20
ORDER BY created_at ASC;

-- Find one session with no matching order (anti-join pattern).
-- LEFT JOIN keeps sessions with no order; o.order_id is then NULL.
SELECT
    ws.website_session_id
FROM website_sessions AS ws
LEFT JOIN orders AS o
    ON ws.website_session_id = o.website_session_id
WHERE o.order_id IS NULL
ORDER BY ws.website_session_id
LIMIT 1;


-- Q3. Overall purchase funnel: stage counts and step-to-step CVRs.
-- page_times: one row per session, with the first visit to each stage.
-- MIN() ignores the NULLs returned for nonmatching page URLs.

WITH page_times AS (
    SELECT
        website_session_id,
        MIN(CASE WHEN pageview_url = '/products'
            THEN created_at END) AS product_at,
        MIN(CASE WHEN pageview_url = '/cart'
            THEN created_at END) AS cart_at,
        MIN(CASE WHEN pageview_url = '/shipping'
            THEN created_at END) AS shipping_at,
        MIN(CASE WHEN pageview_url IN ('/billing', '/billing-2')
            THEN created_at END) AS billing_at,
        MIN(CASE WHEN pageview_url = '/thank-you-for-your-order'
            THEN created_at END) AS purchase_at
    FROM website_pageviews
    GROUP BY website_session_id
),
-- funnel: use 1/0 flags for sessions reaching each stage in order.
-- WHERE limits the denominator to product-listing sessions.
funnel AS (
    SELECT
        website_session_id,
        CASE WHEN cart_at > product_at
            THEN 1 ELSE 0 END AS reached_cart,
        CASE WHEN cart_at > product_at
              AND shipping_at > cart_at
            THEN 1 ELSE 0 END AS reached_shipping,
        CASE WHEN cart_at > product_at
              AND shipping_at > cart_at
              AND billing_at > shipping_at
            THEN 1 ELSE 0 END AS reached_billing,
        CASE WHEN cart_at > product_at
              AND shipping_at > cart_at
              AND billing_at > shipping_at
              AND purchase_at > billing_at
            THEN 1 ELSE 0 END AS reached_purchase
    FROM page_times
    WHERE product_at IS NOT NULL
)
SELECT
    COUNT(*) AS product_sessions,
    SUM(reached_cart) AS cart_sessions,
    SUM(reached_shipping) AS shipping_sessions,
    SUM(reached_billing) AS billing_sessions,
    SUM(reached_purchase) AS purchase_sessions,
    -- Denominator changes to the preceding stage for each step.
    ROUND(SUM(reached_cart) * 100.0 / NULLIF(COUNT(*), 0), 2)
        AS product_to_cart_pct,
    ROUND(SUM(reached_shipping) * 100.0
        / NULLIF(SUM(reached_cart), 0), 2) AS cart_to_shipping_pct,
    ROUND(SUM(reached_billing) * 100.0
        / NULLIF(SUM(reached_shipping), 0), 2) AS shipping_to_billing_pct,
    ROUND(SUM(reached_purchase) * 100.0
        / NULLIF(SUM(reached_billing), 0), 2) AS billing_to_purchase_pct
FROM funnel;


-- Q4. Funnel conversion by device type.
-- This is a separate SQL statement: CTEs are only available to
-- the statement that defines them, so their definitions repeat.
-- Same first-visit methodology and limitations as Q3 above.
WITH page_times AS (
    SELECT
        website_session_id,
        MIN(CASE WHEN pageview_url = '/products'
            THEN created_at END) AS product_at,
        MIN(CASE WHEN pageview_url = '/cart'
            THEN created_at END) AS cart_at,
        MIN(CASE WHEN pageview_url = '/shipping'
            THEN created_at END) AS shipping_at,
        MIN(CASE WHEN pageview_url IN ('/billing', '/billing-2')
            THEN created_at END) AS billing_at,
        MIN(CASE WHEN pageview_url = '/thank-you-for-your-order'
            THEN created_at END) AS purchase_at
    FROM website_pageviews
    GROUP BY website_session_id
),
funnel AS (
    SELECT
        website_session_id,
        CASE WHEN cart_at > product_at
            THEN 1 ELSE 0 END AS reached_cart,
        CASE WHEN cart_at > product_at
              AND shipping_at > cart_at
            THEN 1 ELSE 0 END AS reached_shipping,
        CASE WHEN cart_at > product_at
              AND shipping_at > cart_at
              AND billing_at > shipping_at
            THEN 1 ELSE 0 END AS reached_billing,
        CASE WHEN cart_at > product_at
              AND shipping_at > cart_at
              AND billing_at > shipping_at
              AND purchase_at > billing_at
            THEN 1 ELSE 0 END AS reached_purchase
    FROM page_times
    WHERE product_at IS NOT NULL
)
SELECT
    ws.device_type,
    COUNT(*) AS product_sessions,
    SUM(f.reached_cart) AS cart_sessions,
    SUM(f.reached_shipping) AS shipping_sessions,
    SUM(f.reached_billing) AS billing_sessions,
    SUM(f.reached_purchase) AS purchase_sessions,
    ROUND(SUM(f.reached_cart) * 100.0 / NULLIF(COUNT(*), 0), 2)
        AS product_to_cart_pct,
    ROUND(SUM(f.reached_shipping) * 100.0
        / NULLIF(SUM(f.reached_cart), 0), 2) AS cart_to_shipping_pct,
    ROUND(SUM(f.reached_billing) * 100.0
        / NULLIF(SUM(f.reached_shipping), 0), 2) AS shipping_to_billing_pct,
    ROUND(SUM(f.reached_purchase) * 100.0
        / NULLIF(SUM(f.reached_billing), 0), 2) AS billing_to_purchase_pct,
    -- Cumulative CVR uses product sessions as the denominator.
    ROUND(SUM(f.reached_purchase) * 100.0
        / NULLIF(COUNT(*), 0), 2) AS product_to_purchase_pct
FROM funnel AS f
JOIN website_sessions AS ws
    ON f.website_session_id = ws.website_session_id
GROUP BY ws.device_type
ORDER BY ws.device_type;

-- Portfolio validation to complete before publishing:
-- Compare the sessions visiting the thank-you page with the
-- sessions having actual order records in the orders table.

