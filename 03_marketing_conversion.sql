--===========================================
-- 03. MARKETING CONVERSION ANALYSIS 
--===========================================

-- Business Problem
-- Our e-commerce business receives traffic from different marketing channels and devices. 
-- However, we don't know which traffic sources are most effective at converting visitors into paying customers.
-- Objective: Identify conversion gaps and opportunities to improve marketing effectiveness.
-- Conversion rate = sessions with >= 1 order / all sessions.
-- LIMITATION: Channel spend is not available; these are not ROI
-- or ad-cost-efficiency comparisons.
-- ===============================================================================================


-- Q1. Conversion rate by device type

WITH device_performance AS (

    SELECT
        ws.device_type,
        COUNT(DISTINCT(ws.website_session_id))AS total_sessions,
		COUNT(DISTINCT(o.website_session_id)) AS converted_sessions

    FROM website_sessions AS ws
    LEFT JOIN orders AS o
        ON ws.website_session_id =  o.website_session_id
    GROUP BY ws.device_type
)
SELECT
    device_type,
    total_sessions,
    converted_sessions,
	ROUND(
    converted_sessions * 100.0/ NULLIF(total_sessions, 0), 2
	) AS conversion_rate_pct  --CVR rate
FROM device_performance
ORDER BY conversion_rate_pct DESC;


-- Observed in this dataset: desktop 8.50%; mobile 3.09%.
-- The difference does not by itself explain why users convert.

-- Q2. Marketing Channel Performance
-- Which marketing sources generate the most traffic, 
-- and which convert visitors most effectively?

WITH channel_performance AS (

    SELECT
        ws.utm_source,
        COUNT(DISTINCT(ws.website_session_id))AS total_sessions,
		COUNT(DISTINCT(o.website_session_id)) AS converted_sessions

    FROM website_sessions AS ws
    LEFT JOIN orders AS o
        ON ws.website_session_id =  o.website_session_id
    GROUP BY ws.utm_source
)
SELECT
    utm_source,
    total_sessions,
    converted_sessions,
	ROUND(
    converted_sessions * 100.0/ NULLIF(total_sessions, 0), 2
	) AS conversion_rate_pct  --CVR rate
FROM channel_performance
ORDER BY conversion_rate_pct DESC;

-- Observed: bsearch had a higher aggregate CVR than gsearch,
-- while gsearch generated more converting sessions.
-- Unattributed does not automatically mean direct traffic.



-- Q3. Which marketing sources generate the most revenue?

WITH revenue_performance AS (
    SELECT
        ws.utm_source,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.price_usd) AS total_revenue
    FROM website_sessions AS ws
    LEFT JOIN orders AS o
        ON ws.website_session_id = o.website_session_id
    GROUP BY ws.utm_source
)

SELECT
    utm_source,
    total_orders,
    COALESCE(total_revenue, 0) AS total_revenue
FROM revenue_performance
ORDER BY total_revenue DESC;

--Q3-A. Investigating the Unattributed traffic 
-- Noticed that utm_source showed NULL so now will try to search 
-- Where does the traffic with missing traffic comes from? 

SELECT
    COUNT(*) FILTER (WHERE utm_source IS NULL) AS actual_nulls,
    COUNT(*) FILTER (WHERE utm_source = 'NULL') AS text_nulls
FROM website_sessions;

-- Investigate referrers for sessions whose UTM source is text 'NULL'.
-- NULLIF converts the placeholder string 'NULL' to SQL NULL.
-- A missing referrer alone does not prove direct traffic.

SELECT
    NULLIF(http_referer, 'NULL') AS referrer,
    COUNT(*) AS total_sessions
FROM website_sessions
WHERE utm_source = 'NULL'
GROUP BY NULLIF(http_referer, 'NULL')
ORDER BY total_sessions DESC;

-- Q4. Investigating the device and marketing analysis 
-- Is mobile conversion consistently low across all marketing sources, 
-- or is the gap driven by the differences in traffic composition? 


WITH device_source_performance AS (
    SELECT
        ws.utm_source,    
        ws.device_type,

        COUNT(DISTINCT ws.website_session_id)
            AS total_sessions,

        COUNT(DISTINCT o.website_session_id)
            AS converted_sessions

    FROM website_sessions AS ws
    LEFT JOIN orders AS o
        ON ws.website_session_id = o.website_session_id

    GROUP BY
        ws.utm_source,    
        ws.device_type
)

SELECT
    utm_source,           
    device_type,
    total_sessions,
    converted_sessions,
    ROUND(
        converted_sessions * 100.0
        / NULLIF(total_sessions, 0),
        2
    ) AS conversion_rate_pct

FROM device_source_performance
ORDER BY utm_source, device_type;

-- Finding to document: gsearch outperformed bsearch within both
-- desktop and mobile, despite bsearch's higher aggregate CVR.
-- This reversal is associated with the two channels' device mix.
-- Do not infer a causal marketing effect from these rates alone.