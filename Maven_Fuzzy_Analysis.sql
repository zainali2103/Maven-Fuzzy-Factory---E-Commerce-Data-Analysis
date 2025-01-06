USE mavenfuzzyfactory;
		### TRAFFIC SOURCE ANALYSIS ###
        
#Organic, Direct and Paid Traffic Trend
SELECT
	YEAR(created_at) AS year, 
    MONTH(created_at) AS month, 
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' 
						THEN website_session_id 
                        ELSE NULL END) AS paid_brand_sessions,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' 
						THEN website_session_id 
                        ELSE NULL END) AS paid_nonbrand_sessions,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL 
						THEN website_session_id 
                        ELSE NULL END) AS organic_search_sessions,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL 
						THEN website_session_id 
                        ELSE NULL END) AS direct_sessions
FROM website_sessions
GROUP BY 1,2;

#Website Session Volume Breakdown by utm source, campaign and referring domain
SELECT utm_source, utm_campaign, http_referer,
	   COUNT(website_session_id) AS sessions
FROM website_sessions
GROUP BY utm_source, utm_campaign, http_referer
ORDER BY sessions DESC;

#Gsearch Monthly sessions & orders by brand and non-brand campaigns
SELECT
	DATE(ws.created_at) AS Date,
	YEAR(ws.created_at) AS year, 
    MONTH(ws.created_at) AS month, 
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' 
						THEN ws.website_session_id 
                        ELSE NULL END) AS nonbrand_sessions, 
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' 
						THEN o.order_id 
                        ELSE NULL END) AS nonbrand_orders,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' 
						THEN ws.website_session_id 
                        ELSE NULL END) AS brand_sessions, 
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' 
						THEN o.order_id 
                        ELSE NULL END) AS brand_orders
FROM website_sessions ws
LEFT JOIN orders o
ON o.website_session_id = ws.website_session_id
WHERE ws.utm_source = 'gsearch'
GROUP BY year, month;

#Gsearch non-brand monthly sessions & orders by device type
SELECT
	DATE(ws.created_at) AS Date,
	YEAR(ws.created_at) AS year, 
    MONTH(ws.created_at) AS month, 
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' 
						THEN ws.website_session_id 
						ELSE NULL END) AS desktop_sessions, 
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' 
						THEN o.order_id 
                        ELSE NULL END) AS desktop_orders,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' 
						THEN ws.website_session_id 
						ELSE NULL END) AS mobile_sessions, 
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' 
						THEN o.order_id 
                        ELSE NULL END) AS mobile_orders
FROM website_sessions ws
LEFT JOIN orders o
ON o.website_session_id = ws.website_session_id
WHERE ws.utm_source = 'gsearch'
AND ws.utm_campaign = 'nonbrand'
GROUP BY year, month;

#Bsearch Monthly sessions & orders by brand and non-brand campaigns
SELECT
	DATE(ws.created_at) AS Date,
	YEAR(ws.created_at) AS year, 
    MONTH(ws.created_at) AS month, 
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' 
						THEN ws.website_session_id 
                        ELSE NULL END) AS nonbrand_sessions, 
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' 
						THEN o.order_id 
                        ELSE NULL END) AS nonbrand_orders,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' 
						THEN ws.website_session_id 
                        ELSE NULL END) AS brand_sessions, 
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' 
						THEN o.order_id 
                        ELSE NULL END) AS brand_orders
FROM website_sessions ws
LEFT JOIN orders o
ON o.website_session_id = ws.website_session_id
WHERE ws.utm_source = 'bsearch'
GROUP BY year, month;

#Bsearch non-brand monthly sessions & orders by device type
SELECT
	DATE(ws.created_at) AS Date,
	YEAR(ws.created_at) AS year, 
    MONTH(ws.created_at) AS month, 
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' 
						THEN ws.website_session_id 
						ELSE NULL END) AS desktop_sessions, 
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' 
						THEN o.order_id 
                        ELSE NULL END) AS desktop_orders,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' 
						THEN ws.website_session_id 
						ELSE NULL END) AS mobile_sessions, 
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' 
						THEN o.order_id 
                        ELSE NULL END) AS mobile_orders
FROM website_sessions ws
LEFT JOIN orders o
ON o.website_session_id = ws.website_session_id
WHERE ws.utm_source = 'bsearch'
AND ws.utm_campaign = 'nonbrand'
GROUP BY year, month;

#Cross channel bid optimization: whether the Bsearch nonbrand should have the same bid as Gsearch nonbrand
SELECT ws.device_type,
	   ws.utm_source,
       COUNT(DISTINCT ws.website_session_id) AS sessions,
       COUNT(DISTINCT o.order_id) AS orders,
       COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) AS conv_rate
FROM website_sessions ws
LEFT JOIN orders o
ON o.website_session_id = ws.website_session_id
WHERE utm_campaign = 'nonbrand'
GROUP BY 1, 2;


		### WEBSITE PERFORMANCE ANALYSIS ###
        
#Top 3 most viewed pages ranked by session volume by year & month

