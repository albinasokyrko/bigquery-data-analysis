/* 
Query: Revenue by Device and Continent with Sessions
Description: Aggregates revenue and account metrics by continent, 
calculating the share of global revenue per region.
*/

WITH
-- 1. Calculate revenue and segment it by device type per continent
revenue AS (
    SELECT
        sp.continent,
        SUM(p.price) AS revenue,
        SUM(CASE WHEN sp.device = 'mobile' THEN p.price END) AS revenue_from_mobile,
        SUM(CASE WHEN sp.device = 'desktop' THEN p.price END) AS revenue_from_desktop
    FROM `DA.order` o
    JOIN `DA.product` p 
        ON o.item_id = p.item_id
    JOIN `DA.session_params` sp 
        ON sp.ga_session_id = o.ga_session_id
    GROUP BY 
        sp.continent
),

-- 2. Calculate the global total revenue to use for percentage calculations later
revenue_total AS (
    SELECT 
        SUM(p.price) AS total_revenue
    FROM `DA.order` o
    JOIN `DA.product` p 
        ON o.item_id = p.item_id
),

-- 3. Calculate user engagement and account metrics per continent
account_info AS (
    SELECT
        continent,
        COUNT(DISTINCT acs.account_id) AS account_cnt,
        -- Count only verified accounts
        COUNT(CASE WHEN a.is_verified = 1 THEN a.id END) AS verified_account_cnt,
        COUNT(DISTINCT acs.ga_session_id) AS session_cnt
    FROM `DA.session_params` sp
    JOIN `DA.account_session` acs 
        ON sp.ga_session_id = acs.ga_session_id
    JOIN `DA.account` a 
        ON a.id = acs.account_id
    GROUP BY 
        continent
)

-- 4. Combine all CTEs to generate the final analytical dataset
SELECT
    r.continent,
    r.revenue,
    r.revenue_from_mobile,
    r.revenue_from_desktop,
    -- Calculate the percentage of total global revenue for the current continent
    (r.revenue / rt.total_revenue) * 100 AS revenue_from_total_percent,
    ai.account_cnt,
    ai.verified_account_cnt,
    ai.session_cnt
FROM revenue r
JOIN account_info ai 
    ON r.continent = ai.continent
-- Using CROSS JOIN to append the single global total row to every continent row
CROSS JOIN revenue_total rt;