WITH views AS (
SELECT YEAR(created_at) AS year, 
       MONTH(created_at) AS month, 
       pageview_url,
	   COUNT(DISTINCT website_pageview_id) AS page_viewed
FROM website_pageviews 
GROUP BY year, month, pageview_url
ORDER BY year, month, page_viewed DESC
),
pageRank AS (
SELECT *, 
DENSE_RANK() OVER (PARTITION BY year, month ORDER BY page_viewed DESC) AS pagerank
FROM views)
SELECT * 
FROM pageRank
WHERE pagerank <= 3

#Bounce rate & Landing page Performance
-- Step 1: finding launch date & first pageview id for Lander1 page
SELECT
	MIN(DATE(created_at)) AS launchedDate,
	MIN(website_pageview_id) AS first_test_pv
FROM website_pageviews
WHERE pageview_url = '/lander-1';

-- Step 2: finding first website_pageview_id for each relevant session
CREATE TEMPORARY TABLE first_test_pageviews
SELECT
	ws.website_session_id AS session_id, 
    MIN(wp.website_pageview_id) AS min_pageview_id
FROM website_pageviews wp
INNER JOIN website_sessions ws
ON ws.website_session_id = wp.website_session_id
AND wp.website_pageview_id >= 23504 -- first page_view
AND utm_source = 'gsearch'
AND utm_campaign = 'nonbrand'
GROUP BY 
	session_id; 
    
-- Step 3: indentifying landing page i.e. home or lander for each session  
CREATE TEMPORARY TABLE nonbrand_test_sessions_w_landing_pages
SELECT 
	ftp.session_id AS session_id, 
    wp.pageview_url AS landing_page
FROM first_test_pageviews ftp
LEFT JOIN website_pageviews wp
ON wp.website_pageview_id = ftp.min_pageview_id
WHERE wp.pageview_url IN ('/home','/lander-1'); 

-- Step 4: counting pageviews of each session, to identify bounces	
CREATE TEMPORARY TABLE bounce
SELECT
	lp.session_id AS bounced_session, 
    lp.landing_page, 
    COUNT(wp.website_pageview_id) AS pagesViewed
FROM nonbrand_test_sessions_w_landing_pages lp
LEFT JOIN website_pageviews wp
ON wp.website_session_id = lp.session_id
GROUP BY 1,2
HAVING pagesViewed = 1;

-- step5: summarizing by counting total sessions and bounced session
SELECT
	lp.landing_page, 
    COUNT(DISTINCT lp.session_id) AS Totalsessions, 
    COUNT(DISTINCT b.bounced_session) AS Bouncedsessions,
     COUNT(DISTINCT b.bounced_session)/COUNT(DISTINCT lp.session_id) AS bounce_rate
FROM nonbrand_test_sessions_w_landing_pages lp
LEFT JOIN bounce b
ON lp.session_id = b.bounced_session
GROUP BY 1; 

#Analyzing the revenue generated by lander1 page
-- Step 1: finding first pageview id for Lander1 page
SELECT
	MIN(website_pageview_id) AS first_test_pv
FROM website_pageviews
WHERE pageview_url = '/lander-1';

-- Step 2: finding first website_pageview_id for each relevant session
CREATE TEMPORARY TABLE first_test_pageviews
SELECT
	ws.website_session_id AS session_id, 
    MIN(wp.website_pageview_id) AS min_pageview_id
FROM website_pageviews wp
INNER JOIN website_sessions ws
ON ws.website_session_id = wp.website_session_id
AND wp.website_pageview_id >= 23504 -- first page_view
AND utm_source = 'gsearch'
AND utm_campaign = 'nonbrand'
GROUP BY 
	session_id; 
    
-- Step 3: indentifying landing page i.e. home or lander for each session  
CREATE TEMPORARY TABLE nonbrand_test_sessions_w_landing_pages
SELECT 
	ftp.session_id AS session_id, 
    wp.pageview_url AS landing_page
FROM first_test_pageviews ftp
LEFT JOIN website_pageviews wp
ON wp.website_pageview_id = ftp.min_pageview_id
WHERE wp.pageview_url IN ('/home','/lander-1'); 

-- Step 4: connecting with orders
CREATE TEMPORARY TABLE orders
SELECT
	lp.session_id, 
    lp.landing_page, 
    o.order_id AS order_id
FROM nonbrand_test_sessions_w_landing_pages lp
LEFT JOIN orders o
	ON o.website_session_id = lp.session_id;

-- Step 5: difference between conversion rates 
SELECT
	landing_page, 
    COUNT(DISTINCT session_id) AS sessions, 
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id)/COUNT(DISTINCT session_id) AS conv_rate
FROM orders
GROUP BY 1; 
   -- Lander 1 generated 1.19% more orders than Home.(i.e. 0.0441 - 0.0322 = 0.0119)

		### SALES ANALYSIS ###
#no. of sales, total revenue & total margin generated
SELECT 
	   YEAR(created_at) AS year,
	   MONTH(created_at) AS month,
       COUNT(DISTINCT order_id) AS numberOfSales,
       SUM(price_usd) AS totalRevenue,
       SUM(price_usd - cogs_usd) AS totalMargin
FROM order_items
GROUP BY 1,2;

#How much revenue each product is generating?
SELECT product_id,
	   COUNT(order_id) AS orders,
       SUM(price_usd) AS Revenue,
       SUM(price_usd - cogs_usd) AS Margin,
       AVG(price_usd) AS AverageOrderValue
FROM order_items
GROUP BY 1
ORDER BY Margin DESC

